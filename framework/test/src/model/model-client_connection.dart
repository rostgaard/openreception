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

void _testModelClientConnection() {
  group('Model.ClientConnection', () {
    test('buildObject', _ModelClientConnection.buildObject);
    test('serialization', _ModelClientConnection.serialization);
    test('deserialization', _ModelClientConnection.deserialization);
  });
}

abstract class _ModelClientConnection {
  static void deserialization() {
    model.ClientConnection builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);
    model.ClientConnection decodedCall = new model.ClientConnection.fromJson(
        _json.decode(serializedObject) as Map<String, dynamic>);

    expect(builtObject.connectionCount, equals(decodedCall.connectionCount));
    expect(builtObject.userID, equals(decodedCall.userID));

    expect(builtObject.toJson(), equals(decodedCall.toJson()));
  }

  /// Assert that no exceptions arise during serialization.
  static void serialization() {
    model.ClientConnection builtObject = buildObject();

    expect(() => _json.encode(builtObject), returnsNormally);
  }

  static model.ClientConnection buildObject() {
    final int userId = 2;
    final int connectionCount = 1;

    model.ClientConnection builtObject = new model.ClientConnection.empty()
      ..connectionCount = connectionCount
      ..userID = userId;

    expect(builtObject.connectionCount, equals(connectionCount));
    expect(builtObject.userID, equals(userId));

    return builtObject;
  }
}
