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

void _testModelCalendarEntry() {
  group('Model.CalendarEntry', () {
    test('deserialization', _ModelCalendarEntry.deserialization);
    test('serialization', _ModelCalendarEntry.serialization);
    test('buildObject', _ModelCalendarEntry.buildObject);
  });
}

abstract class _ModelCalendarEntry {
  static void deserialization() {
    model.CalendarEntry builtObject = buildObject();
    model.CalendarEntry deserialized = new model.CalendarEntry.fromJson(
        _json.decode(_json.encode(builtObject)) as Map<String, dynamic>);

    expect(builtObject.id, equals(deserialized.id));
    expect(builtObject.content, equals(deserialized.content));
    expect(
        builtObject.start.difference(deserialized.start).abs().inMilliseconds,
        lessThan(1));
    expect(builtObject.stop.difference(deserialized.stop).abs().inMilliseconds,
        lessThan(1));
    expect(builtObject.lastAuthorId, equals(deserialized.lastAuthorId));
  }

  static void serialization() {
    expect(_json.encode(buildObject()), isNotNull);
    expect(_json.encode(buildObject()), isNotEmpty);
  }

  static model.CalendarEntry buildObject() {
    final int id = 123;
    final String body = 'test test test';
    final DateTime touched = new DateTime.now();
    final DateTime begin = new DateTime.now().add(new Duration(hours: 1));
    final DateTime end = new DateTime.now().add(new Duration(hours: 2));
    final int uid = 42;

    model.CalendarEntry builtObject = new model.CalendarEntry.empty()
      ..lastAuthorId = uid
      ..touched = touched
      ..id = id
      ..content = body
      ..start = begin
      ..stop = end;

    expect(builtObject.id, equals(id));
    expect(builtObject.lastAuthorId, equals(uid));
    expect(builtObject.touched, equals(touched));
    expect(builtObject.content, equals(body));
    expect(builtObject.start, equals(begin));
    expect(builtObject.stop, equals(end));

    return builtObject;
  }
}
