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

library ors.controller.notification;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:ors/response_utils.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart' as sWs;
import 'package:web_socket_channel/web_socket_channel.dart';

class Notification {
  Notification(this._authService);

  final Logger _log = Logger('server.controller.notification');
  final List _stats = [];
  int _sendCountBuffer = 0;

  final Map<int, List<WebSocketChannel>> clientRegistry =
      Map<int, List<WebSocketChannel>>();

  final service.Authentication _authService;

  void initStats() {
    Timer.periodic(Duration(seconds: 1), _tick);
  }

  void _tick(Timer t) {
    if (_stats.length > 60) {
      _stats.removeAt(0);
    }

    _stats.add(_sendCountBuffer);
    _sendCountBuffer = 0;
  }

  Response statistics(Request request) {
    List<List<int>> stats = [];

    int i = 0;
    _stats.forEach((num) {
      stats.add(<int>[i, num]);
      i++;
    });
    return Response.ok(json.encode(stats));
  }

  /// Broadcasts a message to every connected websocket.
  Future<Response> broadcast(Request request) async {
    try {
      final Map contentMap = json.decode(await request.readAsString());

      return okJson(_sendToAll(contentMap));
    } catch (error, stackTrace) {
      _log.warning('Bad client request', error, stackTrace);
      return clientError('Malformed json body');
    }
  }

  Map _sendToAll(Map content) {
    int success = 0;
    int failure = 0;

    final List<WebSocketChannel> recipientSockets = [];

    clientRegistry.values.fold(recipientSockets,
        (List<WebSocketChannel> combined, websockets) => combined..addAll(websockets));

    /// Prevent clients from being notified in the same order always.
    recipientSockets.shuffle();

    recipientSockets.forEach(((WebSocketChannel ws) {
      try {
        String contentString = json.encode(content);

        ws.sink.add(contentString);
        _sendCountBuffer += contentString.codeUnits.length;
        success++;
      } catch (error, stackTrace) {
        failure++;
        _log.severe("Failed to send message to client");
        _log.severe(error, stackTrace);
      }
    }));

    return <String, dynamic>{
      "status": {"success": success, "failed": failure}
    };
  }

  /// WebSocket registration handling.
  /// Registers and un-registers the the websocket in the global registry.
  Map _register(WebSocketChannel webSocket, int uid) {
    _log.info('New WebSocket connection from uid $uid');

    /// Make sure that there is a list to insert into.
    if (clientRegistry[uid] == null) {
      clientRegistry[uid] = <WebSocketChannel>[];
    }
    clientRegistry[uid].add(webSocket);

    /// Listen for incoming data. We expect the data to be a json-encoded String.
    webSocket.stream.map((dynamic string) {
      try {
        return json.decode(string);
      } catch (error) {
        return <String, String>{
          "status": "Malformed content - expected json string."
        };
      }
    }).listen((map) {
      _log.warning(
          'Client $uid tried to send us a message. This is not supported, echoing back.');
      webSocket.sink.add(json.encode(map)); // Echo.
    }, onError: (error, stackTrace) {
      _log.severe('Client $uid sent us a very malformed message. $error : ',
          stackTrace);
      webSocket.sink.close(WebSocketStatus.unsupportedData, "Bad request");}
      , onDone: () {
      _log.info(
          'Disconnected WebSocket connection from uid $uid', "handleWebsocket");
      clientRegistry[uid].remove(webSocket);

      model.ClientConnection conn = model.ClientConnection()
        ..userId = uid
        ..connectionCount = clientRegistry[uid].length;
      event.ClientConnectionState e = event.ClientConnectionState(conn);

      _sendToAll(e.toJson());
    });

    model.ClientConnection conn = model.ClientConnection()
      ..userId = uid
      ..connectionCount = clientRegistry[uid].length;
    event.ClientConnectionState e = event.ClientConnectionState(conn);

    return _sendToAll(e.toJson());
  }

  Future<Response> handleWsConnect(Request request) async {
    model.User user;
    try {
      user = await _authService.userOf(_tokenFrom(request));
    } catch (e) {
      _log.warning('Could not reach authentication server', e);
      return authServerDown();
    }

    Handler handleConnection = sWs.webSocketHandler((ws) {
      _register(ws, user.id);
    });

    return handleConnection(request);
  }

  /// Send primitive. Expects the request body to be a json string with a
  /// list of recipients in the 'recipients' field.
  /// The 'message' field is also mandatory for obvious reasons.
  Future<Response> send(Request request) async {
    Map<String,dynamic> map;
    try {
      map = json.decode(await request.readAsString());
    } catch (error, stackTrace) {
      _log.warning('Bad client request', error, stackTrace);
      return clientError('Malformed json body');
    }

    Map message;
    if (!map.containsKey("message")) {
      return clientError( "Malformed json body");
    }
    message = map['message'];

    List<WebSocketChannel> channels = [];

    (map['recipients'] as Iterable).fold<List>(channels, (list, uid) {
      if (clientRegistry[uid] != null) {
        list.addAll(clientRegistry[uid]);
      }

      return list;
    }).toList()
      ..shuffle();

    _log.finest('Sending $message to ${channels.length} websocket clients');

    channels.forEach((ws) {
      ws.sink.add(json.encode(message));
    });

    return okJson(<String, dynamic>{
      "status": {"success": -1, "failed": -1}
    });
  }

  Future<Response> connectionList(Request request) async {
    Iterable<model.ClientConnection> connections =
        clientRegistry.keys.map((int uid) => model.ClientConnection()
          ..userId = uid
          ..connectionCount = clientRegistry[uid].length);

    return okJson(connections.toList(growable: false));
  }

  Future<Response> connection(Request request, final String userId) async {
    int uid = int.parse(userId);

    if (clientRegistry.containsKey(uid)) {
      model.ClientConnection conn = model.ClientConnection()
        ..userId = uid
        ..connectionCount = clientRegistry[uid].length;

      return okJson(conn);
    } else {
      return notFoundJson({'error': 'No connections for uid $uid'});
    }
  }

  /// Extracts token from request.
  String _tokenFrom(Request request) =>
      request.requestedUri.queryParameters['token'];
}
