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
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart' as shelf_route;
import 'package:shelf_web_socket/shelf_web_socket.dart' as sWs;
import 'package:web_socket_channel/web_socket_channel.dart';

const _json = const JsonCodec();

class Notification {
  final Logger _log = new Logger('server.controller.notification');
  final List<int> _stats = [];
  int _sendCountBuffer = 0;

  final Map<int, List<WebSocketChannel>> clientRegistry =
      new Map<int, List<WebSocketChannel>>();

  final service.Authentication _authService;

  Notification(this._authService);

  void initStats() {
    new Timer.periodic(new Duration(seconds: 1), _tick);
  }

  void _tick(Timer t) {
    if (_stats.length > 60) {
      _stats.removeAt(0);
    }

    _stats.add(_sendCountBuffer);
    _sendCountBuffer = 0;
  }

  shelf.Response statistics(shelf.Request request) {
    List<int> retval = [];

    int i = 0;
    _stats.forEach((int num) {
      retval.add([i, num]);
      i++;
    });
    return new shelf.Response.ok(_json.encode(retval));
  }

  /**
   * Broadcasts a message to every connected websocket.
   */
  Future<shelf.Response> broadcast(shelf.Request request) async {
    try {
      Map contentMap = _json.decode(await request.readAsString());

      return okJson(_sendToAll(contentMap));
    } catch (error, stackTrace) {
      _log.warning('Bad client request', error, stackTrace);
      return clientError('Malformed _json body');
    }
  }

  /**
   *
   */
  Map _sendToAll(Map content) {
    int success = 0;
    int failure = 0;

    final List<WebSocketChannel> recipientSockets = [];

    clientRegistry.values.fold(
        recipientSockets,
        (List<WebSocketChannel> combined, websockets) =>
            combined..addAll(websockets));

    /// Prevent clients from being notified in the same order always.
    recipientSockets.shuffle();

    recipientSockets.forEach(((WebSocketChannel ws) {
      try {
        String contentString = _json.encode(content);

        ws.sink.add(contentString);
        _sendCountBuffer += contentString.codeUnits.length;
        success++;
      } catch (error, stackTrace) {
        failure++;
        _log.severe("Failed to send message to client");
        _log.severe(error, stackTrace);
      }
    }));

    return {
      "status": {"success": success, "failed": failure}
    };
  }

  /**
   * WebSocket registration handling.
   * Registers and un-registers the the websocket in the global registry.
   */
  Map _register(WebSocketChannel webSocket, int uid) {
    _log.info('New WebSocket connection from uid $uid');

    /// Make sure that there is a list to insert into.
    if (clientRegistry[uid] == null) {
      clientRegistry[uid] = new List<WebSocketChannel>();
    }
    clientRegistry[uid].add(webSocket);

    /// Listen for incoming data. We expect the data to be a _json-encoded String.
    webSocket.stream.map((string) {
      try {
        return _json.decode(string);
      } catch (error) {
        return {"status": "Malformed content - expected _json string."};
      }
    }).listen((json) {
      _log.warning(
          'Client $uid tried to send us a message. This is not supported, echoing back.');
      webSocket.sink.add(_json.encode(json)); // Echo.
    }, onError: (error, stackTrace) {
      _log.severe('Client $uid sent us a very malformed message. $error : ',
          stackTrace);
      clientRegistry[uid].remove(webSocket);
      webSocket.sink.close(io.WebSocketStatus.unsupportedData, "Bad request");
    }, onDone: () {
      _log.info(
          'Disconnected WebSocket connection from uid $uid', "handleWebsocket");
      clientRegistry[uid].remove(webSocket);

      model.ClientConnection conn = new model.ClientConnection.empty()
        ..userID = uid
        ..connectionCount = clientRegistry[uid].length;
      event.ClientConnectionState e = new event.ClientConnectionState(conn);

      _sendToAll(e.toJson());
    });

    model.ClientConnection conn = new model.ClientConnection.empty()
      ..userID = uid
      ..connectionCount = clientRegistry[uid].length;
    event.ClientConnectionState e = new event.ClientConnectionState(conn);

    return _sendToAll(e.toJson());
  }

  Future<shelf.Response> handleWsConnect(shelf.Request request) async {
    model.User user;
    try {
      user = await _authService.userOf(_tokenFrom(request));
    } catch (e, s) {
      _log.warning('Could not reach authentication server', e, s);
      return authServerDown();
    }

    shelf.Handler handleConnection = sWs.webSocketHandler((ws) {
      _register(ws, user.id);
    });

    return handleConnection(request);
  }

  /**
   * Send primitive. Expects the request body to be a _json string with a
   * list of recipients in the 'recipients' field.
   * The 'message' field is also mandatory for obvious reasons.
   */
  Future<shelf.Response> send(shelf.Request request) async {
    Map json;
    try {
      json = _json.decode(await request.readAsString());
    } catch (error, stackTrace) {
      _log.warning('Bad client request', error, stackTrace);
      return clientError('Malformed _json body');
    }

    Map message;
    if (!json.containsKey("message")) {
      return clientError("Malformed _json body");
    }
    message = json['message'];

    List<WebSocketChannel> channels = [];

    (json['recipients'] as Iterable).fold(channels, (list, int uid) {
      if (clientRegistry[uid] != null) {
        list.addAll(clientRegistry[uid]);
      }

      return list;
    }).toList()..shuffle();

    _log.finest('Sending $message to ${channels.length} websocket clients');

    channels.forEach((ws) {
      ws.sink.add(_json.encode(message));
    });

    return okJson({"status": "ok"});
  }

  /**
   *
   */
  shelf.Response connectionList(shelf.Request request) {
    Iterable<model.ClientConnection> connections =
        clientRegistry.keys.map((int uid) => new model.ClientConnection.empty()
          ..userID = uid
          ..connectionCount = clientRegistry[uid].length);

    return okJson(connections.toList(growable: false));
  }

  /**
   *
   */
  shelf.Response connection(shelf.Request request) {
    int uid = int.parse(shelf_route.getPathParameter(request, 'uid'));

    if (clientRegistry.containsKey(uid)) {
      model.ClientConnection conn = new model.ClientConnection.empty()
        ..userID = uid
        ..connectionCount = clientRegistry[uid].length;

      return okJson(conn);
    } else {
      return notFoundJson({'error': 'No connections for uid $uid'});
    }
  }

  /**
   * Extracts token from request.
   */
  String _tokenFrom(shelf.Request request) =>
      request.requestedUri.queryParameters['token'];
}
