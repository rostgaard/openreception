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

/// Filestore for persistent storage of [model.CalendarEntry] objects.
class Calendar implements storage.Calendar {
  /// Internal logger
  final Logger _log = Logger('$_libraryName.Calendar');

  /// Root path to where the object files are stored
  final String path;

  /// Determines whether or not to write object changes to a changelog
  final bool logChanges;

  /// Internal sequencer. Keeps track of which id's has been used.
  Sequencer _sequencer;

  /// Revision engine. Keeps track of object changes and who performs them.
  GitEngine _git;

  /// Internal change bus. Exposed externally by [changeStream]
  final Bus<event.CalendarChange> _changeBus = Bus<event.CalendarChange>();

  /// Create a [Calendar] filestore in [path].
  Calendar(String this.path, [GitEngine this._git, bool enableChangelog])
      : this.logChanges = (enableChangelog != null) ? enableChangelog : true {
    final List<String> pathsToCreate = <String>[path];

    if (path.isEmpty) {
      throw ArgumentError.value('', 'path', 'Path must not be empty');
    }

    pathsToCreate.forEach((String newPath) {
      final Directory dir = Directory(newPath);
      if (!dir.existsSync()) {
        dir.createSync();
      }
    });

    _sequencer = Sequencer(path);
    if (this._git != null) {
      _git.init().catchError((dynamic error, StackTrace stackTrace) => Logger
          .root
          .shout('Failed to initialize git engine', error, stackTrace));
      _git.addIgnoredPath(_sequencer.sequencerFilePath);
    }
  }

  /// Returns the next available ID from the sequencer. Notice that every
  /// call to this function will increase the counter in the
  /// sequencer object.
  int get _nextId => _sequencer.nextInt();

  /// Spawns events on every object change. May be used by external classes
  /// to, for instance, maintain caches./
  Stream<event.CalendarChange> get changeStream => _changeBus.stream;

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

  @override
  Future<List<model.Commit>> changes(model.Owner owner, [int eid]) async {
    if (this._git == null) {
      throw UnsupportedError(
          'Filestore is instantiated without git support');
    }

    final String ownerPath = '${owner.id}/calendar';

    FileSystemEntity fse;

    if (eid == null) {
      fse = Directory(ownerPath);
    } else {
      fse = File(ownerPath + '/$eid.json');
    }

    Iterable<Change> gitChanges = await _git.changes(fse);

    int extractUid(String message) => message.startsWith('uid:')
        ? int.parse(message.split(' ').first.replaceFirst('uid:', ''))
        : 0;

    model.CalendarChange convertFilechange(FileChange fc) {
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

      final int eid = int.parse(parts[2].split('.').first);

      return model.CalendarChange(fc.changeType, eid);
    }

    Iterable<model.Commit> changes = gitChanges.map((Change change) =>
        model.Commit()
          ..uid = extractUid(change.message)
          ..changedAt = change.changeTime
          ..commitHash = change.commitHash
          ..authorIdentity = change.author
          ..changes = List<model.ObjectChange>.from(
              change.fileChanges.map<model.CalendarChange>(convertFilechange)));

    _log.info(changes.map((model.Commit c) => c.toJson()));

    return changes;
  }

