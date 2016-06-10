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

part of openreception.framework.filestore;

class Contact implements storage.Contact {
  final Logger _log = new Logger('$libraryName.Contact');
  final String path;
  final Reception receptionStore;
  final GitEngine _git;
  Sequencer _sequencer;
  final Calendar calendarStore;
  final Map<int, String> _index = {};

  Stream<event.ContactChange> get onContactChange => _changeBus.stream;
  Stream<event.ReceptionData> get onReceptionDataChange =>
      _receptionDataChangeBus.stream;

  Bus<event.ContactChange> _changeBus = new Bus<event.ContactChange>();
  Bus<event.ReceptionData> _receptionDataChangeBus =
      new Bus<event.ReceptionData>();

  Future get initialized =>
      _git != null ? _git.initialized : new Future.value(true);
  Future get ready => _git != null ? _git.whenReady : new Future.value(true);

  int get _nextId => _sequencer.nextInt();

  /**
   *
   */
  factory Contact(Reception receptionStore, String path, [GitEngine ge]) {
    if (!new Directory(path).existsSync()) {
      new Directory(path).createSync();
    }

    if (ge != null) {
      ge.init().catchError((error, stackTrace) => Logger.root
          .shout('Failed to initialize git engine', error, stackTrace));
    }

    return new Contact._internal(
        path, receptionStore, new Calendar(path, ge), ge);
  }

  /**
   *
   */
  Contact._internal(String this.path, this.receptionStore, this.calendarStore,
      GitEngine this._git) {
    _buildIndex();
    if (_git != null) {
      _git.addIgnoredPath(_sequencer.sequencerFilePath);
    }
  }

  /**
   * Rebuilds the entire index.
   */
  void _buildIndex() {
    int highestId = 0;
    Stopwatch timer = new Stopwatch()..start();
    _log.info('Building index');
    Iterable<Directory> idDirs =
        new Directory(path).listSync().where(isDirectory);

    idDirs.forEach((dir) {
      try {
        final id = int.parse(basenameWithoutExtension(dir.path));
        _index[id] = dir.path;

        if (id > highestId) {
          highestId = id;
        }
      } catch (e) {
        _log.shout('Failed load index from file ${dir.path}');
      }
    });

    _log.info('Built index of ${_index.keys.length} elements in'
        ' ${timer.elapsedMilliseconds}ms');
    _sequencer = new Sequencer(path, explicitId: highestId);
  }

  /**
   *
   */
  Future<Iterable<model.BaseContact>> _contactsOfReception(int rid) async =>
      (await receptionContacts(rid)).map((rc) => rc.contact);

