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

/// Message store client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
class RESTMessageStore implements storage.Message {
  final WebService _backend;

  /// The uri of the connected backend.
  final Uri host;

  /// The token used for authenticating with the backed.
  final String token;

  const RESTMessageStore(Uri this.host, String this.token, this._backend);

  @override
  Future<model.Message> get(int mid) => this
      ._backend
      .get(_appendToken(resource.Message.single(this.host, mid), this.token))
      .then((String response) => new model.Message.fromJson(
          _json.decode(response) as Map<String, dynamic>));

  @override
  Future<Iterable<model.Message>> getByIds(Iterable<int> ids) async {
    Uri uri = resource.Message.list(host);
    uri = _appendToken(uri, token);

    final Iterable<Map<String, dynamic>> maps = await _backend
        .post(uri, _json.encode(ids))
        .then((String response) => _json.decode(response));

    return maps
        .map((Map<String, dynamic> map) => new model.Message.fromJson(map));
  }

  Future<model.MessageQueueEntry> enqueue(model.Message message) {
    Uri uri = resource.Message.send(this.host, message.id);
    uri = _appendToken(uri, this.token);

    return this
        ._backend
        .post(uri, _json.encode(message))
        .then(_json.decode)
        .then((Map<String, dynamic> queueItemMap) =>
            new model.MessageQueueEntry.fromJson(queueItemMap));
  }

  @override
  Future<model.Message> create(
      model.Message message, model.User modifier) async {
    Uri uri = resource.Message.root(this.host);
    uri = _appendToken(uri, this.token);

    return _backend
        .post(uri, _json.encode(message))
        .then(_json.decode)
        .then((Map<String, dynamic> map) => new model.Message.fromJson(map));
  }

  @override
  Future<Null> remove(int mid, model.User modifier) async {
    Uri uri = resource.Message.single(host, mid);
    uri = _appendToken(uri, token);

    await _backend.delete(uri);
  }

  @override
  Future<model.Message> update(model.Message message, model.User modifier) =>
      _backend
          .put(
              _appendToken(
                  resource.Message.single(this.host, message.id), this.token),
              _json.encode(message))
          .then((String response) => new model.Message.fromJson(
              _json.decode(response) as Map<String, dynamic>));

  Future<Iterable<model.Message>> list({model.MessageFilter filter}) => this
      ._backend
      .get(_appendToken(
          resource.Message.list(this.host, filter: filter), this.token))
      .then((String response) => (_json.decode(response)
              as Iterable<Map<String, dynamic>>)
          .map((Map<String, dynamic> map) => new model.Message.fromJson(map)));

  @override
  Future<Iterable<model.Message>> listDay(DateTime day,
      {model.MessageFilter filter}) async {
    Uri uri = resource.Message.listDay(host, day, filter: filter);
    uri = _appendToken(uri, token);

    return _backend.get(uri).then((String response) => (_json.decode(response)
            as Iterable<Map<String, dynamic>>)
        .map((Map<String, dynamic> map) => new model.Message.fromJson(map)));
  }

  @override
  Future<Iterable<model.Message>> listDrafts({model.MessageFilter filter}) {
    Uri uri = resource.Message.listDrafts(host, filter: filter);
    uri = _appendToken(uri, token);

    return _backend.get(uri).then((String response) => (_json.decode(response)
            as Iterable<Map<String, dynamic>>)
        .map((Map<String, dynamic> map) => new model.Message.fromJson(map)));
  }

  @override
  Future<Iterable<model.Commit>> changes([int mid]) {
    Uri url = resource.Message.changeList(host, mid);
    url = _appendToken(url, this.token);

    Iterable<model.Commit> convertMaps(Iterable<Map<String, dynamic>> maps) =>
        maps.map((Map<String, dynamic> map) => new model.Commit.fromJson(map));

    return this._backend.get(url).then(_json.decode).then(convertMaps);
  }
}
).then(convertMaps);
  }
}
