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

/// Reception store client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
class RESTReceptionStore implements storage.Reception {

  RESTReceptionStore(Uri host, String token, dynamic _backend) : _client =
  api.ReceptionApi(api.ApiClient(basePath: host.toString())) {
    _client.apiClient.getAuthentication<api.ApiKeyAuth>('ApiKeyAuth').apiKey =
        token;
  }

  final api.ReceptionApi _client;

  @override
  Future<model.ReceptionReference> create(
      model.Reception reception, model.User modifier) async {
    try {
      return await _client.createReception(reception);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<model.Reception> get(int rid) async {
    try {
      return await _client.getReception(rid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.ReceptionReference>> list() async {
    try {
      return await _client.receptions();
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<Null> remove(int rid, model.User modifier) async {
    try {
      return await _client.removeReception(rid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<model.ReceptionReference> update(
      model.Reception reception, model.User modifier) async {
    try {
      return await _client.updateReception(reception.id, reception);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.Commit>> changes([int rid]) async {
    try {
      if (rid != 0 ) {
        return await _client.receptionHistory(rid);

      } else {
        return await _client.receptionHistories();
      }
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  Future<String> changelog(int rid) async {
    try {
      return await _client.receptionChangelog(rid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }
}
