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

void _testModelReceptionDialplan() {
  group('Model.ReceptionDialplan', () {
    test('buildObject', _ModelReceptionDialplan.buildObject);
    test('deserialization', _ModelReceptionDialplan.deserialization);
    test('serialization', _ModelReceptionDialplan.serialization);
  });
}

abstract class _ModelReceptionDialplan {
  static void deserialization() {
    model.ReceptionDialplan builtObject = buildObject();
    model.ReceptionDialplan deserializedObject =
        new model.ReceptionDialplan.fromJson(
            _json.decode(_json.encode(builtObject)) as Map<String, dynamic>);

    expect(builtObject.extension, equals(deserializedObject.extension));
    expect(builtObject.note, equals(deserializedObject.note));
    expect(builtObject.extension, equals(deserializedObject.extension));
    expect(builtObject.open, equals(deserializedObject.open));
    expect(
        builtObject.defaultActions, equals(deserializedObject.defaultActions));
  }

  static void serialization() {
    model.ReceptionDialplan builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static model.ReceptionDialplan buildObject() {
    final String extension = '12345678';
    final String note = 'Just a test reception dialplan';

    final List<model.HourAction> open = <model.HourAction>[
      new model.HourAction()
        ..hours = model.parseMultipleHours('mon-fri 16-17').toList()
        ..actions = <model.Action>[new model.Playback('somefile')]
    ];

    final List<model.Action> closed = <model.Action>[
      new model.Playback('otherfile')
    ];

    final model.ReceptionDialplan builtObject = new model.ReceptionDialplan()
      ..extension = extension
      ..note = note
      ..open = open
      ..defaultActions = closed;

    expect(builtObject.extension, equals(extension));
    expect(builtObject.extension, equals(extension));
    expect(builtObject.note, equals(note));
    expect(builtObject.open, equals(open));
    expect(builtObject.defaultActions, equals(closed));

    return builtObject;
  }
}
