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

part of orf.test;

void _testModelCall() {
  group('Model.Call', () {
    test('serialization', _ModelCall.serialization);
    test('deserialization', _ModelCall.deserialization);
    test('buildObject', _ModelCall.buildObject);
    test('callStateStream', _ModelCall.callStateStream);
    test('callStateUnknownToCreated', _ModelCall.callStateUnknownToCreated);
    test('callStateCreatedToRinging', _ModelCall.callStateCreatedToRinging);
    test('callStateParkToHangup', _ModelCall.callStateParkToHangup);
    test('callEventStream', _ModelCall.callEventStream);
    test('callEventStreamUnparkFromHangup',
        _ModelCall.callEventStreamUnparkFromHangup);
    test('callEventStreamQueueLeaveFromHangup',
        _ModelCall.callEventStreamQueueLeaveFromHangup);
  });
}

abstract class _ModelCall {
  /// Assert that no exceptions arise during serialization.
  static void serialization() {
    model.Call builtObject = buildObject();

    expect(() => _json.encode(builtObject), returnsNormally);
  }

  /// Assert that the event stream actually spawns events.
  static Future<Null> callEventStream() {
    List<event.Event> stateChanges = <event.Event>[];

    model.Call builtObject = buildObject()..event.listen(stateChanges.add);

    int initialStateChangeCount = stateChanges.length;

    builtObject.changeState(model.CallState.created);

    return new Future<Null>.delayed(new Duration(milliseconds: 20), () {
      expect(stateChanges.length, equals(initialStateChangeCount + 1));
      expect(stateChanges.last, const TypeMatcher<event.Event>());
    });
  }

  /// Asserts that the event stream spawns unpark event from hangup.
  static Future<Null> callEventStreamUnparkFromHangup() {
    List<event.Event> stateChanges = <event.Event>[];

    model.Call builtObject = buildObject()
      ..state = model.CallState.parked
      ..event.listen(stateChanges.add);

    int initialStateChangeCount = stateChanges.length;
    expect(builtObject.state, equals(model.CallState.parked));
    builtObject.changeState(model.CallState.hungup);

    return new Future<Null>.delayed(new Duration(milliseconds: 20), () {
      expect(stateChanges.length, equals(initialStateChangeCount + 2));
      expect(stateChanges[stateChanges.length - 2],
          const TypeMatcher<event.CallUnpark>());
      expect(stateChanges.last, const TypeMatcher<event.CallHangup>());
    });
  }

  /// Assert that the event stream spawns extra event on queue-> hangup
  /// transition.
  static Future<Null> callEventStreamQueueLeaveFromHangup() {
    List<event.Event> stateChanges = <event.Event>[];

    model.Call builtObject = buildObject()
      ..state = model.CallState.queued
      ..event.listen(stateChanges.add);

    int initialStateChangeCount = stateChanges.length;
    expect(builtObject.state, equals(model.CallState.queued));
    builtObject.changeState(model.CallState.hungup);

    return new Future<Null>.delayed(new Duration(milliseconds: 20), () {
      expect(stateChanges.length, equals(initialStateChangeCount + 2));
      expect(stateChanges[stateChanges.length - 2],
          const TypeMatcher<event.QueueLeave>());
      expect(stateChanges.last, const TypeMatcher<event.CallHangup>());
    });
  }

  /// Assert that the stream spawns events.
  static Future<Null> callStateStream() {
    List<String> stateChanges = <String>[];

    model.Call builtObject = buildObject()..callState.listen(stateChanges.add);

    int initialStateChangeCount = stateChanges.length;

    builtObject.state = model.CallState.transferring;

    return new Future<Null>.delayed(new Duration(milliseconds: 20), () {
      expect(stateChanges.length, equals(initialStateChangeCount + 1));
    });
  }

  /// Assert that the stream spawns the correct event.
  static Future<Null> callStateUnknownToCreated() {
    List<String> stateChanges = <String>[];

    model.Call builtObject = buildObject()..callState.listen(stateChanges.add);

    int initialStateChangeCount = stateChanges.length;

    builtObject.state = model.CallState.unknown;
    builtObject.state = model.CallState.created;

    return new Future<Null>.delayed(new Duration(milliseconds: 20), () {
      expect(stateChanges.length, equals(initialStateChangeCount + 2));
      expect(stateChanges.last, equals(model.CallState.created));
    });
  }

