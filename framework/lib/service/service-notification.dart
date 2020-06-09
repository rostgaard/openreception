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

/// Client for Notification sending.
class NotificationService {
  NotificationService(
      Uri this.host, String this._clientToken, WebService oldClient)
      : _client =
            api.NotificationApi(api.ApiClient(basePath: host.toString())) {
    _client.apiClient.getAuthentication<api.ApiKeyAuth>('ApiKeyAuth').apiKey =
        _clientToken;
  }

  final api.NotificationApi _client;

  final Uri host;
  final String _clientToken;

  /// Performs a broadcast via the notification server.
  Future<api.NotificationSendResponse> broadcastEvent(event.Event event) async {
    try {
      return await _client.broadcast(event.toJson());
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Retrieves the [model.ClientConnection]'s currently active on the server.
  Future<List<api.ClientConnection>> clientConnections() async {
    try {
      return (await _client.allConnections());
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Retrieves the [api.ClientConnection] currently associated with [uid].
  Future<api.ClientConnection> clientConnection(int uid) async {
    try {
      return model.ClientConnection.fromJson(
          (await _client.connectionsByUser(uid)).toJson());
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Sends an event via the notification server to [recipients]
  Future<api.NotificationSendResponse> send(
      Iterable<int> recipients, event.Event event) async {
    try {
      return await _client.send(api.NotificationSendRequest()
        ..recipients = recipients.toList()
        ..message = api.NotificationSendPayload.fromJson(event.toJson()));
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Factory shortcut for opening a [NotificationSocket] client connection.
  static Future<NotificationSocket> socket(
      WebSocket notificationBackend, Uri host, String serverToken) {
    return notificationBackend
        .connect(Uri.parse(host.toString() + '/notifications?token='+ serverToken))
        .then((WebSocket ws) => NotificationSocket(ws));
  }
}

/// Notification listener socket client.
class NotificationSocket {
  /// Creates a [NotificationSocket]. The [_websocket] parameter object needs
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

  final WebSocket _websocket;

  // Chuck-o'-busses.
  Bus<event.Event> _eventBus = Bus<event.Event>();
  Bus<event.CallEvent> _callEventBus = Bus<event.CallEvent>();
  Bus<event.CalendarChange> _calenderChangeBus = Bus<event.CalendarChange>();
  Bus<event.ClientConnectionState> _clientConnectionBus =
      Bus<event.ClientConnectionState>();
  Bus<event.ContactChange> _contactChangeBus = Bus<event.ContactChange>();
  Bus<event.ReceptionData> _receptionDataChangeBus = Bus<event.ReceptionData>();
  Bus<event.ReceptionChange> _receptionChangeBus = Bus<event.ReceptionChange>();
  Bus<event.MessageChange> _messageChangeBus = Bus<event.MessageChange>();
  Bus<event.OrganizationChange> _organizationChangeBus =
      Bus<event.OrganizationChange>();
  Bus<event.DialplanChange> _dialplanChangeBus = Bus<event.DialplanChange>();
  Bus<event.IvrMenuChange> _ivrMenuChangeBus = Bus<event.IvrMenuChange>();
  Bus<event.PeerState> _peerStateBus = Bus<event.PeerState>();
  Bus<event.UserChange> _userChangeBus = Bus<event.UserChange>();
  Bus<event.UserState> _userStateBus = Bus<event.UserState>();
  Bus<event.WidgetSelect> _widgetSelectBus = Bus<event.WidgetSelect>();
  Bus<event.FocusChange> _focusChangeBus = Bus<event.FocusChange>();

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
    event.Event newEvent = event.Event.parse(map);

    if (newEvent != null) {
      _eventBus.fire(newEvent);
    } else {
      // Discard null objects.
    }
  }
}
