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

/// File-based storage backed for [model.BaseContact] and
/// [model.ReceptionAttributes] objects.
class Contact implements storage.Contact {
  /// Internal logger
  final Logger _log = Logger('$_libraryName.Contact');

  /// Directory path to where the serialized [model.BaseContact] objects
  /// are stored on disk.
  final String path;

  /// External [Reception] store. Needed for extracting foreign keys.
  final Reception receptionStore;

  /// Revision engine.
  final GitEngine _git;

  /// Directory path to where the trashed [model.BaseContact] objects are
  /// stored.
  final Directory trashDir;

  /// Internal sequencer.
  Sequencer _sequencer;

  /// Internal [Calendar] store. Used for storing [model.CalendarEntry]
  /// objects associated with [model.BaseContact]s.
  final Calendar calendarStore;

  /// Index of contact ID to object file path.
  final Map<int, String> _index = <int, String>{};

  /// Determines whether or not this filestore log its changes to a
  /// changelog file.
  final bool logChanges;

  Bus<event.ContactChange> _changeBus = Bus<event.ContactChange>();
  Bus<event.ReceptionData> _receptionDataChangeBus =
      Bus<event.ReceptionData>();

  /// Creates a [Contact] object-filestore at [path].
  ///
  /// Needs an associated [Reception] store in order to be able
  /// extract "foreign" key data, such as receptions and organizations
  /// associated with single [model.BaseContact] objects.
  factory Contact(Reception receptionStore, String path,
      [GitEngine ge, bool enableChangelog]) {
    if (!Directory(path).existsSync()) {
      Directory(path).createSync();
    }

    if (path.isEmpty) {
      throw ArgumentError.value('', 'path', 'Path must not be empty');
    }

    if (ge != null) {
      ge.init().catchError((Object error, StackTrace stackTrace) => Logger.root
          .shout('Failed to initialize git engine', error, stackTrace));
    }

    if (enableChangelog == null) {
      enableChangelog = true;
    }

    final Directory trashDir = Directory(path + '/.trash');
    if (!trashDir.existsSync()) {
      trashDir.createSync();
    }

    return Contact._internal(path, receptionStore, Calendar(path, ge),
        ge, enableChangelog, trashDir);
  }

  Contact._internal(String this.path, this.receptionStore, this.calendarStore,
      GitEngine this._git, this.logChanges, this.trashDir) {
    _buildIndex();
    if (_git != null) {
      _git.addIgnoredPath(_sequencer.sequencerFilePath);
    }
  }

  /// Returns the next available ID from the sequencer. Notice that every
  /// call to this function will increase the counter in the
  /// sequencer object.
  int get _nextId => _sequencer.nextInt();

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

  /// Contact change stream.
  ///
  /// Fires every time a [model.BaseContact] change happens within the filestore.
  Stream<event.ContactChange> get onContactChange => _changeBus.stream;

  /// Refception data change stream.
  ///
  /// Fires every time a [model.ReceptionAttributes] change happens within the
  /// filestore.
  Stream<event.ReceptionData> get onReceptionDataChange =>
      _receptionDataChangeBus.stream;

  /// Rebuilds the entire index.
  void _buildIndex() {
    int highestId = 0;
    Stopwatch timer = Stopwatch()..start();
    _log.info('Building index');
    List<FileSystemEntity> idDirs = Directory(path).listSync();

    for (FileSystemEntity fse in idDirs) {
      if (_isDirectory(fse))
        try {
          final int id = int.parse(basenameWithoutExtension(fse.path));
          _index[id] = fse.path;

          if (id > highestId) {
            highestId = id;
          }
        } catch (e) {
          _log.shout('Failed load index from file ${fse.path}');
        }
    }

    _log.info('Built index of ${_index.keys.length} elements in'
        ' ${timer.elapsedMilliseconds}ms');
    _sequencer = Sequencer(path, explicitId: highestId);
  }

