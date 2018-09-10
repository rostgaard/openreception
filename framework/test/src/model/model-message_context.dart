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

void _testModelMessageContext() {
  group('Model.MessageContext', () {
    test('buildObject', _ModelMessageContext.buildObject);
    test('deserialization', _ModelMessageContext.deserialization);
    test('serialization', _ModelMessageContext.serialization);
  });
}

abstract class _ModelMessageContext {
  static void deserialization() {
    model.MessageContext obj = buildObject();
    model.MessageContext deserializedObj = new model.MessageContext.fromJson(
        _json.decode(_json.encode(obj)) as Map<String, dynamic>);

    expect(obj.cid, equals(deserializedObj.cid));
    expect(obj.contactName, equals(deserializedObj.contactName));

    expect(obj.rid, equals(deserializedObj.rid));
    expect(obj.receptionName, equals(deserializedObj.receptionName));

    expect(obj.toJson(), equals(deserializedObj.toJson()));
  }

  static void serialization() {
    model.MessageContext builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  /// Build an object manually.
  static model.MessageContext buildObject() {
    final int contactId = 1;
    final String contactName = 'John Arbuckle';
    final int rid = 2;
    final String receptionName = 'Lasagna-makers inc.';

    model.MessageContext obj = new model.MessageContext.empty()
      ..cid = contactId
      ..contactName = contactName
      ..rid = rid
      ..receptionName = receptionName;

    expect(obj.cid, equals(contactId));
    expect(obj.contactName, equals(contactName));

    expect(obj.rid, equals(rid));
    expect(obj.receptionName, equals(receptionName));

    return obj;
  }
}
