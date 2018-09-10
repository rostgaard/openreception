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
  RESTDialplanStore(Uri this.host, String this.token, this._backend);

  final WebService _backend;

  /// The uri of the connected backend.
  final Uri host;

  /// The token used for authenticating with the backed.
  final String token;

  @override
  Future<model.ReceptionDialplan> create(model.ReceptionDialplan rdp,
      [model.User user]) async {
    Uri url = resource.ReceptionDialplan.list(host);
    url = _appendToken(url, token);

    return model.ReceptionDialplan.fromJson(_json.decode(await _backend
        .post(url, _json.encode(rdp))) as Map<String,dynamic>);
  }

  @override
  Future<model.ReceptionDialplan> get(String extension) {
    Uri url = resource.ReceptionDialplan.single(host, extension);
    url = _appendToken(url, token);

    return _backend
        .get(url)
        .then(_json.decode)
        .then((map) => model.ReceptionDialplan.fromJson(map));
  }

  @override
  Future<Iterable<model.ReceptionDialplan>> list() async {
    Uri url = resource.ReceptionDialplan.list(host);
    url = _appendToken(url, token);

    final String response = await _backend.get(url);
    final Iterable<Map> maps = _json.decode(response);

    return maps.map((map) => model.ReceptionDialplan.fromJson(map));
  }

  @override
  Future<model.ReceptionDialplan> update(model.ReceptionDialplan rdp,
      [model.User user]) {
    Uri url = resource.ReceptionDialplan.single(host, rdp.extension);
    url = _appendToken(url, token);

    return _backend
        .put(url, _json.encode(rdp))
        .then(_json.decode)
        .then((map) => model.ReceptionDialplan.fromJson(map));
  }

  @override
  Future<Null> remove(String extension, model.User user) async {
    Uri url = resource.ReceptionDialplan.single(host, extension);
    url = _appendToken(url, token);

    await _backend.delete(url);
  }

  Future<Iterable<String>> analyze(String extension) async {
    Uri url = resource.ReceptionDialplan.analyze(host, extension);
    url = _appendToken(url, token);

    return await _backend.post(url, '').then(_json.decode) as Iterable<String>;
  }

  /// (Re-)deploys a dialplan for a the reception identified by [rid]
  Future<Iterable<String>> deployDialplan(String extension, int rid) async {
    Uri url = resource.ReceptionDialplan.deploy(host, extension, rid);
    url = _appendToken(url, token);

    return (_json.decode(await _backend.post(url, '')) as List<dynamic>).cast<String>();
  }

  /// Performs a PBX-reload of the deployed dialplan configuration.
  Future<Null> reloadConfig() async {
    Uri url = resource.ReceptionDialplan.reloadConfig(host);
    url = _appendToken(url, token);

    await _backend.post(url, '').then(_json.decode);
  }

  @override
  Future<Iterable<model.Commit>> changes([String extension]) async {
    Uri url = resource.ReceptionDialplan.changeList(host, extension);
    url = _appendToken(url, this.token);

    final String response = await _backend.get(url);
    final Iterable<Map> maps = _json.decode(response);

    return maps.map((map) => model.Commit.fromJson(map));
  }

  Future<String> changelog(String extension) {
    Uri url = resource.ReceptionDialplan.changelog(host, extension);
    url = _appendToken(url, this.token);

    return _backend.get(url);
  }
}
