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

class _HistoricCallEvent {
  final DateTime timestamp;
  final String eventName;

  const _HistoricCallEvent(this.timestamp, this.eventName);

  factory _HistoricCallEvent.fromJson(Map<String, dynamic> map) =>
      new _HistoricCallEvent(DateTime.parse(map['t']), map['e']);

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'t': timestamp.toString(), 'e': eventName};
}

class HistoricCall {
  final String callId;
  final int uid;
  final int rid;
  final int cid;
  final bool inbound;
  final List<_HistoricCallEvent> events = <_HistoricCallEvent>[];
  final Logger _log = new Logger('orf.model.monitoring.HistoricCall');

  HistoricCall.fromActiveCall(ActiveCall ac)
      : callId = ac.callId,
        uid = ac.assignee,
        rid = ac.rid,
        cid = ac.cid,
        inbound = ac.inbound {
    _HistoricCallEvent simplifyEvent(_event.CallEvent ce) =>
        new _HistoricCallEvent(ce.timestamp, ce.eventName);

    events.addAll(ac._events.map(simplifyEvent));
  }

  HistoricCall.fromJson(Map<String, dynamic> map)
      : callId = map['id'],
        uid = map['uid'],
        rid = map['rid'],
        cid = map['cid'],
        inbound = map['in'] {
    events.addAll((map['es'] as Iterable<Map<String, dynamic>>).map(
        (Map<String, dynamic> map) => new _HistoricCallEvent.fromJson(map)));
  }

  bool get unAssigned => uid == noId;

  Duration get answerLatency {
    if (!inbound) {
      return null;
    }

    _HistoricCallEvent offerEvent;
    _HistoricCallEvent pickupEvent;
    try {
      offerEvent = events
          .firstWhere((_HistoricCallEvent e) => e.eventName == _callOfferKey);

      pickupEvent = events
          .firstWhere((_HistoricCallEvent e) => e.eventName == _callPickupKey);
    } on StateError {
      return new Duration(seconds: 2);
    }

    return pickupEvent.timestamp.difference(offerEvent.timestamp);
  }

  /// Determines if the call was answered.
  bool get isAnswered =>
      events.any((_HistoricCallEvent e) => e.eventName == _callPickupKey);

  Duration get handleTime {
    if (inbound) {
      final _HistoricCallEvent offerEvent = events
          .firstWhere((_HistoricCallEvent e) => e.eventName == _callOfferKey);
      final _HistoricCallEvent hangupEvent = events.firstWhere(
          (_HistoricCallEvent e) =>
              e.eventName == _callHangupKey || e.eventName == _callTransferKey);
      return hangupEvent.timestamp.difference(offerEvent.timestamp);
    } else {
      // Outbound call.
      try {
        final _HistoricCallEvent stateEvent = events
            .firstWhere((_HistoricCallEvent e) => e.eventName == _callStateKey);

        final _HistoricCallEvent hangupEvent = events.firstWhere(
            (_HistoricCallEvent e) =>
                e.eventName == _callHangupKey ||
                e.eventName == _callTransferKey);

        return hangupEvent.timestamp.difference(stateEvent.timestamp);
      } catch (e) {
        _log.warning(
            'Failed to determine length of call - setting call duration to 0');
        _log.warning(toJson());
        return new Duration(seconds: 0);
      }
    }
  }

  DateTime get agentStart {
    if (inbound) {
      final _HistoricCallEvent offerEvent = events
          .firstWhere((_HistoricCallEvent e) => e.eventName == _callOfferKey);
      return offerEvent.timestamp;
    } else {
      // Outbound call.
      final _HistoricCallEvent stateEvent = events
          .firstWhere((_HistoricCallEvent e) => e.eventName == _callStateKey);

      return stateEvent.timestamp;
    }
  }

  DateTime get agentStop {
    if (inbound) {
      final _HistoricCallEvent hangupEvent = events.firstWhere(
          (_HistoricCallEvent e) =>
              e.eventName == _callHangupKey || e.eventName == _callTransferKey);
      return hangupEvent.timestamp;
    } else {
      // Outbound call.

      final _HistoricCallEvent hangupEvent = events.firstWhere(
          (_HistoricCallEvent e) =>
              e.eventName == _callHangupKey || e.eventName == _callTransferKey);

      return hangupEvent.timestamp;
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': callId,
        'uid': uid,
        'rid': rid,
        'cid': cid,
        'in': inbound,
        'es': events
            .map((_HistoricCallEvent e) => e.toJson())
            .toList(growable: false)
      };

  @override
  int get hashCode => callId.hashCode;

  @override
  bool operator ==(Object other) =>
      other is HistoricCall && other.callId == callId;
}
