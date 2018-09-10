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

class _NotificationRequest {
  final Map<String, dynamic> body;
  final Uri resource;
  final Completer<String> response = new Completer<String>();

  _NotificationRequest(Uri this.resource, Map<String, dynamic> this.body);
}

/// Client for Notification sending.
class NotificationService {
  static Queue<_NotificationRequest> _requestQueue =
      new Queue<_NotificationRequest>();
  static bool _busy = false;

  final WebService _httpClient;
  final Uri host;
  final String _clientToken;

  NotificationService(
      Uri this.host, String this._clientToken, this._httpClient);

  /// Performs a broadcast via the notification server.
  Future<String> broadcastEvent(event.Event event) {
    Uri uri = resource.Notification.broadcast(host);
    uri = _appendToken(uri, _clientToken);

    return _enqueue(new _NotificationRequest(uri, event.toJson()));
  }

  /// Retrieves the [ClientConnection]'s currently active on the server.
  Future<Iterable<model.ClientConnection>> clientConnections() async {
    Uri uri = resource.Notification.clientConnections(host);
    uri = _appendToken(uri, _clientToken);

    return await _httpClient.get(uri).then(_json.decode).then(
        (Iterable<Map<String, dynamic>> maps) => maps.map(
            (Map<String, dynamic> map) =>
                new model.ClientConnection.fromJson(map)));
  }

  /// Retrieves the [ClientConnection] currently associated with [uid].
  Future<model.ClientConnection> clientConnection(int uid) {
    Uri uri = resource.Notification.clientConnection(host, uid);
    uri = _appendToken(uri, _clientToken);

    return _httpClient.get(uri).then(_json.decode).then(
        (Map<String, dynamic> map) => new model.ClientConnection.fromJson(map));
  }

  /// Sends an event via the notification server to [recipients]
  Future<Null> send(Iterable<int> recipients, event.Event event) async {
    Uri uri = resource.Notification.send(host);
    uri = _appendToken(uri, _clientToken);

    final Map<String, dynamic> payload = <String, dynamic>{
      'recipients': recipients.toList(),
      'message': event.toJson()
    };

    await _httpClient.post(uri, _json.encode(payload));
  }

  /// Every request sent to the phone is enqueued and executed in-order
  /// without the possibility to pipeline requests.
  ///
  /// This is done to enforce strict ordering of notifications, so that
  /// they are received in-order.
  Future<String> _enqueue(_NotificationRequest request) {
    if (!_busy) {
      _busy = true;
      return _performRequest(request);
    } else {
      _requestQueue.add(request);
      return request.response.future;
    }
  }

  /// Performs the actual backend post operation.
  Future<String> _performRequest(_NotificationRequest request) async {
    void dispatchNext() {
      if (_requestQueue.isNotEmpty) {
        _NotificationRequest currentRequest = _requestQueue.removeFirst();

        _performRequest(currentRequest)
            .then((_) => currentRequest.response.complete())
            .catchError(currentRequest.response.completeError);
      } else {
        _busy = false;
      }
    }

    return await _httpClient
        .post(request.resource, _json.encode(request.body))
        .whenComplete(dispatchNext);
  }

  /// Factory shortcut for opening a [NotificationSocket] client connection.
  static Future<NotificationSocket> socket(
      WebSocket notificationBackend, Uri host, String serverToken) {
    return notificationBackend
        .connect(_appendToken(
            resource.Notification.notifications(host), serverToken))
        .then((WebSocket ws) => new NotificationSocket(ws));
  }
}

/// Notification listener socket client.
class NotificationSocket {
  final WebSocket _websocket;

  // Chuck-o'-busses.
  Bus<event.Event> _eventBus = new Bus<event.Event>();
  Bus<event.CallEvent> _callEventBus = new Bus<event.CallEvent>();
  Bus<event.CalendarChange> _calenderChangeBus =
      new Bus<event.CalendarChange>();
  Bus<event.ClientConnectionState> _clientConnectionBus =
      new Bus<event.ClientConnectionState>();
  Bus<event.ContactChange> _contactChangeBus = new Bus<event.ContactChange>();
  Bus<event.ReceptionData> _receptionDataChangeBus =
      new Bus<event.ReceptionData>();
  Bus<event.ReceptionChange> _receptionChangeBus =
      new Bus<event.ReceptionChange>();
  Bus<event.MessageChange> _messageChangeBus = new Bus<event.MessageChange>();
  Bus<event.OrganizationChange> _organizationChangeBus =
      new Bus<event.OrganizationChange>();
  Bus<event.DialplanChange> _dialplanChangeBus =
      new Bus<event.DialplanChange>();
  Bus<event.IvrMenuChange> _ivrMenuChangeBus = new Bus<event.IvrMenuChange>();
  Bus<event.PeerState> _peerStateBus = new Bus<event.PeerState>();
  Bus<event.UserChange> _userChangeBus = new Bus<event.UserChange>();
  Bus<event.UserState> _userStateBus = new Bus<event.UserState>();
  Bus<event.WidgetSelect> _widgetSelectBus = new Bus<event.WidgetSelect>();
  Bus<event.FocusChange> _focusChangeBus = new Bus<event.FocusChange>();

  /// Creates a new [NotificationSocket]. The [_websocket] parameter object needs
  /// to be connected manually. Otherwise, the notification socket will remain
  /// silent.
  NotificationSocket(WebSocket this._websocket) {
    _websocket.onMessage = _parseAndDispatch;

    _websocket.onClose = () async {
      // Discard any inbound messages instead of injecting them into a
      // potentially closed stream.
      _websocket.onMessage = (_) {};

      await _closeEventListeners();
    };

    onEvent.listen(_injectInLocalSteams);
  }

