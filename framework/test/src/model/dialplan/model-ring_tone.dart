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

void _testModelRingtone() {
  group('Model.Ringtone', () {
    test('serializationDeserialization', _ModelRingtone.deserialization);

    test('serialization', _ModelRingtone.serialization);

    test('buildObject', _ModelRingtone.buildObject);
  });
}

abstract class _ModelRingtone {
  static void serialization() {
    model.Ringtone builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void deserialization() {
    model.Ringtone builtObject = buildObject();

    model.Ringtone deserializedObject =
        model.Ringtone.parse(_json.decode(_json.encode(builtObject)));

    expect(builtObject.toJson(), equals(deserializedObject.toJson()));

    expect(builtObject.count, equals(deserializedObject.count));
  }

  static model.Ringtone buildObject() {
    final int count = 2;

    final model.Ringtone builtObject = new model.Ringtone(count);

    expect(builtObject.count, equals(count));

    return builtObject;
  }
}
