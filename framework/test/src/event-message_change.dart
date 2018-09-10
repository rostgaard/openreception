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

void _testEventMessageChange() {
  group('Event.MessageChange', () {
    test('buildObject', _EventMessageChange.buildObject);
    test('serialization', _EventMessageChange.serialization);
    test('serializationDeserialization',
        _EventMessageChange.serializationDeserialization);
  });
}

abstract class _EventMessageChange {
  static void buildObject() {
    final int mid = 1;
    final int uid = 2;
    final DateTime now = new DateTime.now();
    final model.MessageState state = model.MessageState.values.last;

    event.MessageChange testEvent =
        new event.MessageChange.create(mid, uid, state, now);

    expect(testEvent.mid, equals(mid));
    expect(testEvent.modifierUid, equals(uid));
    expect(testEvent.state, equals(event.Change.created));
    expect(testEvent.messageState, equals(state));
    expect(testEvent.timestamp.difference(now).inMilliseconds, equals(0));

    testEvent = new event.MessageChange.update(mid, uid, state, now);

    expect(testEvent.mid, equals(mid));
    expect(testEvent.modifierUid, equals(uid));
    expect(testEvent.state, equals(event.Change.updated));
    expect(testEvent.messageState, equals(state));
    expect(testEvent.timestamp.difference(now).inMilliseconds, equals(0));

    testEvent = new event.MessageChange.delete(mid, uid, state, now);

    expect(testEvent.mid, equals(mid));
    expect(testEvent.modifierUid, equals(uid));
    expect(testEvent.state, equals(event.Change.deleted));
    expect(testEvent.messageState, equals(state));
    expect(testEvent.timestamp.difference(now).inMilliseconds, equals(0));
  }

  static void serialization() {
    final int mid = 1;
    final int uid = 2;
    final DateTime now = new DateTime.now();
    final model.MessageState state = model.MessageState.values.last;

    event.MessageChange testEvent =
        new event.MessageChange.create(mid, uid, state, now);

    expect(testEvent.toJson, returnsNormally);
  }

  static void serializationDeserialization() {
    final int mid = 1;
    final int uid = 2;
    final DateTime now = new DateTime.now();
    final model.MessageState state = model.MessageState.values.last;

    event.MessageChange testEvent =
        new event.MessageChange.create(mid, uid, state, now);

    expect(testEvent.mid, equals(mid));
    expect(testEvent.modifierUid, equals(uid));
    expect(testEvent.state, equals(event.Change.created));
    expect(testEvent.messageState, equals(state));
    expect(testEvent.timestamp.difference(now).inMilliseconds, equals(0));

    event.MessageChange serialized = new event.MessageChange.fromJson(
        _json.decode(_json.encode(testEvent)) as Map<String, dynamic>);

    expect(testEvent.toJson(), equals(serialized.toJson()));
  }
}
