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

enum ServerType {
  authentication,
  calendar,
  callflow,
  cdr,
  contact,
  dialplan,
  message,
  notification,
  notificationSocket,
  user,
  reception
}

ServerType decodeServerType(String type) {
  const Map<String, ServerType> decodeMap = const <String, ServerType>{
    key.authentication: ServerType.authentication,
    key.calendar: ServerType.calendar,
    key.callflow: ServerType.callflow,
    key.cdr: ServerType.cdr,
    key.contact: ServerType.contact,
    key.dialplan: ServerType.dialplan,
    key.message: ServerType.message,
    key.notification: ServerType.notification,
    key.notificationSocket: ServerType.notificationSocket,
    key.user: ServerType.user,
    key.reception: ServerType.reception
  };

  if (!decodeMap.containsKey(type)) {
    throw new StateError('Undefined ServerType: $type');
  }

  return decodeMap[type];
}

String _encodeServerType(ServerType type) {
  const Map<ServerType, String> encodeMap = const <ServerType, String>{
    ServerType.authentication: key.authentication,
    ServerType.calendar: key.calendar,
    ServerType.callflow: key.callflow,
    ServerType.cdr: key.cdr,
    ServerType.contact: key.contact,
    ServerType.dialplan: key.dialplan,
    ServerType.message: key.message,
    ServerType.notification: key.notification,
    ServerType.notificationSocket: key.notificationSocket,
    ServerType.user: key.user,
    ServerType.reception: key.reception
  };

  if (!encodeMap.containsKey(type)) {
    throw new StateError('Undefined ServerType: $type');
  }

  return encodeMap[type];
}

/// Configuration service client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
///
/// A [RESTConfiguration] is similar to a broker registry, that maintains
/// and stores location identifiers for other services.
class RESTConfiguration {
  /// Create a new [RESTConfiguration] client.
  RESTConfiguration(Uri this.host, this._backend);

  final WebService _backend;

  /// The uri of the connected backend.
  final Uri host;

  /// Returns a [model.ClientConfiguration] object.
  Future<model.ClientConfiguration> clientConfig() {
    final Uri uri = resource.Config.get(this.host);

    return _backend.get(uri).then((String response) =>
        new model.ClientConfiguration.fromJson(
            _json.decode(response) as Map<String, dynamic>));
  }

  ///Registers a server in the config server registry.
  Future<Null> register(ServerType type, Uri registerUri) async {
    final Uri uri = resource.Config.root(this.host);
    final Map<String, dynamic> body = <String, dynamic>{
      _encodeServerType(type): registerUri.toString()
    };

    await _backend.put(uri, _json.encode(body));
  }
}
