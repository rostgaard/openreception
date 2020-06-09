/*                  This file is part of OpenReception
                   Copyright (C) 2014-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.service;

/// Contact store client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
class RESTContactStore implements storage.Contact {

  RESTContactStore(Uri host, String token, dynamic _backend) : _client =
  api.ContactApi(api.ApiClient(basePath: host.toString())) {
    _client.apiClient.getAuthentication<api.ApiKeyAuth>('ApiKeyAuth').apiKey =
        token;
  }

  final api.ContactApi _client;

  @override
  Future<List<model.ReceptionReference>> receptions(int cid) async {
    try {
      return _client.contactReceptions(cid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.OrganizationReference>> organizations(int oid) async {
    try {
      return  _client.contactOrganizations(oid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<model.BaseContact> get(int id) async{
    try {
      return  _client.getBaseContact(id);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<model.BaseContact> create(
      model.BaseContact contact, model.User modifier) async {
    try {
      return  _client.createBaseContact(contact);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<Null> update(model.BaseContact contact, model.User modifier) async {
    try {
      return  _client.updateBaseContact(contact.id, contact);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<Null> remove(int id, model.User user) async {
    try {
      return  _client.removeBaseContact(
      id);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.BaseContact>> list() {
    try {
      return  _client.getBaseContacts();
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<model.ReceptionAttributes> data(int cid, int rid) async {
    try {
      return  _client.receptionContact(cid, rid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.ReceptionContact>> receptionContacts(int rid) async {
    try {
      return  _client.contactsByReception(rid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<Null> addData(model.ReceptionAttributes attr, model.User user) async {
    try {
      return  _client.addToReception(attr.cid, attr.receptionId, attr);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.BaseContact>> organizationContacts(int oid)async {
    try {
      return  _client.listByOrganization(oid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<Null> removeData(int cid, int rid, model.User user) async {
    try {
      return await _client.removeFromReception(cid, rid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<Null> updateData(
      model.ReceptionAttributes attr, model.User modifier) async {
    try {
      return await _client.updateReceptionData(attr.cid, attr.receptionId, attr);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.Commit>> changes([int cid, int rid]) async {
    try {
      if (![null,0].contains(rid)) {
        return  _client.contactReceptionHistory(cid, rid);

      } else {
        return  changelog(cid);
      }
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  Future<String> contactChangeLog(int cid) {
    try {
        return  _client.contactChangelog(cid);

    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  Future<List<model.Commit>> changelog(int cid) {
    try {
      if (cid != 0 ) {
        return  _client.contactHistory(cid);

      } else {
        return  _client.contactHistories();
      }
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  Future<String> receptionChangelog(int cid) {
    try {
      return  _client.contactReceptionChangelog(cid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }
}
