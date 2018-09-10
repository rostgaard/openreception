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
  final WebService _backend;

  /// The uri of the connected backend.
  final Uri host;

  /// The token used for authenticating with the backed.
  final String token;

  RESTReceptionStore(Uri this.host, String this.token, this._backend);

  @override
  Future<model.ReceptionReference> create(
      model.Reception reception, model.User modifier) {
    Uri url = resource.Reception.root(this.host);
    url = _appendToken(url, this.token);

    return _backend
        .post(url, _json.encode(reception))
        .then(_json.decode)
        .then((map) => new model.ReceptionReference.fromJson(map));
  }

  @override
  Future<model.Reception> get(int receptionID) {
    Uri url = resource.Reception.single(this.host, receptionID);
    url = _appendToken(url, this.token);

    return this._backend.get(url).then((String response) =>
        new model.Reception.fromJson(
            _json.decode(response) as Map<String, dynamic>));
  }

  @override
  Future<Iterable<model.ReceptionReference>> list() {
    Uri url = resource.Reception.list(this.host);
    url = _appendToken(url, this.token);

    return this._backend.get(url).then((String response) =>
        (_json.decode(response) as Iterable<Map<String, dynamic>>).map(
            (Map<String, dynamic> map) =>
                new model.ReceptionReference.fromJson(map)));
  }

  @override
  Future<Null> remove(int rid, model.User modifier) async {
    Uri url = resource.Reception.single(this.host, rid);
    url = _appendToken(url, this.token);

    await _backend.delete(url);
  }

  @override
  Future<model.ReceptionReference> update(
      model.Reception reception, model.User modifier) {
    Uri url = resource.Reception.single(this.host, reception.id);
    url = _appendToken(url, this.token);

    String data = _json.encode(reception);

    return this
        ._backend
        .put(url, data)
        .then(_json.decode)
        .then((map) => new model.ReceptionReference.fromJson(map));
  }

  @override
  Future<Iterable<model.Commit>> changes([int rid]) async {
    Uri url = resource.Reception.changeList(host, rid);
    url = _appendToken(url, this.token);

    final String response = await _backend.get(url);
    final Iterable<Map> maps = _json.decode(response);
    return maps.map((map) => new model.Commit.fromJson(map));
  }

  Future<String> changelog(int rid) {
    Uri url = resource.Reception.changelog(host, rid);
    url = _appendToken(url, this.token);

    return _backend.get(url);
  }
}
