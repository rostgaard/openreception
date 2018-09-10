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
  final Logger _log = new Logger('$_libraryName.User');

  /// Directory path to where the serialized [model.User] objects
  /// are stored on disk.
  final String path;
  final GitEngine _git;
  final Sequencer _sequencer;
  final bool logChanges;
  final Directory trashDir;

  Bus<event.UserChange> _changeBus = new Bus<event.UserChange>();

  factory User(String path, [GitEngine gitEngine, bool enableChangelog]) {
    if (path.isEmpty) {
      throw new ArgumentError.value('', 'path', 'Path must not be empty');
    }

    if (!new Directory(path).existsSync()) {
      new Directory(path).createSync();
    }

    final Sequencer sequencer = new Sequencer(path);

    if (gitEngine != null) {
      gitEngine.init().catchError((dynamic error, StackTrace stackTrace) =>
          Logger.root
              .shout('Failed to initialize git engine', error, stackTrace));
      gitEngine.addIgnoredPath(sequencer.sequencerFilePath);
    }

    final Directory trashDir = new Directory(path + '/.trash');
    if (!trashDir.existsSync()) {
      trashDir.createSync();
    }

    return new User._internal(path, sequencer, gitEngine,
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
  Future<Iterable<String>> groups() async => <String>[
        model.UserGroups.administrator,
        model.UserGroups.receptionist,
        model.UserGroups.serviceAgent
      ];

  @override
  Future<model.User> get(int uid) async {
    final File file = new File('$path/$uid/user.json');

    if (!file.existsSync()) {
      throw new NotFound('No file with name ${file.path}');
    }

    try {
      final model.User user = new model.User.fromJson(
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
      throw new NotFound('No user found with identity : $identity');
    }
    return user;
  }

  @override
  Future<Iterable<model.UserReference>> list() async => new Directory(path)
      .listSync()
      .where((FileSystemEntity fse) =>
          _isDirectory(fse) && new File(fse.path + '/user.json').existsSync())
      .map((FileSystemEntity fse) => new model.User.fromJson(
              _json.decode(new File(fse.path + '/user.json').readAsStringSync())
                  as Map<String, dynamic>)
          .reference);

  @override
  Future<model.UserReference> create(model.User user, model.User modifier,
      {bool enforceId: false}) async {
    user.id = user.id != model.User.noId && enforceId ? user.id : _nextId;

    final Directory userdir = new Directory('$path/${user.id}')..createSync();
    final File file = new File('${userdir.path}/user.json');

    if (file.existsSync()) {
      throw new ClientError('File already exists, please update instead');
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
      new ChangeLogger(userdir.path)
          .add(new model.UserChangelogEntry.create(modifier.reference, user));
    }

    _changeBus.fire(new event.UserChange.create(user.id, modifier.id));

    return user.reference;
  }

  @override
  Future<Iterable<model.Commit>> changes([int uid]) async {
    if (this._git == null) {
      throw new UnsupportedError(
          'Filestore is instantiated without git support');
    }

    FileSystemEntity fse;

    if (uid == null) {
      fse = new Directory(path);
    } else {
      fse = new File('$path/$uid/user.json');
    }

    Iterable<Change> gitChanges = await _git.changes(fse);

    int extractUid(String message) => message.startsWith('uid:')
        ? int.parse(message.split(' ').first.replaceFirst('uid:', ''))
        : model.User.noId;

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

      return new model.UserChange(fc.changeType, id);
    }

    Iterable<model.Commit> changes = gitChanges.map((Change change) =>
        new model.Commit()
          ..uid = extractUid(change.message)
          ..changedAt = change.changeTime
          ..commitHash = change.commitHash
          ..authorIdentity = change.author
          ..changes = new List<model.ObjectChange>.from(
              change.fileChanges.map(convertFilechange)));

    _log.info(changes.map((model.Commit c) => c.toJson()));

    return changes;
  }

  @override
  Future<model.UserReference> update(
      model.User user, model.User modifier) async {
    final Directory userdir = new Directory('$path/${user.id}');
    final File file = new File('${userdir.path}/user.json');

    if (!file.existsSync()) {
      throw new NotFound();
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
      new ChangeLogger(userdir.path)
          .add(new model.UserChangelogEntry.update(modifier.reference, user));
    }

    _changeBus.fire(new event.UserChange.update(user.id, modifier.id));

    return user.reference;
  }

  @override
  Future<Null> remove(int uid, model.User modifier) async {
    final Directory userdir = new Directory('$path/$uid');

    if (!userdir.existsSync()) {
      throw new NotFound();
    }

    if (this._git != null) {
      await _git.remove(
          userdir,
          'uid:${modifier.id} - ${modifier.name} '
          'removed $uid',
          _authorString(modifier));
    }

    if (logChanges) {
      new ChangeLogger(userdir.path)
          .add(new model.UserChangelogEntry.delete(modifier.reference, uid));
    }
    await userdir.rename(trashDir.path + '/$uid');

    _changeBus.fire(new event.UserChange.delete(uid, modifier.id));
  }

  Future<String> changeLog(int uid) async =>
      logChanges ? new ChangeLogger('$path/$uid').contents() : '';
}
