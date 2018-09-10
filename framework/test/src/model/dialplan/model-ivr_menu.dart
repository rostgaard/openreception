/*                  This file is part of OpenReception
                   Copyright (C) 2015-, BitStackers K/S

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

void _testModelIvrMenu() {
  group('Model.IvrMenu', () {
    test('serializationDeserialization',
        _ModelIvrMenu.serializationDeserialization);

    test('serialization', _ModelIvrMenu.serialization);

    test('buildObject', _ModelIvrMenu.buildObject);
  });
}

abstract class _ModelIvrMenu {
  static void serialization() {
    model.IvrMenu builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void serializationDeserialization() {
    model.IvrMenu builtObject = buildObject();

    model.IvrMenu deserializedObject = new model.IvrMenu.fromJson(
        _json.decode(_json.encode(builtObject)) as Map<String, dynamic>);

    expect(builtObject.toJson(), equals(deserializedObject.toJson()));

    expect(builtObject.name, equals(deserializedObject.name));
    expect(builtObject.greetingShort.filename,
        equals(deserializedObject.greetingShort.filename));
    expect(builtObject.greetingShort.note,
        equals(deserializedObject.greetingShort.note));
    expect(builtObject.greetingShort.toJson(),
        equals(deserializedObject.greetingShort.toJson()));

    expect(builtObject.greetingLong.filename,
        equals(deserializedObject.greetingLong.filename));
    expect(builtObject.greetingLong.note,
        equals(deserializedObject.greetingLong.note));
    expect(builtObject.greetingLong.toJson(),
        equals(deserializedObject.greetingLong.toJson()));

    expect(builtObject.toJson(), equals(deserializedObject.toJson()));

    expect(builtObject.entries, equals(builtObject.entries));
  }

  static model.IvrMenu buildObject() {
    final String name = 'ivr_1';
    final String sub1name = 'sub1';
    final String sub2name = 'sub2';
    final String filename = 'somefile.wav';
    final String sub1filename = 'sub1somefile.wav';
    final String sub2filename = 'sub2somefile.wav';

    final String note = 'Just a test';
    final model.Playback greeting = new model.Playback(filename, note: note);

    final model.Playback sub1greeting =
        new model.Playback(sub1filename, note: note);

    final model.Playback sub2greeting =
        new model.Playback(sub2filename, note: note);

    final List<model.IvrEntry> entries = <model.IvrEntry>[
      new model.IvrVoicemail(
          '1',
          new model.Voicemail('vm-corp_1',
              recipient: 'guy@corp1.org', note: 'Just some guy')),
      new model.IvrSubmenu('2', 'sub-1')
    ];

    final List<model.IvrEntry> sub1entries = <model.IvrEntry>[
      new model.IvrVoicemail(
          '1',
          new model.Voicemail('vm-corp_1',
              recipient: 'guy@corp1.org', note: 'Just some guy')),
      new model.IvrSubmenu('2', 'sub-2'),
      new model.IvrTopmenu('*')
    ];

    final List<model.IvrEntry> sub2entries = <model.IvrEntry>[
      new model.IvrVoicemail(
          '1',
          new model.Voicemail('vm-corp_1',
              recipient: 'guy@corp1.org', note: 'Just some guy')),
      new model.IvrSubmenu('2', 'sub-1')
    ];

    final model.IvrMenu sub1 = new model.IvrMenu(sub1name, sub1greeting)
      ..entries = sub1entries;
    final model.IvrMenu sub2 = new model.IvrMenu(sub2name, sub2greeting)
      ..entries = sub2entries;

    model.IvrMenu builtObject = new model.IvrMenu(name, greeting)
      ..entries = entries
      ..submenus = <model.IvrMenu>[sub1, sub2];

    expect(builtObject.name, equals(name));
    expect(builtObject.greetingShort.filename, equals(filename));
    expect(builtObject.greetingShort.note, equals(note));
    expect(builtObject.greetingShort.toJson(), equals(greeting.toJson()));

    expect(builtObject.greetingLong.filename, equals(filename));
    expect(builtObject.greetingLong.note, equals(note));
    expect(builtObject.greetingLong.toJson(), equals(greeting.toJson()));

    return builtObject;
  }
}