  /**
   *
   */
  Future addData(model.ReceptionAttributes attr, model.User modifier) async {
    if (attr.receptionId == model.Reception.noId) {
      throw new ArgumentError('attr.receptionId must be valid');
    }
    final recDir = new Directory('$path/${attr.cid}/receptions');
    if (!recDir.existsSync()) {
      recDir.createSync();
    }

    final File file = new File('${recDir.path}/${attr.receptionId}.json');

    if (file.existsSync()) {
      throw new storage.ClientError(
          'File already exists, please update instead');
    }

    file.writeAsStringSync(_jsonpp.convert(attr));
    _log.finest('Created new file ${file.path}');

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'added ${attr.cid} to ${attr.receptionId}',
          _authorString(modifier));
    }

    _receptionDataChangeBus.fire(new event.ReceptionData.create(
        attr.cid, attr.receptionId, modifier.id));
  }

  /**
   *
   */
  Future<model.BaseContact> create(
      model.BaseContact contact, model.User modifier,
      {bool enforceId: false}) async {
    contact.id = contact.id != model.BaseContact.noId && enforceId
        ? contact.id
        : _nextId;

    final Directory dir = new Directory('$path/${contact.id}');

    if (dir.existsSync()) {
      throw new storage.ClientError(
          'File already exists, please update instead');
    }

    dir.createSync();
    final File file = new File('${dir.path}/contact.json');

    _log.finest('Creating new file ${file.path}');
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

    _changeBus.fire(new event.ContactChange.create(contact.id, modifier.id));

    return contact;
  }

  /**
   *
   */
  Future<model.BaseContact> get(int id) async {
    final File file = new File('$path/${id}/contact.json');

    if (!file.existsSync()) {
      throw new storage.NotFound('No file ${file.path}');
    }

    try {
      final String jsonString = file.readAsStringSync();
      final model.BaseContact bc =
          model.BaseContact.decode(JSON.decode(jsonString));

      return bc;
    } catch (e) {
      throw e;
    }
  }

  /**
   *
   */
  Future<model.ReceptionAttributes> data(int id, int receptionId) async {
    final file = new File('$path/$id/receptions/$receptionId.json');
    if (!file.existsSync()) {
      throw new storage.NotFound('No file: ${file.path}');
    }

    return model.ReceptionAttributes
        .decode(JSON.decode(await file.readAsString()));
  }

  /**
   *
   */
  Future<Iterable<model.BaseContact>> list() async {
    if (!new Directory(path).existsSync()) {
      return [];
    }

    return Future.wait(_index.keys.map(get));
  }

  /**
   *
   */
  Future<Iterable<model.ReceptionReference>> receptions(int cid) async {
    final rDir = new Directory(path + '/$cid/receptions');
    if (!rDir.existsSync()) {
      return [];
    }

    final rFiles = rDir
        .listSync()
        .where((fse) => fse is File && fse.path.endsWith('.json'));

    return await Future.wait(rFiles.map((FileSystemEntity f) async {
      final int rid = int.parse(basenameWithoutExtension(f.path));

      return (await receptionStore.get(rid)).reference;
    }));
  }

  /**
   *
   */
  Future<Iterable<model.BaseContact>> organizationContacts(
      int organizationId) async {
    Iterable rRefs = await receptionStore._receptionsOfOrg(organizationId);

    Set<model.BaseContact> contacts = new Set();

    await Future.wait(rRefs.map((rRef) async {
      contacts.addAll(await _contactsOfReception(rRef.id));
    }));

    return contacts;
  }

  /**
   *
   */
  Future<Iterable<model.OrganizationReference>> organizations(int cid) async {
    Iterable<model.ReceptionReference> rRefs = await receptions(cid);

    Set<model.OrganizationReference> orgs = new Set();
    await Future.wait(rRefs.map((rid) async {
      orgs.add(new model.OrganizationReference(
          (await receptionStore.get(rid.id)).oid, ''));
    }));

    return orgs;
  }

  /**
   *
   */
  Future<Iterable<model.ReceptionContact>> receptionContacts(int rid) async {
    final subDirs =
        new Directory(path).listSync().where((fse) => fse is Directory);

    List<model.ReceptionContact> rcs = [];
    await Future.wait(subDirs.map((dir) async {
      final ridFile = new File(dir.path + '/receptions/$rid.json');

      if (ridFile.existsSync()) {
        final String bn = basename(dir.path);

        if (!bn.startsWith('.')) {
          final File contactFile = new File('${dir.path}/contact.json');
          final Future<model.BaseContact> bc = contactFile
              .readAsString()
              .then(JSON.decode)
              .then(model.BaseContact.decode);

          final Future<model.ReceptionAttributes> attr = ridFile
              .readAsString()
              .then(JSON.decode)
              .then(model.ReceptionAttributes.decode);

          rcs.add(new model.ReceptionContact(await bc, await attr));
        }
      }
    }));

    return rcs;
  }

  /**
   *
   */
  Future remove(int cid, model.User modifier) async {
    if (!_index.containsKey(cid)) {
      throw new storage.NotFound();
    }

    /// Remove reception references.
    await Future.forEach(await receptions(cid), (rRef) async {
      await removeData(cid, rRef.id, modifier);
    });

    /// Remove calendar entries.
    final model.Owner owner = new model.OwningContact(cid);
    await Future.forEach(await calendarStore.list(owner),
        (model.CalendarEntry entry) async {
      await calendarStore.remove(entry.id, owner, modifier);
    });

    /// Go ahead and remove the file.
    final File contactFile = new File(_index[cid]);

    if (this._git != null) {
      await _git.remove(
          contactFile,
          'uid:${modifier.id} - ${modifier.name} '
          'removed $cid',
          _authorString(modifier));
    } else {
      await contactFile.delete();
    }

    _index.remove(cid);

    _changeBus.fire(new event.ContactChange.delete(cid, modifier.id));
  }

  /**
   *
   */
  Future removeData(int id, int receptionId, model.User modifier) async {
    if (id == model.BaseContact.noId || receptionId == model.Reception.noId) {
      throw new storage.ClientError('Empty id');
    }

    final recDir = new Directory('$path/${id}/receptions');
    final File file = new File('${recDir.path}/${receptionId}.json');
    if (!file.existsSync()) {
      throw new storage.NotFound('No file ${file}');
    }

    _log.finest('Removing file ${file.path}');

    if (this._git != null) {
      await _git.remove(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'removed ${id} from ${receptionId}',
          _authorString(modifier));
    } else {
      file.deleteSync();
    }

    _receptionDataChangeBus
        .fire(new event.ReceptionData.delete(id, receptionId, modifier.id));
  }

  /**
   *
   */
  Future<model.BaseContact> update(
      model.BaseContact contact, model.User modifier) async {
    final File file = new File('$path/${contact.id}/contact.json');

    if (!file.existsSync()) {
      throw new storage.NotFound();
    }

    file.writeAsStringSync(_jsonpp.convert(contact));

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'updated ${contact.name}',
          _authorString(modifier));
    }

    _changeBus.fire(new event.ContactChange.update(contact.id, modifier.id));

    return contact;
  }

  /**
   *
   */
  Future updateData(model.ReceptionAttributes attr, model.User modifier) async {
    if (attr.cid == model.BaseContact.noId) {
      throw new storage.ClientError('Empty id');
    }
    final recDir = new Directory('$path/${attr.cid}/receptions');
    final File file = new File('${recDir.path}/${attr.receptionId}.json');
    if (!file.existsSync()) {
      throw new storage.NotFound('No file ${file}');
    }

    _log.finest('Creating new file ${file.path}');
    file.writeAsStringSync(_jsonpp.convert(attr));

    if (this._git != null) {
      await _git.add(
          file,
          'uid:${modifier.id} - ${modifier.name} '
          'updated ${attr.cid} in ${attr.receptionId}',
          _authorString(modifier));
    }

    _receptionDataChangeBus.fire(new event.ReceptionData.update(
        attr.cid, attr.receptionId, modifier.id));
  }

  /**
   *
   */
  Future<Iterable<model.Commit>> changes([int cid, int rid]) async {
    if (this._git == null) {
      throw new UnsupportedError(
          'Filestore is instantiated without git support');
    }

    FileSystemEntity fse;

    if (cid == null) {
      fse = new Directory('.');
    } else {
      if (rid == null) {
        fse = new Directory('$cid');
      } else {
        fse = new Directory('$cid/receptions/$rid.json');
      }
    }

    Iterable<Change> gitChanges = await _git.changes(fse);

    int extractUid(String message) => message.startsWith('uid:')
        ? int.parse(message.split(' ').first.replaceFirst('uid:', ''))
        : model.User.noId;

    model.ObjectChange convertFilechange(FileChange fc) {
      final List<String> parts = fc.filename.split('/');
      final int id = int.parse(parts[0]);

      if (parts.last == 'contact.json') {
        return new model.ContactChange(fc.changeType, id);
      } else if (parts.length > 2 && parts[1] == 'receptions') {
        final int rid = int.parse(parts[2].split('.').first);
        return new model.ReceptionAttributeChange(fc.changeType, id, rid);
      } else {
        throw new StateError('Could not parse filechange ${fc.toJson()}');
      }
    }

    Iterable<model.Commit> changes = gitChanges.map((change) =>
        new model.Commit()
          ..uid = extractUid(change.message)
          ..changedAt = change.changeTime
          ..commitHash = change.commitHash
          ..authorIdentity = change.author
          ..changes = new List<model.ObjectChange>.from(
              change.fileChanges.map(convertFilechange)));

    _log.info(changes.map((c) => c.toJson()));

    return changes;
  }
}
