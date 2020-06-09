/*                  This file is part of OpenReception
                   Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.model.monitoring;

/// Model class for a call that is currently in progress (not yet hung up).
class ActiveCall {

  /// Default empty constructor.
  ActiveCall.empty();

  final List<_event.CallEvent> _events = <_event.CallEvent>[];

  /// Reception id of the call.
  int get rid => _events
      .firstWhere((_event.CallEvent ce) => ce.call.orRid != noId,
          orElse: () => _event.CallOffer(Call()))
      .call
      .orRid;

  /// Contact id of the call.
  int get cid => _events
      .firstWhere((_event.CallEvent ce) => ce.call.orCid != noId,
          orElse: () => _event.CallOffer(Call()))
      .call
      .orCid;

  /// Call id of the call.
  String get callId => _events.isNotEmpty ? _events.first.call.id : "<empty>";

  /// Add an event to the internal list of historic [_event.CallEvent]s
  /// that occurred with relevance to the [ActiveCall].
  void addEvent(_event.CallEvent e) {
    _events.add(e);
    _events.sort((_event.CallEvent e1, _event.CallEvent e2) =>
        e1.timestamp.compareTo(e2.timestamp));
  }

  /// Retrieve the uid of the agent that call was assigned to.
  ///
  /// If the call was never assigned, returns [model.User.noId].
  int get assignee => _events
      .firstWhere((_event.CallEvent ce) => ce.call.assignedTo != noId,
          orElse: () => _events.first)
      .call
      .assignedTo;

  /// Returns true if the call has not been assigned to an agent.
  bool get unAssigned => assignee == noId;

  /// Returns a log-friendly string visualizing the current event stack.
  String eventString() =>
      '  events:\n' +
      _events.map((_event.Event e) => '  - ${_eventToString(e)}').join('\n');

  /// Convert an event to a string.
  String _eventToString(_event.Event e) =>
      '${e.timestamp.millisecondsSinceEpoch~/1000}: ${e.eventName}';

  @override
  String toString() => 'done:$isDone\n'
      'owner: $assignee\n'
      'isAnswered:$isAnswered${isAnswered && inbound ? ' (latency:${answerLatency.inMilliseconds}ms)' : ''}\n'
      'inbound:$inbound\n'
      '${eventString()}';

  /// Determines if the call is inbound.
  bool get inbound => _events.first.call.inbound;

  /// Determines if the call has been answered.
  bool get isAnswered =>
      _events.any((_event.CallEvent ce) => ce is _event.CallPickup);

  /// Returns the timestamp of the first (in time) event that has occurred.
  DateTime get firstEventTime => _events.first.timestamp;

  /// Returns true if that call is no longer active.
  bool get isDone => _events.any((_event.CallEvent ce) =>
      ce is _event.CallHangup || ce is _event.CallTransfer);

  @override
  int get hashCode => callId.hashCode;

  @override
  bool operator ==(Object other) =>
      other is ActiveCall && other.callId == callId;

  /// The [Duration] a call has been progressing before it was picked up.
  Duration get answerLatency {
    if (!inbound) {
      return null;
    }

    _event.CallOffer offerEvent;
    _event.CallPickup pickupEvent;
    try {
      offerEvent =
          _events.firstWhere((_event.CallEvent ce) => ce is _event.CallOffer) as _event.CallOffer;

      pickupEvent =
          _events.firstWhere((_event.CallEvent ce) => ce is _event.CallPickup) as _event.CallPickup;
    } on StateError {
      return Duration(seconds: 2);
    }

    return pickupEvent.timestamp.difference(offerEvent.timestamp);
  }
}
