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

void _testModelNotify() {
  group('Model.Notify', () {
    test('serializationDeserialization',
        _ModelNotify.serializationDeserialization);

    test('serialization', _ModelNotify.serialization);

    test('buildObject', _ModelNotify.buildObject);
    test('parse', _ModelNotify.parse);
  });
}

abstract class _ModelNotify {
  static void serialization() {
    model.Notify builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void serializationDeserialization() {
    model.Notify builtObject = buildObject();

    model.Notify deserializedObject =
        model.Notify.parse(_json.decode(_json.encode(builtObject)));

    expect(builtObject.toJson(), equals(deserializedObject.toJson()));

    expect(builtObject.eventName, equals(deserializedObject.eventName));
    expect(builtObject.toJson(), equals(deserializedObject.toJson()));
  }

  static model.Notify buildObject() {
    final String eventName = 'call-offer';
    final model.Notify builtObject = new model.Notify(eventName);

    expect(builtObject.eventName, equals(eventName));

    return builtObject;
  }

  static void parse() {
    final String eventName = 'call-offer';

    model.Notify builtObject = model.Notify.parse('notify $eventName');

    expect(builtObject.eventName, equals(eventName));

    /// Adding lots of spaces.
    builtObject = model.Notify.parse('   notify     $eventName');

    expect(builtObject.eventName, equals(eventName));

    expect(() => model.Notify.parse('notif $eventName'),
        throwsA(const TypeMatcher<FormatException>()));
  }
}
