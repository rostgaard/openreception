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

///
/// Event model classes and utilities.
///
/// The events are an integrated part of the core of OpenReception. Every
/// time a change happens, either in a persistent or transient object, an
/// event is sent to every subsystem that needs to respond to this change.
///
/// Example of a subsystems in this context are clients that need to update
/// their UI, based on call-state changes. It may also be a server-side
/// cache/prefetching service that responds to a change in a persistent
/// datastore (for example, a deletion) and updates its locals
/// views/caches accordingly.
library orf.event;

import 'package:logging/logging.dart';
import 'package:orf/model.dart' as model;
import 'package:orf/util.dart' as util;

part 'event/call/event-call.dart';
part 'event/call/event-call_assign.dart';
part 'event/call/event-call_hangup.dart';
part 'event/call/event-call_lock.dart';
part 'event/call/event-call_offer.dart';
part 'event/call/event-call_park.dart';
part 'event/call/event-call_pickup.dart';
part 'event/call/event-call_queue_enter.dart';
part 'event/call/event-call_queue_leave.dart';
part 'event/call/event-call_state_reload.dart';
part 'event/call/event-call_statechange.dart';
part 'event/call/event-call_transfer.dart';
part 'event/call/event-call_unassign.dart';
part 'event/call/event-call_unlock.dart';
part 'event/call/event-call_unpark.dart';
part 'event/event-calendar.dart';
part 'event/event-channel.dart';
part 'event/event-client_connection.dart';
part 'event/event-contact.dart';
part 'event/event-dialplan.dart';
part 'event/event-focus_change.dart';
part 'event/event-ivr_menu.dart';
part 'event/event-message.dart';
part 'event/event-organization.dart';
part 'event/event-peer_state.dart';
part 'event/event-reception.dart';
part 'event/event-reception_contact.dart';
part 'event/event-user.dart';
part 'event/event-user_state.dart';
part 'event/event-widget_select.dart';

///'Enum' representing different outcomes of an change.
abstract class Change {
  /// Object is created.
  static const String created = 'created';

  /// Object is updated.
  static const String updated = 'updated';

  /// Object is deleted.
  static const String deleted = 'deleted';
}

/// Keys for the serialization and deserialization.
abstract class _Key {
  static const String _id = 'id';
  static const String _uid = 'uid';
  static const String _cid = 'cid';
  static const String _mid = 'mid';
  static const String _oid = 'oid';
  static const String _rid = 'rid';
  static const String _eid = 'eid';
  static const String _modifierUid = 'modifier';

  static const String _dialplanChange = 'dialplanChange';
  static const String _ivrMenuChange = 'ivrMenuChange';
  static const String _calendarChange = 'calendarChange';
  static const String _messageChange = 'messageChange';
  static const String _contactChange = 'contactChange';
  static const String _receptionData = 'receptionData';
  static const String _receptionChange = 'receptionChange';
  static const String _userChange = 'userChange';
  static const String _organizationChange = 'organizationChange';
  static const String _connectionState = 'connectionState';
  static const String _widgetSelect = 'widgetSelect';
  static const String _focusChange = 'focusChange';
  static const String _messageState = 'messageState';

  static const String _extension = 'extension';
  static const String _menuName = 'menuName';
  static const String _createdAt = 'createdAt';
  static const String _call = 'call';
  static const String _peer = 'peer';
  static const String _channel = 'channel';
  static const String _event = 'event';
  static const String _hangupCause = 'hangupCause';
  static const String _widget = 'widget';
  static const String _inFocus = 'inFocus';
  static const String _owner = 'owner';
  static const String _timestamp = 'timestamp';
  static const String _changedBy = 'changedBy';
  static const String _paused = 'paused';

  static const String _callAssign = 'call_assign';
  static const String _callUnassign = 'call_unassign';
  static const String _callOffer = 'call_offer';
  static const String _callLock = 'call_lock';
  static const String _callUnlock = 'call_unlock';
  static const String _callPickup = 'call_pickup';
  static const String _callState = 'call_state';
  static const String _callHangup = 'call_hangup';
  static const String _callPark = 'call_park';
  static const String _callUnpark = 'call_unpark';
  static const String _callTransfer = 'call_transfer';
  static const String _queueJoin = 'queue_join';
  static const String _queueLeave = 'queue_leave';
  static const String _peerState = 'peer_state';
  static const String _channelState = 'channel_state';
  static const String _userState = 'userState';
  static const String _state = 'state';
  static const String _callStateReload = 'callStateReload';
}

/// Superclass for events. It's only real purpose is to provide a common interface
/// for [Event] objects, and a parsing factory constructor.
abstract class Event {
  /// Parse an an event that has already been deserialized from JSON string.
  ///
  /// Throws a [FormatException] if the map is not a valid event.
  factory Event.parse(Map<String, dynamic> map) {
    final String eventName = map[_Key._event] as String;
    try {
      switch (eventName) {
        case _Key._widgetSelect:
          return WidgetSelect.fromJson(map);

        case _Key._focusChange:
          return FocusChange.fromJson(map);

        case _Key._peerState:
          return PeerState.fromJson(map);

        case _Key._queueJoin:
          return QueueJoin.fromJson(map);

        case _Key._queueLeave:
          return QueueLeave.fromJson(map);

        case _Key._callLock:
          return CallLock.fromJson(map);

        case _Key._callUnlock:
          return CallUnlock.fromJson(map);

        case _Key._callOffer:
          return CallOffer.fromJson(map);

        case _Key._callTransfer:
          return CallTransfer.fromJson(map);

        case _Key._callUnpark:
          return CallUnpark.fromJson(map);

        case _Key._callPark:
          return CallPark.fromJson(map);

        case _Key._callHangup:
          return CallHangup.fromJson(map);

        case _Key._callState:
          return CallStateChanged.fromJson(map);

        case _Key._callPickup:
          return CallPickup.fromJson(map);

        case _Key._channelState:
          return ChannelState.fromJson(map);

        case _Key._userState:
          return UserState.fromJson(map);

        case _Key._calendarChange:
          return CalendarChange.fromJson(map);

        case _Key._contactChange:
          return ContactChange.fromJson(map);

        case _Key._organizationChange:
          return OrganizationChange.fromJson(map);

        case _Key._receptionChange:
          return ReceptionChange.fromJson(map);

        case _Key._receptionData:
          return ReceptionData.fromJson(map);

        case _Key._connectionState:
          return ClientConnectionState.fromJson(map);

        case _Key._messageChange:
          return MessageChange.fromJson(map);

        case _Key._userChange:
          return UserChange.fromJson(map);

        case _Key._callStateReload:
          return CallStateReload.fromJson(map);

        case _Key._dialplanChange:
          return DialplanChange.fromJson(map);

        case _Key._ivrMenuChange:
          return IvrMenuChange.fromJson(map);

        default:
          throw FormatException('Unsupported event type: $eventName');
      }
    } catch (error, stackTrace) {
      _log.severe('Failed to parse map as event. Map: $map');
      _log.severe(error, stackTrace);

      throw FormatException('Failed to cast map as event.');
    }
  }

  static final Logger _log = Logger('orf.event.Event');

  /// The creation time of the event.
  DateTime get timestamp;

  /// The name of the event. Identifies the type of the object in the
  /// serialization/deserialization.
  String get eventName;

  /// Every specialized class needs a toJson function.
  Map<String, dynamic> toJson();
}
