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

part of orf.model;

/// Enumeration type for call states.
abstract class CallState {
  static const String unknown = 'UNKNOWN';
  static const String created = 'CREATED';
  static const String ringing = 'RINGING';
  static const String queued = 'QUEUED';
  static const String unparked = 'UNPARKED';
  static const String hungup = 'HUNGUP';
  static const String transferring = 'TRANSFERRING';
  static const String transferred = 'TRANSFERRED';
  static const String speaking = 'SPEAKING';
  static const String parked = 'PARKED';
}

/// Class representing a call in the system.
///
/// Every call is identified by a unique id (uuid) that may be used as a
/// handle for REST service method calls.
class Call {
  static const String className = '$_libraryName.Call';
  static final Logger _log = new Logger(Call.className);

  static final Call noCall = new Call.empty(noId);
  static final String noId = '';

  final Bus<String> _callState = new Bus<String>();
  final Bus<_event.CallEvent> _eventBus = new Bus<_event.CallEvent>();

  DateTime arrived = new DateTime.now();
  DateTime answeredAt = util.never;
  int assignedTo = User.noId;
  String bLeg;
  String callerId = '';
  int cid = BaseContact.noId;
  String destination = '';
  bool greetingPlayed = false;
  String _id = noId;
  bool inbound;
  bool _locked = false;
  int rid = Reception.noId;
  String _state = CallState.unknown;
  String hangupCause = '';

  /// Default empty constructor.
  Call.empty(this._id);

  /// Default constructor.
  factory Call.fromMap(Map<String, dynamic> map) => new Call.empty(map[key.id])
    .._state = map[PbxKey.state]
    ..answeredAt = util.unixTimestampToDateTime(map[key.answeredAt])
    ..bLeg = map[key.bLeg]
    .._locked = map[key.locked]
    ..inbound = map[key.inbound]
    ..destination = map[key.destination]
    ..callerId = map[key.callerId]
    ..greetingPlayed = map[key.greetingPlayed]
    ..rid = map[ORPbxKey.receptionId]
    ..cid = map[ORPbxKey.contactId]
    ..assignedTo = map[key.assignedTo]
    ..arrived = util.unixTimestampToDateTime(map[key.arrivalTime]);

  /// A call is identical to another call if their id's match.
  @override
  bool operator ==(Object other) => other is Call && _id == other._id;

  /// Assign a call to a user.
  ///
  /// Effectively sets [assignedTo] to the ID of the [user].
  void assignTo(User user) {
    assignedTo = user.id;
  }

  /// Stream of call-state changes.
  Stream<String> get callState => _callState.stream;

  /// Change the state of the [Call] object to [newState].
  void changeState(String newState) {
    final String lastState = _state;

    _state = newState;

    _log.finest('UUID: $_id: $lastState => $newState');

    if (lastState == CallState.queued) {
      notifyEvent(new _event.QueueLeave(this));
    } else if (lastState == CallState.parked) {
      notifyEvent(new _event.CallUnpark(this));
    }

    switch (newState) {
      case (CallState.created):
        notifyEvent(new _event.CallOffer(this));
        break;

      case (CallState.parked):
        notifyEvent(new _event.CallPark(this));
        break;

      case (CallState.unparked):
        notifyEvent(new _event.CallUnpark(this));
        break;

      case (CallState.queued):
        notifyEvent(new _event.QueueJoin(this));
        break;

      case (CallState.hungup):
        notifyEvent(new _event.CallHangup(this, hangupCause: hangupCause));
        break;

      case (CallState.speaking):
        notifyEvent(new _event.CallPickup(this));
        break;

      case (CallState.transferred):
        notifyEvent(new _event.CallTransfer(this));
        break;

      case (CallState.ringing):
        notifyEvent(new _event.CallStateChanged(this));
        break;

      case (CallState.transferring):
        break;

      default:
        _log.severe('Changing call ${this} to Unkown state!');
        break;
    }
  }

  /// The channel ID of the call.
  ///
  /// Note: The channel is a unique identifier so remember to change it,
  /// if ID changes.
  String get channel => _id;

  /// The Unique identification of the call
  String get id => _id;

  /// The current state of the call.
  String get state => _state;

  /// Explicitly change the state of the call without sending
  /// [_event.CallEvent]s
  set state(String newState) {
    _state = newState;
    _callState.fire(newState);
  }

  Stream<_event.CallEvent> get event => _eventBus.stream;

  /// Hashcode follows convention from [==].
  @override
  int get hashCode => _id.hashCode;

  /// Convenicence function to determine if the [Call] is no a [noCall]
  /// object.
  bool get isActive => this != noCall;

  /// Link (bridge) thwo calls.
  void link(Call other) {
    if (locked) locked = false;

    bLeg = other._id;
    other.bLeg = _id;
  }

  /// Determines if the call is currently locked for pickup.
  bool get locked => _locked;

  /// Update the lock status of the [Call].
  set locked(bool lock) {
    _locked = lock;

    if (lock) {
      notifyEvent(new _event.CallLock((this)));
    } else {
      notifyEvent(new _event.CallUnlock(this));
    }
  }

  void notifyEvent(_event.Event e) => _eventBus.fire(e);

  /// Unassign a call from a user.
  void release() {
    assignedTo = User.noId;
  }

  /// String version of [Call] for debug/log purposes.
  @override
  String toString() => this == noCall
      ? 'no Call'
      : 'CallId: $_id, state: $_state, destination: $destination';

  /// Serilization function.
  Map<String, dynamic> toJson() => <String, dynamic>{
        key.id: _id,
        PbxKey.state: _state,
        key.bLeg: bLeg,
        key.locked: locked,
        key.inbound: inbound,
        key.destination: destination,
        key.callerId: callerId,
        key.greetingPlayed: greetingPlayed,
        ORPbxKey.receptionId: rid,
        ORPbxKey.contactId: cid,
        key.assignedTo: assignedTo,
        key.channel: channel,
        key.arrivalTime: util.dateTimeToUnixTimestamp(arrived),
        key.answeredAt: util.dateTimeToUnixTimestamp(answeredAt)
      };
}