  Future<Iterable<model.BaseContact>> _contactsOfReception(int rid) async =>
      (await receptionContacts(rid))
          .map((model.ReceptionContact rc) => rc.contact);

  @override
  Future<Null> addData(
      model.ReceptionAttributes attr, model.User modifier) async {
    if (attr.receptionId == model.Reception.noId) {
      throw ArgumentError('attr.receptionId must be valid');
    }

    final Directory recDir = _receptionDir(attr.cid);
    if (!recDir.existsSync()) {
      recDir.createSync();
    }

    final File file = File('${recDir.path}/${attr.receptionId}.json');

    if (file.existsSync()) {
      throw ClientError('File already exists, please update instead');
    }

    file.writeAsStringSync(_jsonpp.convert(attr));
    _log.finest('Created file ${file.path}');

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'added ${attr.cid} to ${attr.receptionId}',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(recDir.path).add(
          model.ReceptionDataChangelogEntry.create(
              modifier.reference, attr));
    }

    _receptionDataChangeBus.fire(event.ReceptionData.create(
        attr.cid, attr.receptionId, modifier.id));
  }

  @override
  Future<model.BaseContact> create(
      model.BaseContact contact, model.User modifier,
      {bool enforceId: false}) async {
    contact.id = contact.id != model.BaseContact.noId && enforceId
        ? contact.id
        : _nextId;

    final Directory dir = _contactDir(contact.id);

    if (dir.existsSync()) {
      throw ClientError('File already exists, please update instead');
    }

    dir.createSync();
    final File file = File('${dir.path}/contact.json');

    _log.finest('Creating file ${file.path}');
    file.writeAsStringSync(_jsonpp.convert(contact));

    /// Update index
    _index[contact.id] = file.path;

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'added ${contact.id}',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(dir.path).add(
          model.ContactChangelogEntry.create(modifier.reference, contact));
    }

    _changeBus.fire(event.ContactChange.create(contact.id, modifier.id));

    return contact;
  }

  @override
  Future<model.BaseContact> get(int id) async {
    final File file = File('$path/$id/contact.json');

    if (!file.existsSync()) {
      throw NotFound('No file ${file.path}');
    }

    try {
      final String jsonString = file.readAsStringSync();
      final model.BaseContact bc = model.BaseContact.fromJson(
          _json.decode(jsonString) as Map<String, Object>);

      return bc;
    } catch (e) {
      throw e;
    }
  }

  @override
  Future<model.ReceptionAttributes> data(int id, int rid) async {
    final File file = _receptionFile(id, rid);
    if (!file.existsSync()) {
      throw NotFound('No file: ${file.path}');
    }

    return model.ReceptionAttributes.fromJson(
        _json.decode(await file.readAsString()) as Map<String, Object>);
  }

  @override
  Future<Iterable<model.BaseContact>> list() async {
    if (!Directory(path).existsSync()) {
      return const <model.BaseContact>[];
    }

    return Future.wait(_index.keys.map(get));
  }

  @override
  Future<Iterable<model.ReceptionReference>> receptions(int cid) async {
    final Directory rDir = _receptionDir(cid);
    if (!rDir.existsSync()) {
      return <model.ReceptionReference>[];
    }

    final Iterable<FileSystemEntity> rFiles =
        rDir.listSync().where(_isJsonFile);

    final List<model.ReceptionReference> rRefs = <model.ReceptionReference>[];

    await Future.forEach(rFiles, (FileSystemEntity f) async {
      final int rid = int.parse(basenameWithoutExtension(f.path));
      try {
        rRefs.add((await receptionStore.get(rid)).reference);
      } catch (e) {
        _log.warning('Failed to load file ${f.path} (rid:$rid)', e);
      }
    });

    return rRefs;
  }

  @override
  Future<Iterable<model.BaseContact>> organizationContacts(
      int organizationId) async {
    Iterable<model.ReceptionReference> rRefs =
        await receptionStore._receptionsOfOrg(organizationId);

    Set<model.BaseContact> contacts = Set<model.BaseContact>();

    await Future.wait(rRefs.map((model.ReceptionReference rRef) async {
      contacts.addAll(await _contactsOfReception(rRef.id));
    }));

    return contacts;
  }

  @override
  Future<Iterable<model.OrganizationReference>> organizations(int cid) async {
    Iterable<model.ReceptionReference> rRefs = await receptions(cid);

    Set<model.OrganizationReference> orgs =
        Set<model.OrganizationReference>();
    await Future.wait(rRefs.map((model.ReceptionReference rRef) async {
      orgs.add(model.OrganizationReference(
          (await receptionStore.get(rRef.id)).oid, ''));
    }));

    return orgs;
  }

  @override
  Future<Iterable<model.ReceptionContact>> receptionContacts(int rid) async {
    final Iterable<FileSystemEntity> subDirs =
        Directory(path).listSync().where(_isDirectory);

    List<model.ReceptionContact> rcs = <model.ReceptionContact>[];
    await Future.wait(subDirs.map((FileSystemEntity fse) async {
      final File ridFile = File(fse.path + '/receptions/$rid.json');

      if (ridFile.existsSync()) {
        final String bn = basename(fse.path);

        if (!bn.startsWith('.')) {
          final File contactFile = File('${fse.path}/contact.json');
          final Future<model.BaseContact> bc = contactFile.readAsString().then(
              (final String s) =>
                  model.BaseContact.fromJson(_json.decode(s)));

          final Future<model.ReceptionAttributes> attr = ridFile
              .readAsString()
              .then((final String s) =>
                  model.ReceptionAttributes.fromJson(_json.decode(s)));

          rcs.add(model.ReceptionContact(await bc, await attr));
        }
      }
    }));

    return rcs;
  }

  /// Trashes a [model.BaseContact] object, identified by [cid], from this
  /// filestore.
  ///
  /// This action will also delete every other object directly associated
  /// with the [model.BaseContact] object. For example, if a
  /// [model.BaseContact] object has a number of [model.CalendarEntry] and
  /// [model.ReceptionAttributes] object, these will trashed along with the
  /// [model.BaseContact] object. Every object removed will spawn an
  /// appropriate delete event, that allows clients and stores to update
  /// caches or views accordingly.
  @override
  Future<Null> remove(int cid, model.User modifier) async {
    if (!_index.containsKey(cid)) {
      throw NotFound();
    }

    final Directory contactDir = Directory('$path/$cid');

    /// Remove reception references.
    await Future.forEach(await receptions(cid),
        (model.ReceptionReference rRef) async {
      _receptionDataChangeBus
          .fire(event.ReceptionData.delete(cid, rRef.id, modifier.id));
    });

    /// Remove calendar entries.
    final model.Owner owner = model.OwningContact(cid);
    await Future.forEach(await calendarStore.list(owner),
        (model.CalendarEntry entry) async {
      calendarStore._deleteNotify(entry.id, owner, modifier);
    });

    if (this._git != null) {
      /// Go ahead and remove the file.
      final File contactFile = File(_index[cid]);
      await _git.remove(
          contactFile,
          'uid:${modifier.id} - ${modifier.name} '
          'removed $cid',
          _authorString(modifier));
    }

    _index.remove(cid);

    if (logChanges) {
      ChangeLogger(contactDir.path)
          .add(model.ContactChangelogEntry.delete(modifier.reference, cid));
    }

    await contactDir.rename(trashDir.path + '/$cid');

    _changeBus.fire(event.ContactChange.delete(cid, modifier.id));
  }

  @override
  Future<Null> removeData(int id, int rid, model.User modifier) async {
    if (id == model.BaseContact.noId || rid == model.Reception.noId) {
      throw ClientError('Empty id');
    }

    final Directory recDir = Directory('$path/$id/receptions');
    final File file = File('${recDir.path}/$rid.json');
    if (!file.existsSync()) {
      throw NotFound('No file $file');
    }

    _log.finest('Removing file ${file.path}');

    if (this._git != null) {
      await _git.remove(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'removed $id from $rid',
          _authorString(modifier));
    } else {
      file.deleteSync();
    }

    if (logChanges) {
      ChangeLogger(recDir.path).add(
          model.ReceptionDataChangelogEntry.delete(
              modifier.reference, id, rid));
    }

    _receptionDataChangeBus
        .fire(event.ReceptionData.delete(id, rid, modifier.id));
  }

  @override
  Future<Null> update(model.BaseContact contact, model.User modifier) async {
    final File file = File('$path/${contact.id}/contact.json');

    if (!file.existsSync()) {
      throw NotFound();
    }

    file.writeAsStringSync(_jsonpp.convert(contact));

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'updated ${contact.name}',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger('$path/${contact.id}').add(
          model.ContactChangelogEntry.update(modifier.reference, contact));
    }

    _changeBus.fire(event.ContactChange.update(contact.id, modifier.id));
  }

  @override
  Future<Null> updateData(
      model.ReceptionAttributes attr, model.User modifier) async {
    if (attr.cid == model.BaseContact.noId) {
      throw ClientError('Empty id');
    }
    final Directory recDir = Directory('$path/${attr.cid}/receptions');
    final File file = File('${recDir.path}/${attr.receptionId}.json');
    if (!file.existsSync()) {
      throw NotFound('No file $file');
    }

    _log.finest('Creating file ${file.path}');
    file.writeAsStringSync(_jsonpp.convert(attr));

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'updated ${attr.cid} in ${attr.receptionId}',
          _authorString(modifier));
    }

    if (logChanges) {
      ChangeLogger(recDir.path).add(
          model.ReceptionDataChangelogEntry.update(
              modifier.reference, attr));
    }

    _receptionDataChangeBus.fire(event.ReceptionData.update(
        attr.cid, attr.receptionId, modifier.id));
  }

  /// Lists Git commits on stored objects.
  ///
  /// The type of objects may be either [model.BaseContact] or
  /// [model.ReceptionAttributes] or both - based on how many parameters
  /// are passed.
  /// Throws [UnsupportedError] if the filestore is instantiated without
  /// Git revisioning.
  @override
  Future<Iterable<model.Commit>> changes([int cid, int rid]) async {
    if (this._git == null) {
      throw UnsupportedError(
          'Filestore is instantiated without git support');
    }

    FileSystemEntity fse;

    if (cid == null) {
      fse = Directory(path);
    } else {
      if (rid == null) {
        fse = Directory('$path/$cid');
      } else {
        fse = File('$path/$cid/receptions/$rid.json');
      }
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
      final int id = int.parse(parts.first);

      if (parts.last == 'contact.json') {
        return model.ContactChange(fc.changeType, id);
      } else if (parts.length > 2 && parts[1] == 'receptions') {
        final int rid = int.parse(parts[2].split('.').first);
        return model.ReceptionAttributeChange(fc.changeType, id, rid);
      } else {
        throw StateError('Could not parse filechange ${fc.toJson()}');
      }
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

  /// Return the logged changelog values for [cid] as a raw string.
  Future<String> changeLog(int cid) async =>
      logChanges ? ChangeLogger(_contactDir(cid).path).contents() : '';

  /// Return the logged reception data changelog values for [cid] as a raw
  /// string.
  Future<String> receptionChangeLog(int cid) async =>
      logChanges ? ChangeLogger(_receptionDir(cid).path).contents() : '';

  Directory _receptionDir(int cid) => Directory('$path/$cid/receptions');

  File _receptionFile(int cid, int rid) =>
      File('$path/$cid/receptions/$rid.json');

  Directory _contactDir(int cid) => Directory('$path/$cid');
}
