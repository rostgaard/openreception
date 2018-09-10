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

void _testModelTransfer() {
  group('Model.Voicemail', () {
    test('deserialization', _ModelTransfer.deserialization);

    test('serialization', _ModelTransfer.serialization);

    test('buildObject', _ModelTransfer.buildObject);
  });
}

abstract class _ModelTransfer {
  static void serialization() {
    model.Transfer builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void deserialization() {
    model.Transfer builtObject = buildObject();

    model.Transfer deserializedObject =
        model.Transfer.parse(_json.decode(_json.encode(builtObject)));

    expect(builtObject.toJson(), equals(deserializedObject.toJson()));

    expect(builtObject.extension, equals(deserializedObject.extension));
    expect(builtObject.note, equals(deserializedObject.note));
  }

  static model.Transfer buildObject() {
    final String extension = '322114455';
    final String note = 'Just an extension';

    model.Transfer builtObject = new model.Transfer(extension, note: note);

    expect(builtObject.extension, equals(extension));
    expect(builtObject.note, equals(note));

    return builtObject;
  }
}
