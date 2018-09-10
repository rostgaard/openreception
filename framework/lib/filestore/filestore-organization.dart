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

/// File-based storage backed for [model.Organization] objects.
class Organization implements storage.Organization {
  /// Internal logger
  final Logger _log = Logger('$_libraryName.Organization');

  /// Directory path to where the serialized [model.Organization] objects
  /// are stored on disk.
  final String path;
  final Contact _contactFileStore;
  final Reception _receptionFileStore;
  final GitEngine _git;
  final Sequencer _sequencer;
  final bool logChanges;
  final Directory trashDir;

  Bus<event.OrganizationChange> _changeBus =
      Bus<event.OrganizationChange>();

  factory Organization(
      Contact _contactFileStore, Reception _receptionFileStore, String path,
      [GitEngine _git, bool enableChangelog]) {
    if (path.isEmpty) {
      throw ArgumentError.value('', 'path', 'Path must not be empty');
    }

    if (!Directory(path).existsSync()) {
      Directory(path).createSync();
    }

    final Directory trashDir = Directory(path + '/.trash');
    if (!trashDir.existsSync()) {
      trashDir.createSync();
    }

    final Sequencer _sequencer = Sequencer(path);
    if (_git != null) {
      _git.init().catchError((dynamic error, StackTrace stackTrace) => Logger
          .root
          .shout('Failed to initialize git engine', error, stackTrace));
      _git.addIgnoredPath(_sequencer.sequencerFilePath);
    }

    return Organization._internal(
        _contactFileStore,
        _receptionFileStore,
        path,
        _git,
        _sequencer,
        (enableChangelog != null) ? enableChangelog : true,
        trashDir);
  }

  /// Internal constructor that finalizes fields.
  Organization._internal(
      this._contactFileStore,
      this._receptionFileStore,
      String this.path,
      GitEngine this._git,
      Sequencer this._sequencer,
      bool this.logChanges,
      Directory this.trashDir);

  /// Returns the next available ID from the sequencer. Notice that every
  /// call to this function will increase the counter in the
  /// sequencer object.
  int get _nextId => _sequencer.nextInt();

  Stream<event.OrganizationChange> get onOrganizationChange =>
      _changeBus.stream;

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
  Future<Map<String, Map<String, String>>> receptionMap() async {
    final Map<String, Map<String, String>> map =
        <String, Map<String, String>>{};

    Iterable<model.ReceptionReference> rRefs = await _receptionFileStore.list();

    await Future.forEach(rRefs, (model.ReceptionReference rRef) async {
      try {
        final model.Reception reception =
            await _receptionFileStore.get(rRef.id);
        final model.Organization org = await get(reception.oid);

        map[rRef.id.toString()] = <String, String>{
          'organization': org.name,
          'reception': reception.name
        };
      } catch (e, s) {
        _log.warning(
            'Failed to map reception ${rRef.name} (rid: ${rRef.id})', e, s);
      }
    });

    return map;
  }

  @override
  Future<Iterable<model.BaseContact>> contacts(int oid) async {
    List<model.BaseContact> cRefs = <model.BaseContact>[];
    List<model.ReceptionReference> rRefs = await receptions(oid);

    await Future.forEach(rRefs, (model.ReceptionReference rRef) async {
      cRefs.addAll(await _contactFileStore._contactsOfReception(rRef.id));
    });

    return cRefs;
  }

  @override
  Future<model.OrganizationReference> create(
      model.Organization org, model.User modifier,
      {bool enforceId: false}) async {
    if (org.id == null) {
      throw ClientError(
          ArgumentError.notNull(org.id.toString()).toString());
    }
    org.id = org.id != model.Organization.noId && enforceId ? org.id : _nextId;

    final Directory orgDir = Directory('$path/${org.id}')..createSync();
    final File file = File('$path/${org.id}/organization.json');

    if (file.existsSync()) {
      throw ClientError('File already exists, please update instead');
    }

    file.writeAsStringSync(_jsonpp.convert(org));

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'added ${org.name}',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(orgDir.path).add(
          model.OrganizationChangelogEntry.create(modifier.reference, org));
    }