  /// Global event stream. Receive all events broadcast or sent to uid of
  /// subscriber.
  Stream<event.Event> get onEvent => _eventBus.stream;
  @deprecated
  Stream<event.Event> get eventStream => onEvent;

  /// Filtered stream that only emits [event.CallEvent] objects.
  Stream<event.CallEvent> get onCallEvent => _callEventBus.stream;

  /// Filtered stream that only emits [event.MessageChange] objects.
  Stream<event.MessageChange> get onMessageChange => _messageChangeBus.stream;

  /// Filtered stream that only emits [event.CalendarChange] objects.
  Stream<event.CalendarChange> get onCalendarChange =>
      _calenderChangeBus.stream;

  /// Filtered stream that only emits [event.ClientConnectionState] objects.
  Stream<event.ClientConnectionState> get onClientConnectionChange =>
      _clientConnectionBus.stream;

  /// Filtered stream that only emits [event.ContactChange] objects.
  Stream<event.ContactChange> get onContactChange => _contactChangeBus.stream;

  /// Filtered stream that only emits [event.ReceptionData] objects.
  Stream<event.ReceptionData> get onReceptionDataChange =>
      _receptionDataChangeBus.stream;

  /// Filtered stream that only emits [event.ReceptionChange] objects.
  Stream<event.ReceptionChange> get onReceptionChange =>
      _receptionChangeBus.stream;

  /// Filtered stream that only emits [event.OrganizationChange] objects.
  Stream<event.OrganizationChange> get onOrganizationChange =>
      _organizationChangeBus.stream;

  /// Filtered stream that only emits [event.DialplanChange] objects.
  Stream<event.DialplanChange> get onDialplanChange =>
      _dialplanChangeBus.stream;

  /// Filtered stream that only emits [event.IvrMenuChange] objects.
  Stream<event.IvrMenuChange> get onIvrMenuChange => _ivrMenuChangeBus.stream;

  /// Filtered stream that only emits [event.PeerState] objects.
  Stream<event.PeerState> get onPeerState => _peerStateBus.stream;

  /// Filtered stream that only emits [event.UserChange] objects.
  Stream<event.UserChange> get onUserChange => _userChangeBus.stream;

  /// Filtered stream that only emits [event.UserState] objects.
  Stream<event.UserState> get onUserState => _userStateBus.stream;

  /// Filtered stream that only emits [event.WidgetSelect] objects.
  Stream<event.WidgetSelect> get onWidgetSelect => _widgetSelectBus.stream;

  /// Filtered stream that only emits [event.FocusChange] objects.
  Stream<event.FocusChange> get onFocusChange => _focusChangeBus.stream;

  /// Further decode [event.Event] objects and put into their respective
  /// stream.
  void _injectInLocalSteams(event.Event e) {
    if (e is event.CallEvent) {
      _callEventBus.fire(e);
    } else if (e is event.MessageChange) {
      _messageChangeBus.fire(e);
    } else if (e is event.CalendarChange) {
      _calenderChangeBus.fire(e);
    } else if (e is event.ClientConnectionState) {
      _clientConnectionBus.fire(e);
    } else if (e is event.ContactChange) {
      _contactChangeBus.fire(e);
    } else if (e is event.ReceptionData) {
      _receptionDataChangeBus.fire(e);
    } else if (e is event.ReceptionChange) {
      _receptionChangeBus.fire(e);
    } else if (e is event.OrganizationChange) {
      _organizationChangeBus.fire(e);
    } else if (e is event.DialplanChange) {
      _dialplanChangeBus.fire(e);
    } else if (e is event.IvrMenuChange) {
      _ivrMenuChangeBus.fire(e);
    } else if (e is event.PeerState) {
      _peerStateBus.fire(e);
    } else if (e is event.UserChange) {
      _userChangeBus.fire(e);
    } else if (e is event.UserState) {
      _userStateBus.fire(e);
    } else if (e is event.WidgetSelect) {
      _widgetSelectBus.fire(e);
    } else if (e is event.FocusChange) {
      _focusChangeBus.fire(e);
    }
  }

  /// Finalize object and close all subscriptions.
  Future<Null> _closeEventListeners() async {
    await _eventBus.close();

    await Future.wait(<Future<Null>>[
      _callEventBus.close(),
      _calenderChangeBus.close(),
      _clientConnectionBus.close(),
      _contactChangeBus.close(),
      _receptionDataChangeBus.close(),
      _receptionChangeBus.close(),
      _messageChangeBus.close(),
      _organizationChangeBus.close(),
      _dialplanChangeBus.close(),
      _ivrMenuChangeBus.close(),
      _peerStateBus.close(),
      _userChangeBus.close(),
      _userStateBus.close(),
      _widgetSelectBus.close(),
      _focusChangeBus.close()
    ]);
  }

  /// Closes the websocket and all open streams.
  Future<Null> close() async {
    await _websocket.close();
  }

  /// Parses, decodes and dispatches a received String buffer containg an
  /// encoded event object.
  void _parseAndDispatch(String buffer) {
    Map<String, dynamic> map = _json.decode(buffer) as Map<String, dynamic>;
    event.Event newEvent = new event.Event.parse(map);

    if (newEvent != null) {
      _eventBus.fire(newEvent);
    } else {
      // Discard null objects.
    }
  }
}
