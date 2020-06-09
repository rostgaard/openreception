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

/// Dialplan store and service client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
class RESTDialplanStore implements storage.ReceptionDialplan {
  RESTDialplanStore(Uri host, String token, dynamic backend)
      : _client = api.ApiClient(basePath: host.toString()) {
    _client.getAuthentication<api.ApiKeyAuth>('ApiKeyAuth').apiKey = token;
  }

  final api.ApiClient _client;

  @override
  Future<model.ReceptionDialplan> create(model.ReceptionDialplan rdp,
      [model.User user]) async {
    final response = await _client.client
        .post("/receptiondialplan", body: _json.encode(rdp));
    WebService.checkResponse(response.statusCode, "POST", null, response.body);

    return model.ReceptionDialplan.fromJson(_json.decode(response.body));
  }

  @override
  Future<model.ReceptionDialplan> get(String extension) async {
    final response =
        await _client.client.get("/receptiondialplan/" + extension);
    WebService.checkResponse(response.statusCode, "GET", null, response.body);

    return model.ReceptionDialplan.fromJson(_json.decode(response.body));
  }

  @override
  Future<List<model.ReceptionDialplan>> list() async {
    final response = await _client.client.get("/receptiondialplan");
    WebService.checkResponse(response.statusCode, "GET", null, response.body);

    return (_json.decode(response.body) as List)
        .map((e) => model.ReceptionDialplan.fromJson(e))
        .toList();
  }

  @override
  Future<model.ReceptionDialplan> update(model.ReceptionDialplan rdp,
      [model.User user]) async {
    final response = await _client.client
        .put('/receptiondialplan/${rdp.extension}', body: _json.encode(rdp));
    WebService.checkResponse(response.statusCode, "GET", null, response.body);

    return model.ReceptionDialplan.fromJson(_json.decode(response.body));
  }

  @override
  Future<Null> remove(String extension, model.User user) async {
    final response =
        await _client.client.delete("/receptiondialplan/" + extension);
    WebService.checkResponse(response.statusCode, "GET", null, response.body);

    return model.ReceptionDialplan.fromJson(_json.decode(response.body));
  }

  Future<Iterable<String>> analyze(String extension) async {
    final response = await _client.client
        .get("/receptiondialplan/" + extension + '/analyze');
    WebService.checkResponse(response.statusCode, "GET", null, response.body);

    return _json.decode(response.body) as List<String>;
  }

  /// (Re-)deploys a dialplan for a the reception identified by [rid]
  Future<List<String>> deployDialplan(String extension, int rid) async {
    final response = await _client.client
        .post('/receptiondialplan/${extension}/deploy/${rid}');
    WebService.checkResponse(response.statusCode, "GET", null, response.body);

    return _json.decode(response.body) as List<String>;
  }

  /// Performs a PBX-reload of the deployed dialplan configuration.
  Future<Null> reloadConfig() async {
    final response =
        await _client.client.post("/receptiondialplan/reloadConfig");
    WebService.checkResponse(response.statusCode, "GET", null, response.body);

    return model.ReceptionDialplan.fromJson(_json.decode(response.body));
  }

  @override
  Future<List<model.Commit>> changes([String extension]) async {
    throw UnimplementedError();
  }

  Future<String> changelog(String extension) {
    throw UnimplementedError();
  }
}
