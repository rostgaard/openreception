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

void _testModelMessageFilter() {
  group('Model.MessageFilter', () {
    test('buildObject', _ModelMessageFilter.buildObject);
    test('deserialization', _ModelMessageFilter.deserialization);
    test('serialization', _ModelMessageFilter.serialization);
  });
}

abstract class _ModelMessageFilter {
  static void deserialization() {
    model.MessageFilter obj = buildObject();
    model.MessageFilter deserializedObj = new model.MessageFilter.fromJson(
        _json.decode(_json.encode(obj)) as Map<String, dynamic>);

    expect(obj.contactId, equals(deserializedObj.contactId));
    expect(obj.limitCount, equals(deserializedObj.limitCount));
    expect(obj.receptionId, equals(deserializedObj.receptionId));
    expect(obj.userId, equals(deserializedObj.userId));
  }

  static void serialization() {
    model.MessageFilter builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  /// Build an object manually.
  static model.MessageFilter buildObject() {
    final int cid = 1;
    final int limitCount = 100;
    final int rid = 2;

    final int uid = 99;

    model.MessageFilter obj = new model.MessageFilter.empty()
      ..contactId = cid
      ..limitCount = limitCount
      ..receptionId = rid
      ..userId = uid;

    expect(obj.contactId, equals(cid));
    expect(obj.limitCount, equals(limitCount));
    expect(obj.receptionId, equals(rid));
    expect(obj.userId, equals(uid));

    return obj;
  }
}
