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

/// Organization store client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
class RESTOrganizationStore implements storage.Organization {

  RESTOrganizationStore(Uri host, String token, dynamic backend) : _client =
  api.OrganizationApi(api.ApiClient(basePath: host.toString())) {
    _client.apiClient.getAuthentication<api.ApiKeyAuth>('ApiKeyAuth').apiKey =
        token;
  }

  final api.OrganizationApi _client;

  @override
  Future<List<model.BaseContact>> contacts(int oid) async {
    try {
      return await _client.organizationContacts(oid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.ReceptionReference>> receptions(int oid) async {
    try {
      return await _client.organizationReceptions(oid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }


  @override
  Future<model.Organization> get(int oid) async {
    try {
      return await _client.fetch(oid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<model.OrganizationReference> create(
      model.Organization organization, model.User modifier) async {
    try {
      return await _client.createOrg(organization);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<model.OrganizationReference> update(
      model.Organization organization, model.User modifier) async {
    try {
      return await _client.update(organization.id, organization);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<Null> remove(int oid, model.User modifier) async {
    try {
      await _client.delete(oid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.OrganizationReference>> list() async {
    try {
      return await _client.orgs();
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.Commit>> changes([int oid]) async {
    try {
      if (oid != 0 ) {
        return await _client.organizationHistory(oid);

      } else {
        return await _client.organizationHistories();
      }
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  Future<String> changelog(int oid) async {
    try {
      return await _client.organizationChangelog(oid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }
}
