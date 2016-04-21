part of management_tool.controller;

class Contact {
  final service.RESTContactStore _service;
  final model.User _appUser;

  Contact(this._service, this._appUser);

  Future<Iterable<model.ContactReference>> receptionContacts(int rid) =>
      _service.receptionContacts(rid).catchError(_handleError);

  Future<Iterable<model.ReceptionReference>> receptions(int rid) =>
      _service.receptions(rid).catchError(_handleError);

  Future<Iterable<model.OrganizationReference>> contactOrganizations(int cid) =>
      _service.organizations(cid).catchError(_handleError);

  Future<model.ReceptionAttributes> getByReception(int cid, int rid) =>
      _service.data(cid, rid).catchError(_handleError);

  Future<Iterable<model.ContactReference>> list() =>
      _service.list().catchError(_handleError);

  Future<model.BaseContact> get(int cid) =>
      _service.get(cid).catchError(_handleError);

  Future<model.ContactReference> update(model.BaseContact contact) =>
      _service.update(contact, _appUser).catchError(_handleError);

  Future<model.ContactReference> create(model.BaseContact contact) =>
      _service.create(contact, _appUser).catchError(_handleError);

  Future remove(int cid) =>
      _service.remove(cid, _appUser).catchError(_handleError);

  Future<model.ReceptionContact> addToReception(
          model.ReceptionAttributes attr) =>
      _service.addData(attr, _appUser).catchError(_handleError);

  Future removeFromReception(int cid, int rid) =>
      _service.removeData(cid, rid, _appUser).catchError(_handleError);

  Future<model.ReceptionContact> updateInReception(
          model.ReceptionAttributes attr) =>
      _service.updateData(attr, _appUser).catchError(_handleError);

  Future<Map<model.ReceptionReference, Iterable<model.ContactReference>>>
      colleagues(int cid) async {
    Map map = {};
    List<model.ContactReference> foundColleagues = [];
    final Iterable<model.ReceptionReference> receptions =
        await _service.receptions(cid);

    await Future.wait(receptions.map((rRef) async {
      map[rRef] = await _service.receptionContacts(rRef.id);
    }));

    return map;
  }
}