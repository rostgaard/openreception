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

void _testModelUserStatus() {
  group('Model.Status', () {
    test('deserialization', _ModelUserStatus.deserialization);
    test('serialization', _ModelUserStatus.serialization);
    test('buildObject', _ModelUserStatus.buildObject);
//    test('stateChange', ModelUserStatus.stateChange);
  });
}

abstract class _ModelUserStatus {
  /// Merely asserts that no exceptions arise during a deserialization.
  static void deserialization() {
    model.UserStatus built = buildObject();
    String serializedObject = _json.encode(built);
    model.UserStatus decoded = new model.UserStatus.fromJson(
        _json.decode(serializedObject) as Map<String, dynamic>);

    expect(built.paused, equals(decoded.paused));
    expect(built.userId, equals(decoded.userId));

    expect(built.toJson(), equals(decoded.toJson()));
  }

  static void serialization() {
    model.UserStatus builtObject = buildObject();
    String serializedString = _json.encode(builtObject);

    expect(serializedString, isNotEmpty);
    expect(serializedString, isNotNull);
  }

  static model.UserStatus buildObject() {
    final bool paused = true;
    final int userId = 2;

    model.UserStatus builtObject = new model.UserStatus(paused, userId);

    expect(builtObject.paused, equals(paused));
    expect(builtObject.userId, equals(userId));

    return builtObject;
  }
}
