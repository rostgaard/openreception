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

void _testModelPhoneNumber() {
  group('Model.PhoneNumber', () {
    test('serialization', _ModelPhoneNumber.serialization);
    test('deserialization', _ModelPhoneNumber.deserialization);
    test('buildObject', _ModelPhoneNumber.buildObject);
  });
}

abstract class _ModelPhoneNumber {
  /// assert that no exceptions arise during serialization.
  static void serialization() {
    model.PhoneNumber builtObject = buildObject();

    expect(() => _json.encode(builtObject), returnsNormally);
  }

  /// Assert that no exceptions arise during a deserialization.
  static void deserialization() {
    model.PhoneNumber built = buildObject();

    model.PhoneNumber decoded = new model.PhoneNumber.fromJson(
        _json.decode(_json.encode(built)) as Map<String, dynamic>);

    expect(built.confidential, equals(decoded.confidential));
    expect(built.note, equals(decoded.note));
    expect(built.destination, equals(decoded.destination));

    expect(built.toJson(), equals(decoded.toJson()));
  }

  static model.PhoneNumber buildObject() {
    final String description = 'Cell Phone - work';
    final String value = '+45 44 88 1231';

    final bool confidential = false;

    model.PhoneNumber phoneNumber = new model.PhoneNumber.empty()
      ..confidential = confidential
      ..note = description
      ..destination = value;

    expect(phoneNumber.confidential, equals(confidential));
    expect(phoneNumber.note, equals(description));
    expect(phoneNumber.destination, equals(value));

    return phoneNumber;
  }
}