  @override
  Future<model.CalendarEntry> create(
      model.CalendarEntry entry, model.Owner owner, model.User modifier,
      {bool enforceId: false}) async {
    entry.id =
        entry.id != 0 && enforceId ? entry.id : _nextId;

    entry.lastAuthorId = modifier.id;
    entry.touched = DateTime.now();

    final Directory ownerDir = _ownerDir(owner.id);
    try {
      ownerDir.createSync();
    } catch (e) {
      _log.warning('Creating directory ${ownerDir.path}');
      throw NotFound('Owner not found: ${owner.id}');
    }

    final File file = File('${ownerDir.path}/${entry.id}.json');

    if (file.existsSync()) {
      throw ClientError('File already exists, please update instead');
    }

    _log.finest('Creating file ${file.path}');
    file.writeAsStringSync(_jsonpp.convert(entry));

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name}'
          'added ${entry.id} to $owner',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(ownerDir.path).add(
          model.CalendarChangelogEntry.create(modifier.reference, entry));
    }

    _changeBus
        .fire(event.CalendarChange.create(entry.id, owner, modifier.id));

    return entry;
  }

  @override
  Future<model.CalendarEntry> get(int eid, model.Owner owner) async {
    final Iterable<FileSystemEntity> subdirs =
        Directory(path).listSync().where(_isDirectory);

    for (FileSystemEntity subdir in subdirs) {
      if (subdir is Directory) {
        final Iterable<FileSystemEntity> ownerDirs =
            subdir.listSync().where(_isDirectory);

        for (FileSystemEntity dir in ownerDirs) {
          File file = File('${dir.path}/$eid.json');

          if (file.existsSync()) {
            return model.CalendarEntry.fromJson(
                _json.decode(file.readAsStringSync()) as Map<String, dynamic>);
          }
        }
      }
    }

    throw NotFound('No file with eid $eid');
  }

  @override
  Future<List<model.CalendarEntry>> list(model.Owner owner) async {
    String ownerPath = '$path/${owner.id}/calendar';

    if (!Directory(ownerPath).existsSync()) {
      return const <model.CalendarEntry>[];
    }

    return _list(ownerPath);
  }

  Future<Iterable<model.CalendarEntry>> _list(String basePath) async =>
      Directory(basePath)
          .listSync()
          .where((FileSystemEntity fse) =>
              _isFile(fse) && fse.path.endsWith('.json'))
          .map((FileSystemEntity fse) => model.CalendarEntry.fromJson(
              _json.decode((fse as File).readAsStringSync())
                  as Map<String, dynamic>));

  /// Deletes the [model.CalendarEntry] associated with [eid] in the
  /// filestore.
  ///
  /// The action is logged as being performed by user [modifier].
  @override
  Future<Null> remove(int eid, model.Owner owner, model.User modifier) async {
    final Directory ownerDir = Directory('$path/${owner.id}/calendar');
    final File file = File('${ownerDir.path}/$eid.json');

    if (!file.existsSync()) {
      throw NotFound();
    }

    _log.finest('Deleting file ${file.path}');

    if (this._git != null) {
      await _git.remove(
          file,
          'uid:${modifier.id} - ${modifier.name}'
          ' removed $eid',
          _authorString(modifier));
    } else {
      file.deleteSync();
    }
    if (logChanges) {
      ChangeLogger(ownerDir.path).add(
          model.CalendarChangelogEntry.delete(modifier.reference, eid));
    }

    _deleteNotify(eid, owner, modifier);
  }

  /// Notifies listeners of the [changeStream] that an item has been deleted.
  void _deleteNotify(int eid, model.Owner owner, model.User modifier) =>
      _changeBus.fire(event.CalendarChange.delete(eid, owner, modifier.id));

  @override
  Future<model.CalendarEntry> update(
      model.CalendarEntry entry, model.Owner owner, model.User modifier) async {
    final Directory ownerDir = Directory('$path/${owner.id}/calendar');
    final File file = File('${ownerDir.path}/${entry.id}.json');

    entry.lastAuthorId = modifier.id;
    entry.touched = DateTime.now();

    if (!file.existsSync()) {
      throw NotFound();
    }

    _log.finest('Updating file ${file.path}');
    file.writeAsStringSync(_jsonpp.convert(entry));

    if (this._git != null) {
      await _git.commit(
          file,
          'uid:${modifier.id} - ${modifier.name}'
          ' updated ${entry.id}',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(ownerDir.path).add(
          model.CalendarChangelogEntry.update(modifier.reference, entry));
    }

    _changeBus
        .fire(event.CalendarChange.update(entry.id, owner, modifier.id));

    return entry;
  }

  /// Returns the changeLog of calender entry changes for owner with
  /// id [ownerId].
  Future<String> changeLog(int ownerId) async =>
      logChanges ? await ChangeLogger(_ownerDir(ownerId).path).contents() : '';

  Directory _ownerDir(int ownerId) => Directory('$path/$ownerId/calendar');
}
