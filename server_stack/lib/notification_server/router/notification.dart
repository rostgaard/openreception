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

part of openreception.notification_server.router;

abstract class Notification {
  static const String className = '$libraryName.Notification';
  static final Logger _log = new Logger(Notification.className);
  static List _stats = [];
  static int _sendCountBuffer = 0;

  static initStats() {
    new Timer.periodic(new Duration(seconds: 1), _tick);
  }

  static _tick(Timer t) {
    if (_stats.length > 60) {
      _stats.removeAt(0);
    }

    _stats.add(_sendCountBuffer);
    _sendCountBuffer = 0;
  }

  static shelf.Response statistics(shelf.Request request) {
    List retval = [];

    int i = 0;
    _stats.forEach((int num) {
      retval.add([i, num]);
      i++;
    });
    return new shelf.Response.ok(JSON.encode(retval));
  }

  /**
   * Broadcasts a message to every connected websocket.
   */
  static Future<shelf.Response> broadcast(shelf.Request request) async {
    try {
      Map contentMap = JSON.decode(await request.readAsString());

      return okJson(_sendToAll(contentMap));
    } catch (error, stackTrace) {
      _log.warning('Bad client request', error, stackTrace);
      return clientError('Malformed JSON body');
    }
  }

  /**
   *
   */
  static Map _sendToAll(Map content) {
    int success = 0;
    int failure = 0;

    List<WebSocketChannel> recipientSockets = clientRegistry.values.fold(
        new List<WebSocketChannel>(),
        (combined, websockets) => combined..addAll(websockets));

    recipientSockets.shuffle();

    recipientSockets.forEach(((WebSocketChannel ws) {
      try {
        String contentString = JSON.encode(content);

        ws.sink.add(contentString);
        _sendCountBuffer += contentString.codeUnits.length;
        success++;
        return true;
      } catch (error, stackTrace) {
        failure++;
        _log.severe("Failed to send message to client");
        _log.severe(error, stackTrace);
        return false;
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
  static Map _register(WebSocketChannel webSocket, int uid) {
    _log.info('New WebSocket connection from uid $uid');

    /// Make sure that there is a list to insert into.
    if (clientRegistry[uid] == null) {
      clientRegistry[uid] = new List<WebSocketChannel>();
    }
    clientRegistry[uid].add(webSocket);

    /// Listen for incoming data. We expect the data to be a JSON-encoded String.
    webSocket.stream.map((string) {
      try {
        return JSON.decode(string);
      } catch (error) {
        return {"status": "Malformed content - expected JSON string."};
      }
    }).listen((json) {
      _log.warning(
          'Client $uid tried to send us a message. This is not supported, echoing back.');
      webSocket.sink.add(JSON.encode(json)); // Echo.
    }, onError: (error, stackTrace) {
      _log.severe('Client $uid sent us a very malformed message. $error : ',
          stackTrace);
      clientRegistry[uid].remove(webSocket);
      webSocket.sink.close(io.WebSocketStatus.UNSUPPORTED_DATA, "Bad request");
    }, onDone: () {
      _log.info(
          'Disconnected WebSocket connection from uid $uid', "handleWebsocket");
      clientRegistry[uid].remove(webSocket);

      Model.ClientConnection conn = new Model.ClientConnection.empty()
        ..userID = uid
        ..connectionCount = clientRegistry[uid].length;
      Event.ClientConnectionState event = new Event.ClientConnectionState(conn);

      _sendToAll(event.toJson());
    });

    Model.ClientConnection conn = new Model.ClientConnection.empty()
      ..userID = uid
      ..connectionCount = clientRegistry[uid].length;
    Event.ClientConnectionState event = new Event.ClientConnectionState(conn);

    return _sendToAll(event.toJson());
  }

  static Future<shelf.Response> _handleWsConnect(shelf.Request request) async {
    Model.User user;
    try {
      user = await _authService.userOf(_tokenFrom(request));
    } catch (e, s) {
      _log.warning('Could not reach authentication server', e, s);
      return authServerDown();
    }

    shelf.Handler handleConnection = sWs.webSocketHandler((ws) {
      Notification._register(ws, user.id);
    });

    return handleConnection(request);
  }

  /**
   * Send primitive. Expects the request body to be a JSON string with a
   * list of recipients in the 'recipients' field.
   * The 'message' field is also mandatory for obvious reasons.
   */
  static Future<shelf.Response> send(shelf.Request request) async {
    Map json;
    try {
      json = JSON.decode(await request.readAsString());
    } catch (error, stackTrace) {
      _log.warning('Bad client request', error, stackTrace);
      return clientError('Malformed JSON body');
    }

    Map message;
    if (!json.containsKey("message")) {
      return clientError("Malformed JSON body");
    }
    message = json['message'];

    List<WebSocketChannel> channels =
        (json['recipients'] as Iterable).fold([], (list, int uid) {
      if (clientRegistry[uid] != null) {
        list.addAll(clientRegistry[uid]);
      }

      return list;
    }).toList()..shuffle();

    _log.finest('Sending $message to ${channels.length} websocket clients');

    channels.forEach((ws) {
      ws.sink.add(JSON.encode(message));
      _log.finest('Sending $message to ${ws}');
    });

    return okJson({"status": "ok"});
  }

  /**
   *
   */
  static shelf.Response connectionList(shelf.Request request) {
    Iterable<Model.ClientConnection> connections =
        clientRegistry.keys.map((int uid) => new Model.ClientConnection.empty()
          ..userID = uid
          ..connectionCount = clientRegistry[uid].length);

    return okJson(connections.toList(growable: false));
  }

  /**
   *
   */
  static shelf.Response connection(shelf.Request request) {
    int uid = int.parse(shelf_route.getPathParameter(request, 'uid'));

    if (clientRegistry.containsKey(uid)) {
      Model.ClientConnection conn = new Model.ClientConnection.empty()
        ..userID = uid
        ..connectionCount = clientRegistry[uid].length;

      return okJson(conn);
    } else {
      return notFoundJson({'error': 'No connections for uid $uid'});
    }
  }
}
