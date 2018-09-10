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

part of orf.test;

void _testModelOpeningHour() {
  group('Model.OpeningHour', () {
    test('serializationDeserialization',
        _ModelOpeningHour.serializationDeserialization);

    test('serialization', _ModelOpeningHour.serialization);

    test('buildObject', _ModelOpeningHour.buildObject);
    test('parse (single)', _ModelOpeningHour.parseSingle);
    test('parse (single - FormatException)',
        _ModelOpeningHour.parseSingleFormatException);
    test('parse (multiple)', _ModelOpeningHour.parseMultiple);
    test('printFormat', _ModelOpeningHour.printFormat);
  });
}

abstract class _ModelOpeningHour {
  static void serialization() {
    model.OpeningHour builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void serializationDeserialization() {
    model.OpeningHour builtObject = buildObject();

    model.OpeningHour deserializedObject =
        model.OpeningHour.parse(_json.decode(_json.encode(builtObject)));

    expect(builtObject.toJson(), equals(deserializedObject.toJson()));

    expect(builtObject.toJson(), equals(deserializedObject.toJson()));
  }

  static model.OpeningHour buildObject() {
    final model.OpeningHour builtObject = new model.OpeningHour.empty()
      ..fromDay = model.WeekDay.mon
      ..toDay = model.WeekDay.thur
      ..fromHour = 9
      ..fromMinute = 30
      ..toHour = 16
      ..toMinute = 30;

    return builtObject;
  }

  static void parseSingle() {
    model.OpeningHour builtObject = model.OpeningHour.parse('mon-fri 8-17');

    expect(builtObject.fromDay, equals(model.WeekDay.mon));
    expect(builtObject.toDay, equals(model.WeekDay.fri));
    expect(builtObject.fromHour, equals(8));
    expect(builtObject.toHour, equals(17));

    builtObject = model.OpeningHour.parse('mon-fri     8-17   ');

    expect(builtObject.fromDay, equals(model.WeekDay.mon));
    expect(builtObject.toDay, equals(model.WeekDay.fri));
    expect(builtObject.fromHour, equals(8));
    expect(builtObject.toHour, equals(17));
  }

  static void parseSingleFormatException() {
    expect(() => model.Notify.parse('mon-ved 8-17'),
        throwsA(const TypeMatcher<FormatException>()));
  }

  static void printFormat() {
    expect(model.OpeningHour.parse('mon-fri 8-17').toJson(),
        equals('mon-fri 8:00-17:00'));
    expect(model.OpeningHour.parse('mon-fri 8:00-17:00').toJson(),
        equals('mon-fri 8:00-17:00'));

    expect(
        model.OpeningHour.parse('mon 8-17').toJson(), equals('mon 8:00-17:00'));

    expect(model.OpeningHour.parse('mon 8:00-17:00').toJson(),
        equals('mon 8:00-17:00'));
  }

  static void parseMultiple() {
    Iterable<model.OpeningHour> builtObjects =
        model.parseMultipleHours('mon-fri 8-17, sat 12-13');

    expect(builtObjects.first.fromDay, equals(model.WeekDay.mon));
    expect(builtObjects.first.toDay, equals(model.WeekDay.fri));
    expect(builtObjects.first.fromHour, equals(8));
    expect(builtObjects.first.toHour, equals(17));

    expect(builtObjects.last.fromDay, equals(model.WeekDay.sat));
    expect(builtObjects.last.toDay, equals(model.WeekDay.sat));
    expect(builtObjects.last.fromHour, equals(12));
    expect(builtObjects.last.toHour, equals(13));
  }
}
