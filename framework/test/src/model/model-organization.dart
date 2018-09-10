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

void _testModelOrganization() {
  group('Model.Organization', () {
    test('buildObject', _ModelOrganization.buildObject);
    test('serialization', _ModelOrganization.serialization);
    test('deserialization', _ModelOrganization.deserialization);
  });
}

abstract class _ModelOrganization {
  /// Asserts that no exceptions arise during serialization.
  static void serialization() {
    model.Organization builtObject = buildObject();

    expect(() => _json.encode(builtObject), returnsNormally);
  }

  /// Assert that no exceptions arise during deserialization.
  static void deserialization() {
    model.Organization builtObject = buildObject();

    String serializedObject = _json.encode(builtObject);
    model.Organization decodedObject = new model.Organization.fromJson(
        _json.decode(serializedObject) as Map<String, dynamic>);

    expect(builtObject.notes, equals(decodedObject.notes));
    expect(builtObject.id, equals(decodedObject.id));
    expect(builtObject.name, equals(decodedObject.name));

    expect(builtObject.toJson(), equals(decodedObject.toJson()));
  }

  static model.Organization buildObject() {
    final List<String> notes = <String>['Goldmember'];
    final int id = 42;
    final String name = 'Hey Goldmember!';

    model.Organization testOrganization = new model.Organization.empty()
      ..notes = notes
      ..id = id
      ..name = name;
    expect(testOrganization.notes, equals(notes));
    expect(testOrganization.id, equals(id));
    expect(testOrganization.name, equals(name));

    return testOrganization;
  }
}
