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

void _testModelMessageEndpoint() {
  group('Model.MessageEndpoint', () {
    test('buildObject', _ModelMessageEndpoint.buildObject);
    test('deserialization', _ModelMessageEndpoint.deserialization);
    test('serialization', _ModelMessageEndpoint.serialization);
  });
}

abstract class _ModelMessageEndpoint {
  static void deserialization() {
    model.MessageEndpoint obj = buildObject();
    model.MessageEndpoint deserializedObj = new model.MessageEndpoint.fromJson(
        _json.decode(_json.encode(obj)) as Map<String, dynamic>);

    expect(obj.address, equals(deserializedObj.address));
    expect(obj.name, equals(deserializedObj.name));
    expect(obj.type, equals(deserializedObj.type));
    expect(obj.note, equals(deserializedObj.note));
  }

  static void serialization() {
    model.MessageEndpoint builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  /// Build an object manually.
  static model.MessageEndpoint buildObject() {
    final String name = 'John Arbuckle';
    final String address = 'test@test.test';
    final String note = 'Some Reception';
    final String type = model.MessageEndpointType.emailTo;

    model.MessageEndpoint obj = new model.MessageEndpoint.empty()
      ..address = address
      ..name = name
      ..note = note
      ..type = type;

    expect(obj.address, equals(address));
    expect(obj.name, equals(name));
    expect(obj.note, equals(note));
    expect(obj.type, equals(type));

    return obj;
  }
}
