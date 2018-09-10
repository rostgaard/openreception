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

void _testModelCalendarCommit() {
  group('Model.CalendarCommit', () {
    test('deserialization', _ModelCalendarEntryChange.deserialization);
    test('serialization', _ModelCalendarEntryChange.serialization);
    test('buildObject', _ModelCalendarEntryChange.buildObject);
  });
}

abstract class _ModelCalendarEntryChange {
  static void deserialization() {
    model.Commit built = buildObject();
    model.Commit deserialized = new model.Commit.fromJson(
        _json.decode(_json.encode(built)) as Map<String, dynamic>);

    expect(built.toJson(), equals(deserialized.toJson()));

    expect(built.commitHash, equals(deserialized.commitHash));
    expect(
        built.changedAt.difference(deserialized.changedAt).abs().inMilliseconds,
        lessThan(1));
    expect(built.authorIdentity, equals(deserialized.authorIdentity));
  }

  /// Asserts that no exceptions arise during serialization.
  static void serialization() {
    model.Commit builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static model.Commit buildObject() {
    final DateTime changedAt = new DateTime.now();
    final String parentRef = 'asdm3mmf';
    final String changedBy = 'user@place';

    model.Commit builtObject = new model.Commit()
      ..changedAt = changedAt
      ..commitHash = parentRef
      ..authorIdentity = changedBy;

    expect(builtObject.commitHash, equals(parentRef));
    expect(builtObject.changedAt, equals(changedAt));
    expect(builtObject.authorIdentity, equals(changedBy));

    return builtObject;
  }
}
