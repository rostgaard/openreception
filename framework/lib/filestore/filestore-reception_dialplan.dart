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

/// File-based storage backed for [model.ReceptionDialplan] objects.
class ReceptionDialplan implements storage.ReceptionDialplan {
  /// Internal logger
  final Logger _log = new Logger('$_libraryName.ReceptionDialplan');

  /// Directory path to where the serialized [model.ReceptionDialplan]
  /// objects are stored on disk.
  final String path;
  GitEngine _git;
  final bool logChanges;
  final Directory trashDir;

  Bus<event.DialplanChange> _changeBus = new Bus<event.DialplanChange>();

  factory ReceptionDialplan(String path,
      [GitEngine gitEngine, bool enableChangelog]) {
    if (path.isEmpty) {
      throw new ArgumentError.value('', 'path', 'Path must not be empty');
    }

    if (!new Directory(path).existsSync()) {
      new Directory(path).createSync();
    }
    if (gitEngine != null) {
      gitEngine.init().catchError((dynamic error, StackTrace stackTrace) =>
          Logger.root
              .shout('Failed to initialize git engine', error, stackTrace));
    }

    final Directory trashDir = new Directory(path + '/.trash');
    if (!trashDir.existsSync()) {
      trashDir.createSync();
    }

    return new ReceptionDialplan._internal(path, gitEngine,
        (enableChangelog != null) ? enableChangelog : true, trashDir);
  }

  /// Internal constructor.
  ReceptionDialplan._internal(String this.path,
      [GitEngine this._git, bool this.logChanges, this.trashDir]);

  Stream<event.DialplanChange> get onChange => _changeBus.stream;

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
  Future<model.ReceptionDialplan> create(
      model.ReceptionDialplan rdp, model.User modifier) async {
    final Directory dialplanDir = new Directory('$path/${rdp.extension}')
      ..createSync();
    final File file = new File('$path/${rdp.extension}/dialplan.json');

    if (file.existsSync()) {
      throw new ClientError('File already exists, please update instead');
    }

    file.writeAsStringSync(_jsonpp.convert(rdp));

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'added ${rdp.extension}',
          _authorString(modifier));
    }

    if (logChanges) {
      new ChangeLogger(dialplanDir.path).add(
          new model.DialplanChangelogEntry.create(modifier.reference, rdp));
    }

    _changeBus
        .fire(new event.DialplanChange.create(rdp.extension, modifier.id));

    return rdp;
  }

  @override
  Future<model.ReceptionDialplan> get(String extension) async {
    final File file = new File('$path/$extension/dialplan.json');

    if (!file.existsSync()) {
      throw new NotFound('No file with name ${file.path}');
    }

    try {
      final model.ReceptionDialplan rdp = new model.ReceptionDialplan.fromJson(
          _json.decode(file.readAsStringSync()) as Map<String, dynamic>);
      return rdp;
    } catch (e) {
      throw e;
    }
  }

  @override
  Future<Iterable<model.ReceptionDialplan>> list() async {
    final Iterable<FileSystemEntity> dirs = new Directory(path)
        .listSync()
        .where((FileSystemEntity fse) =>
            _isDirectory(fse) &&
            new File(fse.path + '/dialplan.json').existsSync());

    return dirs.map((FileSystemEntity fse) {
      final String fileContents =
          new File(fse.path + '/dialplan.json').readAsStringSync();

      return new model.ReceptionDialplan.fromJson(
          _json.decode(fileContents) as Map<String, dynamic>);
    });
  }

  @override
  Future<model.ReceptionDialplan> update(
      model.ReceptionDialplan rdp, model.User modifier) async {
    final Directory dialplanDir = new Directory('$path/${rdp.extension}');

    final File file = new File('$path/${rdp.extension}/dialplan.json');

    if (!file.existsSync()) {
      throw new NotFound();
    }

    file.writeAsStringSync(_jsonpp.convert(rdp));

    if (this._git != null) {
      await _git.commit(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'updated ${rdp.extension}',
          _authorString(modifier));
    }

    if (logChanges) {
      new ChangeLogger(dialplanDir.path).add(
          new model.DialplanChangelogEntry.update(modifier.reference, rdp));
    }

    _changeBus
        .fire(new event.DialplanChange.update(rdp.extension, modifier.id));

    return rdp;
  }

  @override
  Future<Null> remove(String extension, model.User modifier) async {
    final Directory dialplanDir = new Directory('$path/$extension');

    final File file = new File('$path/$extension/dialplan.json');

    if (!file.existsSync()) {
      throw new NotFound();
    }

    if (this._git != null) {
      await _git.remove(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'removed $extension',
          _authorString(modifier));
    } else {
      if (logChanges) {
        new ChangeLogger(dialplanDir.path).add(
            new model.DialplanChangelogEntry.delete(
                modifier.reference, extension));
      }

      await dialplanDir.rename(trashDir.path +
          '/$extension-${new DateTime.now().millisecondsSinceEpoch}');
    }

    _changeBus.fire(new event.DialplanChange.delete(extension, modifier.id));
  }

  @override
  Future<Iterable<model.Commit>> changes([String extension]) async {
    if (this._git == null) {
      throw new UnsupportedError(
          'Filestore is instantiated without git support');
    }

    FileSystemEntity fse;

    if (extension == null) {
      fse = new Directory(path);
    } else {
      fse = new File('$path/$extension/dialplan.json');
    }

    Iterable<Change> gitChanges = await _git.changes(fse);

    int extractUid(String message) => message.startsWith('uid:')
        ? int.parse(message.split(' ').first.replaceFirst('uid:', ''))
        : model.User.noId;

    model.ObjectChange convertFilechange(FileChange fc) {
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

      final String name = parts.first;

      return new model.ReceptionDialplanChange(fc.changeType, name);
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

  Future<String> changeLog(String extension) async =>
      logChanges ? new ChangeLogger('$path/$extension').contents() : '';
}
