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

const JsonCodec _json = const JsonCodec();

void _testEvent() {
  group('Event.parse', () {
    test('contactChangeState', _EventTests.contactChangeState);
    test('organizationChangeState', _EventTests.organizationChangeState);
    test('receptionChangeState', _EventTests.receptionChangeState);
    test(
        'receptionContactChangeState', _EventTests.receptionContactChangeState);
    test('messageChangeState', _EventTests.messageChangeState);
    test('calendarEntryState', _EventTests.calendarEntryState);
    test('userChange', _EventTests.userChange);
    test('callStateReload', _EventTests.callStateReload);
    test('callHangup', _EventTests.callHangup);
  });
}

abstract class _EventTests {
  static void contactChangeState() {
    final int cid = 1;

    event.ContactChange testEvent = new event.ContactChange.create(cid);

    event.ContactChange builtEvent =
        new event.Event.parse(testEvent.toJson()) as event.ContactChange;

    expect(builtEvent.cid, equals(cid));
    expect(builtEvent.state, equals(event.Change.created));
  }

  static void organizationChangeState() {
    final int oid = 1;
    final int uid = 3;

    event.OrganizationChange testEvent =
        new event.OrganizationChange.create(oid, uid);

    event.OrganizationChange builtEvent = new event.Event.parse(
        _json.decode(_json.encode(testEvent)) as Map<String, dynamic>);

    expect(builtEvent.oid, equals(oid));
    expect(builtEvent.modifierUid, equals(uid));
    expect(builtEvent.state, equals(event.Change.created));
  }

  static void receptionChangeState() {
    final int rid = 1;
    final int uid = 3;

    event.ReceptionChange testEvent =
        new event.ReceptionChange.create(rid, uid);

    event.ReceptionChange builtEvent =
        new event.Event.parse(testEvent.toJson()) as event.ReceptionChange;

    expect(builtEvent.rid, equals(rid));
    expect(builtEvent.modifierUid, equals(uid));
    expect(builtEvent.state, equals(event.Change.created));
  }

  static void receptionContactChangeState() {
    final int cid = 1;
    final int rid = 2;
    final int uid = 3;

    event.ReceptionData testEvent =
        new event.ReceptionData.create(cid, rid, uid);

    event.ReceptionData builtEvent =
        new event.Event.parse(testEvent.toJson()) as event.ReceptionData;

    expect(builtEvent.cid, equals(cid));
    expect(builtEvent.rid, equals(rid));
    expect(builtEvent.modifierUid, equals(uid));
    expect(builtEvent.state, equals(event.Change.created));
  }

  static void messageChangeState() {
    final int mid = 1;
    final int uid = 2;
    final DateTime now = new DateTime.now();
    final model.MessageState state = model.MessageState.values.last;

    event.MessageChange testEvent =
        new event.MessageChange.create(mid, uid, state, now);

    event.MessageChange builtEvent = new event.Event.parse(
        _json.decode(_json.encode(testEvent)) as Map<String, dynamic>);

    expect(builtEvent.mid, equals(mid));
    expect(builtEvent.modifierUid, equals(uid));
    expect(builtEvent.state, equals(event.Change.created));
    expect(builtEvent.messageState, equals(state));
    expect(builtEvent.timestamp.difference(now).inMilliseconds, equals(0));
  }

  static void calendarEntryState() {
    final int eid = 1;
    final model.Owner owner = new model.OwningReception(3);
    final int uid = 3;

    event.CalendarChange testEvent =
        new event.CalendarChange.create(eid, owner, uid);

    event.CalendarChange builtEvent =
        new event.Event.parse(testEvent.toJson()) as event.CalendarChange;

    expect(builtEvent.owner.toJson(), equals(owner.toJson()));
    expect(builtEvent.eid, equals(eid));
    expect(builtEvent.modifierUid, equals(uid));
    expect(builtEvent.state, equals(event.Change.created));
  }

  static void userChange() {
    final int userId = 1234;
    final int modifier = 4312;

    event.UserChange createEvent =
        new event.UserChange.create(userId, modifier);
    event.UserChange updateEvent =
        new event.UserChange.update(userId, modifier);
    event.UserChange removeEvent =
        new event.UserChange.delete(userId, modifier);

    event.UserChange builtEvent =
        new event.Event.parse(createEvent.toJson()) as event.UserChange;

    expect(builtEvent.uid, equals(userId));
    expect(builtEvent.modifierUid, equals(modifier));
    expect(builtEvent.state, equals(event.Change.created));

    builtEvent =
        new event.Event.parse(updateEvent.toJson()) as event.UserChange;

    expect(builtEvent.uid, equals(userId));
    expect(builtEvent.modifierUid, equals(modifier));
    expect(builtEvent.state, equals(event.Change.updated));

    builtEvent =
        new event.Event.parse(removeEvent.toJson()) as event.UserChange;

    expect(builtEvent.uid, equals(userId));
    expect(builtEvent.modifierUid, equals(modifier));
    expect(builtEvent.state, equals(event.Change.deleted));
  }

  static void callStateReload() {
    event.CallStateReload testEvent = new event.CallStateReload();

    event.Event builtEvent = new event.Event.parse(
        _json.decode(_json.encode(testEvent)) as Map<String, dynamic>);

    expect(
        builtEvent.timestamp
            .difference(testEvent.timestamp)
            .inMilliseconds
            .abs(),
        lessThan(1000));
    expect(builtEvent, const TypeMatcher<event.CallStateReload>());
    expect(builtEvent.eventName, testEvent.eventName);
  }

  static void callHangup() {
    model.Call testCall = new model.Call.empty('test-id');

    event.CallHangup testEvent =
        new event.CallHangup(testCall, hangupCause: 'no-reason');

    event.CallHangup builtEvent =
        new event.Event.parse(testEvent.toJson()) as event.CallHangup;

    expect(
        builtEvent.timestamp
            .difference(testEvent.timestamp)
            .abs()
            .inMilliseconds,
        lessThan(1));
    expect(builtEvent, const TypeMatcher<event.CallHangup>());
    expect(builtEvent.hangupCause, equals(testEvent.hangupCause));
    expect(builtEvent.eventName, testEvent.eventName);
  }
}
