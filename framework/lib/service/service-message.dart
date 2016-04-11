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

part of openreception.service;

class RESTMessageStore implements Storage.Message {
  static final String className = '${libraryName}.RESTMessageStore';

  WebService _backend = null;
  Uri _host;
  String _token = '';

  RESTMessageStore(Uri this._host, String this._token, this._backend);

  /**
   *
   */
  Future<Model.Message> get(int mid) => this
      ._backend
      .get(_appendToken(Resource.Message.single(this._host, mid), this._token))
      .then((String response) =>
          new Model.Message.fromMap(JSON.decode(response)));

  /**
   *
   */
  Future<Model.MessageQueueEntry> enqueue(Model.Message message) {
    Uri uri = Resource.Message.send(this._host, message.id);
    uri = _appendToken(uri, this._token);

    return this
        ._backend
        .post(uri, JSON.encode(message.asMap))
        .then(JSON.decode)
        .then((Map queueItemMap) =>
            new Model.MessageQueueEntry.fromMap(queueItemMap));
  }

  /**
   *
   */
  Future<Model.Message> create(Model.Message message, Model.User modifier) =>
      _backend
          .post(_appendToken(Resource.Message.root(this._host), this._token),
              JSON.encode(message.asMap))
          .then((String response) =>
              new Model.Message.fromMap(JSON.decode(response)));

  Future remove(int mid, Model.User modifier) {
    Uri uri = Resource.Message.single(_host, mid);
    uri = _appendToken(uri, _token);

    return _backend.delete(uri);
  }

  /**
   *
   */
  Future<Model.Message> update(Model.Message message, Model.User modifier) =>
      _backend
          .put(
              _appendToken(
                  Resource.Message.single(this._host, message.id), this._token),
              JSON.encode(message.asMap))
          .then((String response) =>
              new Model.Message.fromMap(JSON.decode(response)));
  /**
   *
   */
  Future<Iterable<Model.Message>> list({Model.MessageFilter filter}) => this
      ._backend
      .get(_appendToken(
          Resource.Message.list(this._host, filter: filter), this._token))
      .then((String response) => (JSON.decode(response) as Iterable)
          .map((Map map) => new Model.Message.fromMap(map)));

  /**
   *
   */
  Future<Iterable<Model.Commit>> changes([int mid]) {
    Uri url = Resource.Message.changeList(_host, mid);
    url = _appendToken(url, this._token);

    Iterable<Model.Commit> convertMaps(Iterable<Map> maps) =>
        maps.map(Model.Commit.decode);

    return this._backend.get(url).then(JSON.decode).then(convertMaps);
  }
}