  /// Assert that the stream spawns events in the correct order.
  static Future<Null> callStateParkToHangup() {
    List<String> stateChanges = <String>[];

    model.Call builtObject = buildObject()..callState.listen(stateChanges.add);

    int initialStateChangeCount = stateChanges.length;

    builtObject.state = model.CallState.parked;
    builtObject.state = model.CallState.hungup;

    return new Future<Null>.delayed(new Duration(milliseconds: 20), () {
      expect(stateChanges.length, equals(initialStateChangeCount + 2));
      expect(stateChanges[stateChanges.length - 2],
          equals(model.CallState.parked));
      expect(stateChanges.last, equals(model.CallState.hungup));
    });
  }

  /// Assert that the stream spawns the correct event.
  static Future<Null> callStateCreatedToRinging() {
    List<String> stateChanges = <String>[];

    model.Call builtObject = buildObject()..callState.listen(stateChanges.add);

    int initialStateChangeCount = stateChanges.length;

    builtObject.state = model.CallState.created;
    builtObject.state = model.CallState.ringing;

    return new Future<Null>.delayed(new Duration(milliseconds: 20), () {
      expect(stateChanges.length, equals(initialStateChangeCount + 2));
      expect(stateChanges.last, equals(model.CallState.ringing));
    });
  }

  /// Asserts that no exceptions arise during serialization.
  static void deserialization() {
    model.Call builtCall = buildObject();
    String serializedObject = _json.encode(builtCall);
    model.Call decodedCall = new model.Call.fromJson(
        _json.decode(serializedObject) as Map<String, dynamic>);

    expect(builtCall.id, equals(decodedCall.id));
    expect(builtCall.arrived.difference(decodedCall.arrived).abs(),
        lessThan(new Duration(seconds: 1)));
    expect(builtCall.answeredAt.difference(decodedCall.answeredAt).abs(),
        lessThan(new Duration(seconds: 1)));
    expect(builtCall.assignedTo, equals(decodedCall.assignedTo));
    expect(builtCall.bLeg, equals(decodedCall.bLeg));
    expect(builtCall.callerId, equals(decodedCall.callerId));
    expect(builtCall.cid, equals(decodedCall.cid));
    expect(builtCall.destination, equals(decodedCall.destination));
    expect(builtCall.greetingPlayed, equals(decodedCall.greetingPlayed));
    expect(builtCall.inbound, equals(decodedCall.inbound));
    expect(builtCall.locked, equals(decodedCall.locked));
    expect(builtCall.rid, equals(decodedCall.rid));
    expect(builtCall.state, equals(decodedCall.state));

    expect(builtCall.toJson(), equals(decodedCall.toJson()));
  }

  static model.Call buildObject() {
    final String testId = 'test-id';
    final String blegTestId = 'b-leg-test-id';
    final DateTime arrived = new DateTime.now();
    final DateTime answeredAt = new DateTime.now()
      ..add(new Duration(seconds: 30));
    final int assignedTo = 1;
    final String callerId = 'That guy';
    final int contactId = 2;
    final int rid = 3;
    final String destination = '12345678';
    final bool greetingPlayed = false;
    final bool inbound = true;
    final bool locked = false;
    final String state = model.CallState.created;

    model.Call builtCall = new model.Call.empty(testId)
      ..arrived = arrived
      ..answeredAt = answeredAt
      ..assignedTo = assignedTo
      ..bLeg = blegTestId
      ..callerId = callerId
      ..cid = contactId
      ..destination = destination
      ..greetingPlayed = greetingPlayed
      ..inbound = inbound
      ..locked = locked
      ..rid = rid
      ..state = model.CallState.created;

    expect(builtCall.id, equals(testId));
    expect(builtCall.arrived, equals(arrived));
    expect(builtCall.answeredAt, equals(answeredAt));
    expect(builtCall.assignedTo, equals(assignedTo));
    expect(builtCall.bLeg, equals(blegTestId));
    expect(builtCall.callerId, equals(callerId));
    expect(builtCall.cid, equals(contactId));
    expect(builtCall.destination, equals(destination));
    expect(builtCall.greetingPlayed, equals(greetingPlayed));
    expect(builtCall.inbound, equals(inbound));
    expect(builtCall.locked, equals(locked));
    expect(builtCall.rid, equals(rid));
    expect(builtCall.state, equals(state));

    return builtCall;
  }
}