    _changeBus.fire(event.OrganizationChange.create(org.id, modifier.id));

    return org.reference;
  }

  @override
  Future<model.Organization> get(int id) async {
    final File file = File('$path/$id/organization.json');

    if (!file.existsSync()) {
      throw NotFound('No file with name ${file.path}');
    }

    try {
      final model.Organization org = model.Organization.fromJson(
          _json.decode(file.readAsStringSync()));
      return org;
    } catch (e, s) {
      print(s);
      throw e;
    }
  }

  @override
  Future<Iterable<model.OrganizationReference>> list() async =>
      Directory(path)
          .listSync()
          .where((FileSystemEntity fse) =>
              _isDirectory(fse) &&
              File(fse.path + '/organization.json').existsSync())
          .map((FileSystemEntity fse) => model.Organization.fromJson(
                  _json.decode((File(fse.path + '/organization.json'))
                      .readAsStringSync()) as Map<String, dynamic>)
              .reference);

  @override
  Future<Null> remove(int oid, model.User modifier) async {
    final Directory orgDir = Directory('$path/$oid');
    final File file = File('$path/$oid/organization.json');

    if (!file.existsSync()) {
      throw NotFound();
    }

    if (logChanges) {
      ChangeLogger(orgDir.path).add(
          model.OrganizationChangelogEntry.delete(modifier.reference, oid));
    }

    if (this._git != null) {
      await _git.remove(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'removed $oid',
          _authorString(modifier));
    } else {
      await orgDir.rename(trashDir.path + '/$oid');
    }

    _changeBus.fire(event.OrganizationChange.delete(oid, modifier.id));
  }

  @override
  Future<model.OrganizationReference> update(
      model.Organization org, model.User modifier) async {
    final Directory orgDir = Directory('$path/${org.id}');
    final File file = File('$path/${org.id}/organization.json');

    if (org.id == model.Organization.noId) {
      throw ClientError('uuid may not be "noId"');
    }

    if (!file.existsSync()) {
      throw NotFound();
    }

    file.writeAsStringSync(_jsonpp.convert(org));

    if (this._git != null) {
      await _git.commit(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'updated ${org.name}',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(orgDir.path).add(
          model.OrganizationChangelogEntry.update(modifier.reference, org));
    }

    _changeBus.fire(event.OrganizationChange.update(org.id, modifier.id));

    return org.reference;
  }

  @override
  Future<Iterable<model.ReceptionReference>> receptions(int oid) =>
      _receptionFileStore._receptionsOfOrg(oid);

  @override
  Future<Iterable<model.Commit>> changes([int oid]) async {
    if (this._git == null) {
      throw UnsupportedError(
          'Filestore is instantiated without git support');
    }

    FileSystemEntity fse;

    if (oid == null) {
      fse = Directory(path);
    } else {
      fse = File('$path/$oid/organization.json');
    }

    Iterable<Change> gitChanges = await _git.changes(fse);

    int extractUid(String message) => message.startsWith('uid:')
        ? int.parse(message.split(' ').first.replaceFirst('uid:', ''))
        : model.User.noId;

    model.OrganizationChange convertFilechange(FileChange fc) {
      String filename = fc.filename;

      List<String> pathParts = path.split('/');

      for (String pathPart in pathParts.reversed) {
        if (filename.startsWith(pathPart)) {
          filename = filename.replaceFirst(pathPart, '');
        }
      }

      final int id = int.parse(
          filename.split('/').where((String str) => str.isNotEmpty).first);

      return model.OrganizationChange(fc.changeType, id);
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

  Future<String> changeLog(int oid) async =>
      logChanges ? ChangeLogger('$path/$oid').contents() : '';
}
