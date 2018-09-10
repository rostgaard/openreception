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

void _testModelReceptionTransfer() {
  group('Model.ReceptionTransfer', () {
    test('deserialization', _ModelReceptionTransfer.deserialization);

    test('serialization', _ModelReceptionTransfer.serialization);

    test('buildObject', _ModelReceptionTransfer.buildObject);
    test('parsing', _ModelReceptionTransfer.parsing);
  });
}

abstract class _ModelReceptionTransfer {
  static void serialization() {
    model.ReceptionTransfer builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void deserialization() {
    model.ReceptionTransfer builtObject = buildObject();

    model.ReceptionTransfer deserializedObject =
        model.ReceptionTransfer.parse(_json.decode(_json.encode(builtObject)));

    expect(builtObject.toJson(), equals(deserializedObject.toJson()));

    expect(builtObject.extension, equals(deserializedObject.extension));
    expect(builtObject.note, equals(deserializedObject.note));
  }

  static void parsing() {
    final String buffer1 = 'reception 12340001';
    final String buffer2 = 'reception 12340001 (Test reception 1)';
    final String buffer3 = 'transfer 12340001 (Test reception 1)';

    expect(model.ReceptionTransfer.parse(buffer1), isNotNull);
    expect(model.ReceptionTransfer.parse(buffer2), isNotNull);
    expect(() => model.ReceptionTransfer.parse(buffer3),
        throwsA(const TypeMatcher<FormatException>()));
  }

  static model.ReceptionTransfer buildObject() {
    final String extension = '322114455';
    final String note = 'Just an extension';

    model.ReceptionTransfer builtObject =
        new model.ReceptionTransfer(extension, note: note);

    expect(builtObject.extension, equals(extension));
    expect(builtObject.note, equals(note));

    return builtObject;
  }
}
