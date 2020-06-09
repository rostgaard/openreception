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

/// IVR store and service client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
class RESTIvrStore implements storage.Ivr {
  RESTIvrStore(Uri host, String token, dynamic backend)
      : _client = api.ApiClient(basePath: host.toString()) {
    _client.getAuthentication<api.ApiKeyAuth>('ApiKeyAuth').apiKey = token;
  }

  final api.ApiClient _client;

  @override
  Future<model.IvrMenu> create(model.IvrMenu menu, [model.User user]) async {
    final response = await _client.client
        .post("/ivr-menu", body: _json.encode(menu));
    if (response.statusCode >= 400) {
      WebService.checkResponse(
          response.statusCode, "POST", null, response.body);

      return model.IvrMenu.fromJson(_json.decode(response.body));
    }
  }

  Future<Iterable<String>> deploy(String menuName) async {
    final response = await _client.client
        .post('/ivr-menu/${menuName}/deploy');
    if (response.statusCode >= 400) {
      WebService.checkResponse(response.statusCode, "GET", null, response.body);

      return _json.decode(response.body) as List<String>;
    }
  }

  @override
  Future<Null> remove(String menuName, model.User modifier) async {
    final response =
    await _client.client.delete("/ivr-menu/" + menuName);
    if (response.statusCode >= 400) {
      WebService.checkResponse(response.statusCode, "GET", null, response.body);

      return null;
    }
  }

  @override
  Future<model.IvrMenu> get(String menuName) async {
    final response =
    await _client.client.get("/ivr-menu/" + menuName);
    if (response.statusCode >= 400) {
      WebService.checkResponse(response.statusCode, "GET", null, response.body);

      return model.IvrMenu.fromJson(_json.decode(response.body));
    }
  }

  @override
  Future<List<model.IvrMenu>> list() async {
    final response = await _client.client.get("/ivr-menu");
    WebService.checkResponse(response.statusCode, "GET", null, response.body);

    return (_json.decode(response.body) as List)
        .map((e) => model.IvrMenu.fromJson(e))
        .toList();
  }

  @override
  Future<model.IvrMenu> update(model.IvrMenu menu, [model.User user]) async {
    final response = await _client.client
        .put('/ivr-menu/${menu.name}', body: _json.encode(menu));
    WebService.checkResponse(response.statusCode, "GET", null, response.body);

    return model.IvrMenu.fromJson(_json.decode(response.body));
  }

  @override
  Future<List<model.Commit>> changes([String menuName]) async {
    throw UnimplementedError();

  }

  Future<String> changelog(String menuName) {
    throw UnimplementedError();

  }
}
