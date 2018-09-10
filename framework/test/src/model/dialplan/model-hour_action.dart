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

void _testModelHourAction() {
  group('Model.HourAction', () {
    test('deserialization', _HourAction.deserialization);

    test('serialization', _HourAction.serialization);

    test('buildObject', _HourAction.buildObject);
    test('parse', _HourAction.parse);
  });
}

abstract class _HourAction {
  static void serialization() {
    model.HourAction builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void deserialization() {
    model.HourAction builtObject = buildObject();

    model.HourAction deserializedObject = model.HourAction
        .parse(_json.decode(_json.encode(builtObject)) as Map<String, dynamic>);

    expect(builtObject.hours, equals(deserializedObject.hours));
    expect(builtObject.actions, equals(deserializedObject.actions));
    expect(builtObject.toString(), isNotEmpty);
  }

  static model.HourAction buildObject() {
    final List<model.OpeningHour> openHours = <model.OpeningHour>[
      new model.OpeningHour.empty()
        ..fromDay = model.WeekDay.mon
        ..fromHour = 8
        ..fromMinute = 30
        ..toDay = model.WeekDay.thur
        ..toHour = 17,
      new model.OpeningHour.empty()
        ..fromDay = model.WeekDay.fri
        ..fromHour = 8
        ..fromMinute = 30
        ..toDay = model.WeekDay.fri
        ..toHour = 16
    ];
    final List<model.Action> actions = <model.Action>[
      _ModelPlayback.buildObject()
    ];

    model.HourAction builtObject = new model.HourAction()
      ..hours = openHours
      ..actions = actions;

    expect(builtObject.hours, equals(openHours));
    expect(builtObject.actions, equals(actions));
    expect(builtObject.toString(), isNotEmpty);

    return builtObject;
  }

  static void parse() {}
}
