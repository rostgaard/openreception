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

void _testModelPeerAccount() {
  group('Model.BaseContact', () {
    test('deserialization', _ModelPeerAccount.deserialization);

    test('serialization', _ModelPeerAccount.serialization);

    test('buildObject', _ModelPeerAccount.buildObject);
  });
}

abstract class _ModelPeerAccount {
  static void serialization() {
    model.PeerAccount builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void deserialization() {
    model.PeerAccount built = _ModelPeerAccount.buildObject();
    model.PeerAccount deserialized = new model.PeerAccount.fromJson(
        _json.decode(_json.encode(built)) as Map<String, dynamic>);

    expect(built.username, equals(deserialized.username));
    expect(built.password, equals(deserialized.password));
    expect(built.context, equals(deserialized.context));
  }

  static model.PeerAccount buildObject() {
    final String name = 'hal9000';
    final String password = 'I\'m afraid I cannot let you do that';
    final String context = 'Discovery One';

    model.PeerAccount builtObject =
        new model.PeerAccount(name, password, context);

    expect(builtObject.username, equals(name));
    expect(builtObject.password, equals(password));
    expect(builtObject.context, equals(context));

    return builtObject;
  }
}
