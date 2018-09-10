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

/// File-based storage backed for [model.Reception] objects.
class Reception implements storage.Reception {
  final Logger _log = new Logger('$_libraryName.Reception');

  /// Directory path to where the serialized [model.Reception] objects
  /// are stored on disk.
  final String path;
  final Sequencer _sequencer;
  final GitEngine _git;
  final Calendar calendarStore;
  final bool logChanges;
  final Directory trashDir;

  Bus<event.ReceptionChange> _changeBus = new Bus<event.ReceptionChange>();

  factory Reception(String path, [GitEngine _git, bool enableChangelog]) {
    if (path.isEmpty) {
      throw new ArgumentError.value('', 'path', 'Path must not be empty');
    }

    if (!new Directory(path).existsSync()) {
      new Directory(path).createSync();
    }

    if (_git != null) {
      _git.init().catchError((dynamic error, StackTrace stackTrace) => Logger
          .root
          .shout('Failed to initialize git engine', error, stackTrace));
    }

    if (enableChangelog == null) {
      enableChangelog = true;
    }

    final Directory trashDir = new Directory(path + '/.trash');
    if (!trashDir.existsSync()) {
      trashDir.createSync();
    }

    return new Reception._internal(path, new Calendar(path, _git),
        new Sequencer(path), _git, enableChangelog, trashDir);
  }

  Reception._internal(String this.path, this.calendarStore, this._sequencer,
      GitEngine this._git, bool this.logChanges, this.trashDir) {
    if (_git != null) {
      _git.addIgnoredPath(_sequencer.sequencerFilePath);
    }
  }

  Stream<event.ReceptionChange> get onReceptionChange => _changeBus.stream;

  /// Returns when the filestore is initialized
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

  Future<Iterable<model.ReceptionReference>> _receptionsOfOrg(int oid) async {
    final Iterable<FileSystemEntity> dirs = new Directory(path)
        .listSync()
        .where((FileSystemEntity fse) =>
            _isDirectory(fse) &&
            new File(fse.path + '/reception.json').existsSync());

    return dirs
        .map((FileSystemEntity fse) {
          final model.Reception reception = new model.Reception.fromJson(
              _json.decode(
                  (new File(fse.path + '/reception.json')).readAsStringSync())
              as Map<String, dynamic>);
          return reception;
        })
        .where((model.Reception r) => r.oid == oid)
        .map((model.Reception r) => r.reference)
        .toList(growable: false);
  }

  @override
  Future<model.ReceptionReference> create(
      model.Reception reception, model.User modifier,
      {bool enforceId: false}) async {
    reception.id = reception.id != model.Reception.noId && enforceId
        ? reception.id
        : _nextId;

    final Directory dir = new Directory('$path/${reception.id}');
    final File file = new File('${dir.path}/reception.json');

    if (file.existsSync()) {
      throw new ClientError(
          'File ${file.path} already exists, please update instead');
    }

    _log.finest('Creating new reception file ${file.path}');
    dir.createSync();
    file.writeAsStringSync(_jsonpp.convert(reception));

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'added ${reception.id}',
          _authorString(modifier));
    }

    if (logChanges) {
      new ChangeLogger('$path/${reception.id}').add(
          new model.ReceptionChangelogEntry.create(
              modifier.reference, reception));
    }

    _changeBus
        .fire(new event.ReceptionChange.create(reception.id, modifier.id));

    return reception.reference;
  }

  @override
  Future<model.Reception> get(int id) async {
    final File file = new File('$path/$id/reception.json');

    if (!file.existsSync()) {
      throw new NotFound('No file with name $id');
    }

    try {
      final model.Reception bc = new model.Reception.fromJson(
          _json.decode(file.readAsStringSync()) as Map<String, dynamic>);
      return bc;
    } catch (e) {
      throw e;
    }
  }

  @override
  Future<Iterable<model.ReceptionReference>> list() async {
    final Iterable<FileSystemEntity> dirs = new Directory(path)
        .listSync()
        .where((FileSystemEntity fse) =>
            _isDirectory(fse) &&
            new File(fse.path + '/reception.json').existsSync());

    return dirs.map((FileSystemEntity fse) {
      final model.Reception reception = new model.Reception.fromJson(
          _json.decode(
              (new File(fse.path + '/reception.json')).readAsStringSync())
          as Map<String, dynamic>);
      return reception.reference;
    });
  }

  @override
  Future<Null> remove(int rid, model.User modifier) async {
    final Directory receptionDir = new Directory('$path/$rid');

    if (!receptionDir.existsSync()) {
      throw new NotFound();
    }

    _log.finest('Deleting file ${receptionDir.path}');
    if (this._git != null) {
      await _git.remove(
          receptionDir,
          'uid:${modifier.id} - ${modifier.name} '
          'removed $rid',
          _authorString(modifier));
    }

    if (logChanges) {
      new ChangeLogger('$path/$rid').add(
          new model.ReceptionChangelogEntry.delete(modifier.reference, rid));
    }

    await receptionDir.rename(trashDir.path + '/$rid');

    _changeBus.fire(new event.ReceptionChange.delete(rid, modifier.id));
  }

  @override
  Future<model.ReceptionReference> update(
      model.Reception rec, model.User modifier) async {
    if (rec.id == model.Reception.noId) {
      throw new ClientError('id may not be "noId"');
    }
    final File file = new File('$path/${rec.id}/reception.json');
    if (!file.existsSync()) {
      throw new NotFound();
    }

    file.writeAsStringSync(_jsonpp.convert(rec));

    if (this._git != null) {
      await _git.commit(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'updated ${rec.name}',
          _authorString(modifier));
    }

    if (logChanges) {
      new ChangeLogger('$path/${rec.id}').add(
          new model.ReceptionChangelogEntry.update(modifier.reference, rec));
    }

    _changeBus.fire(new event.ReceptionChange.update(rec.id, modifier.id));

    return rec.reference;
  }

  @override
  Future<Iterable<model.Commit>> changes([int rid]) async {
    if (this._git == null) {
      throw new UnsupportedError(
          'Filestore is instantiated without git support');
    }

    FileSystemEntity fse;

    if (rid == null) {
      fse = new Directory(path);
    } else {
      fse = new File('$path/$rid/reception.json');
    }

    Iterable<Change> gitChanges = await _git.changes(fse);

    int extractUid(String message) => message.startsWith('uid:')
        ? int.parse(message.split(' ').first.replaceFirst('uid:', ''))
        : model.User.noId;

    model.ReceptionChange convertFilechange(FileChange fc) {
      String filename = fc.filename;

      List<String> pathParts = path.split('/');

      for (String pathPart in pathParts.reversed) {
        if (filename.startsWith(pathPart)) {
          filename = filename.replaceFirst(pathPart, '');
        }
      }

      List<String> parts = filename
          .split('/')
          .where((String str) => str.isNotEmpty)
          .toList(growable: false);

      final int id = int.parse(parts.first);

      return new model.ReceptionChange(fc.changeType, id);
    }

    Iterable<model.Commit> changes = gitChanges.map((Change change) =>
        new model.Commit()
          ..uid = extractUid(change.message)
          ..changedAt = change.changeTime
          ..commitHash = change.commitHash
          ..authorIdentity = change.author
          ..changes = new List<model.ObjectChange>.from(
              change.fileChanges.map(convertFilechange)));

    _log.finest(changes.map((model.Commit c) => c.toJson()));

    return changes;
  }

  Future<String> changeLog(int rid) async =>
      logChanges ? new ChangeLogger('$path/$rid').contents() : '';
}
