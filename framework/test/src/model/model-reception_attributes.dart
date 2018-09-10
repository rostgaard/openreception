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

void _testModelReceptionAttributes() {
  group('Model.ReceptionAttributes', () {
    test('deserialization', _ModelReceptionAttributes.deserialization);

    test('serialization', _ModelReceptionAttributes.serialization);

    test('buildObject', _ModelReceptionAttributes.buildObject);
  });
}

abstract class _ModelReceptionAttributes {
  static void serialization() {
    model.ReceptionAttributes builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void deserialization() {
    model.ReceptionAttributes builtObject = buildObject();
    model.ReceptionAttributes deserializedObject =
        new model.ReceptionAttributes.fromJson(
            _json.decode(_json.encode(builtObject)) as Map<String, dynamic>);

    expect(builtObject.receptionId, equals(deserializedObject.receptionId));
    expect(builtObject.cid, equals(deserializedObject.cid));

    {
      Iterable<Map<String, dynamic>> lhsPn =
          builtObject.phoneNumbers.map((model.PhoneNumber pn) => pn.toJson());
      Iterable<Map<String, dynamic>> rhsPn = deserializedObject.phoneNumbers
          .map((model.PhoneNumber pn) => pn.toJson());

      expect(lhsPn, equals(rhsPn));
    }

    expect(
        builtObject.backupContacts, equals(deserializedObject.backupContacts));
    expect(builtObject.departments, equals(deserializedObject.departments));
    expect(
        builtObject.emailaddresses, equals(deserializedObject.emailaddresses));
    expect(builtObject.handling, equals(deserializedObject.handling));
    expect(builtObject.infos, equals(deserializedObject.infos));

    expect(builtObject.titles, equals(deserializedObject.titles));
    expect(builtObject.relations, equals(deserializedObject.relations));
    expect(builtObject.responsibilities,
        equals(deserializedObject.responsibilities));
    expect(builtObject.tags, equals(deserializedObject.tags));
    expect(builtObject.workhours, equals(deserializedObject.workhours));
    expect(builtObject.messagePrerequisites,
        equals(deserializedObject.messagePrerequisites));
    expect(builtObject.whenWhats, equals(deserializedObject.whenWhats));
  }

  static model.ReceptionAttributes buildObject() {
    final int receptionId = 2;
    final int contactId = 3;

    final List<model.PhoneNumber> pn = <model.PhoneNumber>[
      new model.PhoneNumber.empty()
        ..confidential = true
        ..note = 'Fluid connection'
        ..destination = '-0045 32112345'
    ];

    final List<String> backupContacts = <String>['Buford'];
    final List<String> departments = <String>['Fish school', 'Clowning'];
    final List<String> emailaddresses = <String>['scaly@nibble.bits'];
    final List<String> handling = <String>['Avoid fishing rods, please'];
    final List<String> infos = <String>[
      'He\'s a fish, what more do you need to know?'
    ];
    final List<String> titles = <String>['GOLD-fish'];
    final List<String> relations = <String>['Yo\' mamma'];
    final List<String> responsibilities = <String>[
      'Swimming around',
      'Nibbling'
    ];
    final List<String> tags = <String>['Fish', 'Gold', 'Athlete'];
    final List<String> workhours = <String>['Quite frankly; never'];
    final List<String> messagePrerequisites = <String>['[fishcode]'];

    final List<model.WhenWhat> whenWhats = <model.WhenWhat>[
      new model.WhenWhat('man-fri 08:00-09:00', 'Meeting'),
      new model.WhenWhat('wed 12:00-12:30', 'lunch')
    ];

    model.ReceptionAttributes builtObject =
        new model.ReceptionAttributes.empty()
          ..receptionId = receptionId
          ..cid = contactId
          ..phoneNumbers.addAll(pn)
          ..backupContacts = backupContacts
          ..departments = departments
          ..emailaddresses = emailaddresses
          ..handling = handling
          ..infos = infos
          ..titles = titles
          ..relations.addAll(relations)
          ..responsibilities = responsibilities
          ..tags = tags
          ..workhours = workhours
          ..messagePrerequisites = messagePrerequisites
          ..whenWhats = whenWhats;

    expect(builtObject.receptionId, equals(receptionId));
    expect(builtObject.cid, equals(contactId));

    expect(builtObject.phoneNumbers, equals(pn));
    expect(builtObject.backupContacts, equals(backupContacts));
    expect(builtObject.departments, equals(departments));
    expect(builtObject.emailaddresses, equals(emailaddresses));
    expect(builtObject.handling, equals(handling));
    expect(builtObject.infos, equals(infos));
    expect(builtObject.titles, equals(titles));
    expect(builtObject.relations, equals(relations));
    expect(builtObject.responsibilities, equals(responsibilities));
    expect(builtObject.tags, equals(tags));
    expect(builtObject.workhours, equals(workhours));
    expect(builtObject.messagePrerequisites, equals(messagePrerequisites));
    expect(builtObject.whenWhats, equals(whenWhats));

    return builtObject;
  }
}
