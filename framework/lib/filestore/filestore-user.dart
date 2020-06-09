/*                  This file is part of OpenReception
                   Copyright (C) 2016-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.filestore;

/// File-based storage backed for [model.User] objects.
class User implements storage.User {
  /// Internal logger
  final Logger _log = Logger('$_libraryName.User');

  /// Directory path to where the serialized [model.User] objects
  /// are stored on disk.
  final String path;
  final GitEngine _git;
  final Sequencer _sequencer;
  final bool logChanges;
  final Directory trashDir;

  Bus<event.UserChange> _changeBus = Bus<event.UserChange>();

  factory User(String path, [GitEngine gitEngine, bool enableChangelog]) {
    if (path.isEmpty) {
      throw ArgumentError.value('', 'path', 'Path must not be empty');
    }

    if (!Directory(path).existsSync()) {
      Directory(path).createSync();
    }

    final Sequencer sequencer = Sequencer(path);

    if (gitEngine != null) {
      gitEngine.init().catchError((dynamic error, StackTrace stackTrace) =>
          Logger.root
              .shout('Failed to initialize git engine', error, stackTrace));
      gitEngine.addIgnoredPath(sequencer.sequencerFilePath);
    }

    final Directory trashDir = Directory(path + '/.trash');
    if (!trashDir.existsSync()) {
      trashDir.createSync();
    }

    return User._internal(path, sequencer, gitEngine,
        (enableChangelog != null) ? enableChangelog : true, trashDir);
  }

  User._internal(
      this.path, this._sequencer, this._git, this.logChanges, this.trashDir);

  Stream<event.UserChange> get onUserChange => _changeBus.stream;

  /// Returns when the filestore is initialized.
  Future<Null> get initialized async {
    if (_git != null) {
      return _git.initialized;
    } else {
      return null;
    }
  }

  /// Awaits if there is already an operation in progress and returns
  /// whenever the filestore is ready to process the next request.
  Future<Null> get ready async {
    if (_git != null) {
      return _git.whenReady;
    } else {
      return null;
    }
  }

  /// Returns the next available ID from the sequencer. Notice that every
  /// call to this function will increase the counter in the
  /// sequencer object.
  int get _nextId => _sequencer.nextInt();

  @override
  Future<List<String>> groups() async => <String>[
        model.UserGroups.administrator,
        model.UserGroups.receptionist,
        model.UserGroups.serviceAgent
      ];

  @override
  Future<model.User> get(int uid) async {
    final File file = File('$path/$uid/user.json');

    if (!file.existsSync()) {
      throw NotFound('No file with name ${file.path}');
    }

    try {
      final model.User user = model.User.fromJson(
          _json.decode(file.readAsStringSync()) as Map<String, dynamic>);
      return user;
    } catch (e) {
      throw e;
    }
  }

  @override
  Future<model.User> getByIdentity(String identity) async {
    model.User user;
    await Future.wait((await list()).map((model.UserReference uRef) async {
      final model.User u = await get(uRef.id);
      if (u.identities.contains(identity)) {
        user = u;
      }
    }));

    if (user == null) {
      throw NotFound('No user found with identity : $identity');
    }
    return user;
  }

  @override
  Future<List<model.UserReference>> list() async => Directory(path)
      .listSync()
      .where((FileSystemEntity fse) =>
          _isDirectory(fse) && File(fse.path + '/user.json').existsSync())
      .map((FileSystemEntity fse) => model.User.fromJson(
              _json.decode(File(fse.path + '/user.json').readAsStringSync())
                  as Map<String, dynamic>).reference
          ).toList();

  @override
  Future<model.UserReference> create(model.User user, model.User modifier,
      {bool enforceId: false}) async {
    user.id = user.id != 0 && enforceId ? user.id : _nextId;

    final Directory userdir = Directory('$path/${user.id}')..createSync();
    final File file = File('${userdir.path}/user.json');

    if (file.existsSync()) {
      throw ClientError('File already exists, please update instead');
    }

    file.writeAsStringSync(_jsonpp.convert(user));

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'added ${user.id}',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(userdir.path)
          .add(model.UserChangelogEntry.create(modifier.reference, user));
    }

    _changeBus.fire(event.UserChange.create(user.id, modifier.id));

    return user.reference;
  }

  @override
  Future<List<model.Commit>> changes([int uid]) async {
    if (this._git == null) {
      throw UnsupportedError(
          'Filestore is instantiated without git support');
    }

    FileSystemEntity fse;

    if (uid == null) {
      fse = Directory(path);
    } else {
      fse = File('$path/$uid/user.json');
    }

    List<Change> gitChanges = await _git.changes(fse);

    int extractUid(String message) => message.startsWith('uid:')
        ? int.parse(message.split(' ').first.replaceFirst('uid:', ''))
        : 0;

    model.UserChange convertFilechange(FileChange fc) {
      String filename = fc.filename;

      List<String> pathParts = path.split('/').toList(growable: false);

      for (String pathPart in pathParts.reversed) {
        if (filename.startsWith(pathPart)) {
          filename = filename.replaceFirst(pathPart, '');
        }
      }

      final int id = int.parse(
          filename.split('/').where((String str) => str.isNotEmpty).first);

      return model.UserChange(fc.changeType, id);
    }

    List<model.Commit> changes = gitChanges.map((Change change) =>
        model.Commit()
          ..uid = extractUid(change.message)
          ..changedAt = change.changeTime
          ..commitHash = change.commitHash
          ..authorIdentity = change.author
          ..changes = List<model.ObjectChange>.from(
              change.fileChanges.map(convertFilechange)));

    _log.info(changes.map((model.Commit c) => c.toJson()));

    return changes;
  }

  @override
  Future<model.UserReference> update(
      model.User user, model.User modifier) async {
    final Directory userdir = Directory('$path/${user.id}');
    final File file = File('${userdir.path}/user.json');

    if (!file.existsSync()) {
      throw NotFound();
    }

    file.writeAsStringSync(_jsonpp.convert(user));

    if (this._git != null) {
      await _git.commit(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'updated ${user.id}',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(userdir.path)
          .add(model.UserChangelogEntry.update(modifier.reference, user));
    }

    _changeBus.fire(event.UserChange.update(user.id, modifier.id));

    return user.reference;
  }

  @override
  Future<Null> remove(int uid, model.User modifier) async {
    final Directory userdir = Directory('$path/$uid');

    if (!userdir.existsSync()) {
      throw NotFound();
    }

    if (this._git != null) {
      await _git.remove(
          userdir,
          'uid:${modifier.id} - ${modifier.name} '
          'removed $uid',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(userdir.path)
          .add(model.UserChangelogEntry.delete(modifier.reference, uid));
    }
    await userdir.rename(trashDir.path + '/$uid');

    _changeBus.fire(event.UserChange.delete(uid, modifier.id));
  }

  Future<String> changeLog(int uid) async =>
      logChanges ? ChangeLogger('$path/$uid').contents() : '';
}
