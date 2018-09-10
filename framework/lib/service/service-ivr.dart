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
  RESTIvrStore(Uri this.host, String this.token, this._backend);

  final WebService _backend;

  /// The uri of the connected backend.
  final Uri host;

  /// The token used for authenticating with the backed.
  final String token;

  @override
  Future<model.IvrMenu> create(model.IvrMenu menu, [model.User user]) async {
    Uri url = resource.Ivr.list(host);
    url = _appendToken(url, token);
    print(menu.toJson());

    final String response = await _backend.post(url, _json.encode(menu));

    return model.IvrMenu.fromJson(
        _json.decode(response) as Map<String, dynamic>);
  }

  Future<Iterable<String>> deploy(String menuName) async {
    Uri url = resource.Ivr.deploy(host, menuName);
    url = _appendToken(url, token);

    return _json.decode(await _backend.post(url, '')) as Iterable<String>;
  }

  @override
  Future<Null> remove(String menuName, model.User modifier) async {
    Uri url = resource.Ivr.single(host, menuName);
    url = _appendToken(url, token);

    await _backend.delete(url);
  }

  @override
  Future<model.IvrMenu> get(String menuName) async {
    Uri url = resource.Ivr.single(host, menuName);
    url = _appendToken(url, token);

    final String response = await _backend.get(url);
    return model.IvrMenu.fromJson(
        _json.decode(response) as Map<String, dynamic>);
  }

  @override
  Future<Iterable<model.IvrMenu>> list() async {
    Uri url = resource.Ivr.list(host);
    url = _appendToken(url, token);

    final String response = await _backend.get(url);
    final List<Map<String, dynamic>> maps =
        (_json.decode(response) as List<dynamic>).cast<Map<String, dynamic>>();

    return maps.map((Map<String, dynamic> map) => model.IvrMenu.fromJson(map));
  }

  @override
  Future<model.IvrMenu> update(model.IvrMenu menu, [model.User user]) async {
    Uri url = resource.Ivr.single(host, menu.name);
    url = _appendToken(url, token);

    final String response = await _backend.put(url, _json.encode(menu));

    return model.IvrMenu.fromJson(
        _json.decode(response) as Map<String, dynamic>);
    ;
  }

  @override
  Future<Iterable<model.Commit>> changes([String menuName]) async {
    Uri url = resource.Ivr.changeList(host, menuName);
    url = _appendToken(url, token);

    final String response = await _backend.get(url);
    final List<Map<String, dynamic>> maps =
        (_json.decode(response) as List<dynamic>).cast<Map<String, dynamic>>();
    return maps.map((Map<String, dynamic> map) => model.Commit.fromJson(map));
  }

  Future<String> changelog(String menuName) {
    Uri url = resource.Ivr.changelog(host, menuName);
    url = _appendToken(url, token);

    return _backend.get(url);
  }
}
