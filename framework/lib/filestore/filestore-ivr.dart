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

/// File-based storage backed for [model.IvrMenu] objects.
class Ivr implements storage.Ivr {
  /// Internal logger
  final Logger _log = Logger('$_libraryName.Ivr');

  /// Directory path to where the serialized [model.IvrMenu] objects
  /// are stored on disk.
  final String path;
  GitEngine _git;
  final bool logChanges;
  final Directory trashDir;

  Bus<event.IvrMenuChange> _changeBus = Bus<event.IvrMenuChange>();

  factory Ivr(String path, [GitEngine revisionEngine, bool enableChangelog]) {
    if (path.isEmpty) {
      throw ArgumentError.value('', 'path', 'Path must not be empty');
    }

    if (!Directory(path).existsSync()) {
      Directory(path).createSync();
    }

    final Directory trashDir = Directory(path + '/.trash')..createSync();

    if (revisionEngine != null) {
      revisionEngine.init().catchError((dynamic error, StackTrace stackTrace) =>
          Logger.root
              .shout('Failed to initialize git engine', error, stackTrace));
    }

    return Ivr._internal(path, revisionEngine,
        (enableChangelog != null) ? enableChangelog : true, trashDir);
  }

  Ivr._internal(
      String this.path, GitEngine this._git, this.logChanges, this.trashDir);

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

  Stream<event.IvrMenuChange> get onChange => _changeBus.stream;
  @override
  Future<model.IvrMenu> create(model.IvrMenu menu, model.User modifier) async {
    final Directory menuDir = Directory('$path/${menu.name}')..createSync();
    final File file = File('${menuDir.path}/menu.json');

    if (file.existsSync()) {
      throw ClientError('File already exists, please update instead');
    }

    file.writeAsStringSync(_jsonpp.convert(menu));

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'added ${menu.name}',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(menuDir.path)
          .add(model.IvrChangelogEntry.create(modifier.reference, menu));
    }

    _changeBus.fire(event.IvrMenuChange.create(menu.name, modifier.id));

    return menu;
  }

  @override
  Future<model.IvrMenu> get(String menuName) async {
    final File file = File('$path/$menuName/menu.json');

    if (!file.existsSync()) {
      throw NotFound('No file with name $menuName');
    }

    try {
      final model.IvrMenu menu = model.IvrMenu.fromJson(
          _json.decode(file.readAsStringSync()) as Map<String, dynamic>);
      return menu;
    } catch (e,s) {
      print(s);
      throw e;
    }
  }

  @override
  Future<Iterable<model.IvrMenu>> list() async => Directory(path)
      .listSync()
      .where((FileSystemEntity fse) =>
          _isDirectory(fse) && File(fse.path + '/menu.json').existsSync())
      .map((FileSystemEntity fse) => model.IvrMenu.fromJson(
          _json.decode((File(fse.path + '/menu.json')).readAsStringSync())
          as Map<String, dynamic>));

  @override
  Future<model.IvrMenu> update(model.IvrMenu menu, model.User modifier) async {
    final Directory menuDir = Directory('$path/${menu.name}');
    final File file = File('${menuDir.path}/menu.json');

    if (!file.existsSync()) {
      throw NotFound();
    }

    file.writeAsStringSync(_jsonpp.convert(menu));

    if (this._git != null) {
      await _git.commit(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'updated ${menu.name}',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(menuDir.path)
          .add(model.IvrChangelogEntry.update(modifier.reference, menu));
    }

    _changeBus.fire(event.IvrMenuChange.update(menu.name, modifier.id));

    return menu;
  }

  @override
  Future<Null> remove(String menuName, model.User modifier) async {
    final Directory menuDir = Directory('$path/$menuName');
    final File file = File('${menuDir.path}/menu.json');

    if (!file.existsSync()) {
      throw NotFound();
    }

    if (this._git != null) {
      await _git.remove(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'removed $menuName',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(menuDir.path).add(
          model.IvrChangelogEntry.delete(modifier.reference, menuName));
    }

    await menuDir.rename(trashDir.path +
        '/$menuName-${DateTime.now().millisecondsSinceEpoch}');

    _changeBus.fire(event.IvrMenuChange.delete(menuName, modifier.id));
  }

  @override
  Future<Iterable<model.Commit>> changes([String menuName]) async {
    if (this._git == null) {
      throw UnsupportedError(
          'Filestore is instantiated without git support');
    }

    FileSystemEntity fse;

    if (menuName == null) {
      fse = Directory(path);
    } else {
      fse = File('$path/$menuName/menu.json');
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

      return model.IvrChange(fc.changeType, name);
    }

    Iterable<model.Commit> changes = gitChanges.map((Change change) =>
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

  Future<String> changeLog(String menuName) async =>
      logChanges ? ChangeLogger('$path/$menuName').contents() : '';
}
