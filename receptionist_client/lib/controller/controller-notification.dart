/*                  This file is part of OpenReception
                   Copyright (C) 2012-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orc.controller;

/**
 * Contains a bunch of notification streams for various events.
 */
class Notification {
  Bus<model.UserStatus> _agentStateChangeBus = new Bus<model.UserStatus>();
  Bus<or_event.CalendarChange> _calendarChangeBus =
      new Bus<or_event.CalendarChange>();
  Bus<or_event.CallEvent> _callStateChangeBus = new Bus<or_event.CallEvent>();
  Bus<or_event.ClientConnectionState> _clientConnectionStateBus =
      new Bus<or_event.ClientConnectionState>();
  final Logger _log = new Logger('$libraryName.Notification');
  Bus<or_event.PeerState> _peerStateChangeBus = new Bus<or_event.PeerState>();
  Bus<or_event.ReceptionChange> _receptionChangeBus =
      new Bus<or_event.ReceptionChange>();
  Bus<or_event.ContactChange> _contactChangeBus = new Bus<or_event.ContactChange>();
  Bus<or_event.ReceptionData> _receptionDataChangeBus =
      new Bus<or_event.ReceptionData>();

  final service.NotificationService _service;
  final service.NotificationSocket _socket;

  /**
   * Constructor.
   */
  Notification(service.NotificationSocket this._socket,
      service.NotificationService this._service) {
    _observers();
  }

  /**
   *
   */
  Future<Iterable<model.ClientConnection>> clientConnections() =>
      _service.clientConnections();

  /**
   * Handle the [OREvent.CalendarChange] [event].
   */
  void _calendarChange(or_event.CalendarChange event) {
    _calendarChangeBus.fire(event);
  }

  /**
   * Handle the [OREvent.CallEvent] [event].
   */
  void _callEvent(or_event.CallEvent event) {
    _callStateChangeBus.fire(event);
  }

  /**
   * Handle the [OREvent.ClientConnectionState] [event].
   */
  void _clientConnectionState(or_event.ClientConnectionState event) {
    _clientConnectionStateBus.fire(event);
  }

  /**
   * Fire [event] on relevant bus.
   */
  void _dispatch(or_event.Event e) {
    _log.finest(e.toJson());

    if (e is or_event.CallEvent) {
      _callEvent(e);
    } else if (e is or_event.CalendarChange) {
      _calendarChange(e);
    } else if (e is or_event.ClientConnectionState) {
      _clientConnectionState(e);
    } else if (e is or_event.MessageChange) {
      _messageChange(e);
    } else if (e is or_event.UserState) {
      _userState(e);
    } else if (e is or_event.PeerState) {
      _peerStateChangeBus.fire(e);
    } else if (e is or_event.ReceptionChange) {
      _receptionChangeBus.fire(e);
    } else if (e is or_event.ReceptionData) {
      _receptionDataChangeBus.fire(e);
    } else if (e is or_event.ContactChange) {
      _contactChangeBus.fire(e);
    } else {
      _log.severe('Failed to dispatch event $e');
    }
  }

  /**
   * Handle the [OREvent.MessageChange] [event].
   */
  void _messageChange(or_event.MessageChange event) {
    _log.info('Ignoring event $event');
  }

  /**
   * Agent state change stream.
   */
  Stream<model.UserStatus> get onAgentStateChange =>
      _agentStateChangeBus.stream;

  /**
   * Call state change stream.
   */
  Stream<or_event.CallEvent> get onAnyCallStateChange =>
      _callStateChangeBus.stream;

  /**
   * Calendar Event changes stream.
   */
  Stream<or_event.CalendarChange> get onCalendarChange =>
      _calendarChangeBus.stream;

  /**
   * Client connection state change stream.
   */
  Stream<or_event.ClientConnectionState> get onClientConnectionStateChange =>
      _clientConnectionStateBus.stream;

  /**
   * Agent state change stream.
   */
  Stream<or_event.PeerState> get onPeerStateChange => _peerStateChangeBus.stream;

  /**
   * Reception change stream.
   */
  Stream<or_event.ReceptionChange> get onReceptionChange =>
      _receptionChangeBus.stream;

  /**
   * Contact change stream.
   */
  Stream<or_event.ContactChange> get onContactChange => _contactChangeBus.stream;

  /**
   * ReceptionData change stream.
   */
  Stream<or_event.ReceptionData> get onReceptionDataChange =>
      _receptionDataChangeBus.stream;

  /**
   * Observers.
   */
  void _observers() {
    _socket.onEvent.listen(_dispatch, onDone: () => null);
  }

  /**
   * Handle the [OREvent.UserState] [event].
   */
  void _userState(or_event.UserState event) {
    _agentStateChangeBus.fire(new model.UserStatus.fromJson(event.toJson()));
  }

  /**
   *
   */
  Future notifySystem(or_event.Event e) => _service.send([0], e);
}
