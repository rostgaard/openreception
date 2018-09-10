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

void _testModelIvrEntry() {
  group('Model.IvrEntry', () {
    test('parseUndefined', _ModelIvrEntry.parseUndefined);
    test('parseIvrReceptionTransfer', _ModelIvrEntry.parseIvrReceptionTransfer);
    test('parseSubmenu', _ModelIvrEntry.parseSubmenu);
    test('parseTopmenu', _ModelIvrEntry.parseTopmenu);
    test('parseIvrTransfer', _ModelIvrEntry.parseIvrTransfer);
    test('parseIvrVoicemail', _ModelIvrEntry.parseIvrVoicemail);
  });
}

abstract class _ModelIvrEntry {
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

    expect(builtObject.entries, equals(deserializedObject.entries));
  }

  static model.IvrMenu buildObject() {
    final String name = 'ivr_1';
    final String filename = 'somefile.wav';
    final String note = 'Just a test';
    final model.Playback greeting = new model.Playback(filename, note: note);

    final List<model.IvrEntry> entries = <model.IvrEntry>[
      new model.IvrVoicemail('1', new model.Voicemail('vm-test')),
      new model.IvrTransfer('2', new model.Transfer('testtesttest')),
    ];

    model.IvrMenu builtObject = new model.IvrMenu(name, greeting)
      ..entries = entries;

    expect(builtObject.name, equals(name));
    expect(builtObject.greetingShort.filename, equals(filename));
    expect(builtObject.greetingShort.note, equals(note));

    expect(builtObject.greetingShort.toJson(), equals(greeting.toJson()));

    expect(builtObject.entries, equals(entries));
    expect(builtObject.greetingLong.filename, equals(filename));
    expect(builtObject.greetingLong.note, equals(note));
    expect(builtObject.greetingLong.toJson(), equals(greeting.toJson()));

    return builtObject;
  }

  static void parseSubmenu() {
    final String submenu = 'sub_1';

    model.IvrSubmenu builtObject = model.IvrEntry.parse('1: submenu $submenu');

    expect(builtObject.digits, equals('1'));
    expect(builtObject, const TypeMatcher<model.IvrSubmenu>());
    expect(builtObject.name, equals(submenu));
  }

  static void parseIvrTransfer() {
    final String extension = '33444222';

    model.IvrTransfer builtObject =
        model.IvrEntry.parse('2: transfer $extension');

    expect(builtObject.digits, equals('2'));
    expect(builtObject, const TypeMatcher<model.IvrTransfer>());
    expect(builtObject.transfer.extension, equals(extension));
  }

  static void parseIvrReceptionTransfer() {
    final String extension = '33444222';

    model.IvrReceptionTransfer builtObject =
        model.IvrEntry.parse('2: reception $extension');

    expect(builtObject.digits, equals('2'));
    expect(builtObject, const TypeMatcher<model.IvrReceptionTransfer>());
    expect(builtObject.transfer.extension, equals(extension));
  }

  static void parseIvrVoicemail() {
    final String vmBox = 'vm-33444222';
    final String recipient = 'krc@awesome.me';
    final String note = 'Standard email';

    model.IvrVoicemail builtObject =
        model.IvrEntry.parse('3: voicemail $vmBox $recipient ($note)');

    expect(builtObject.digits, equals('3'));
    expect(builtObject, const TypeMatcher<model.IvrVoicemail>());
    expect(builtObject.voicemail.vmBox, equals(vmBox));
    expect(builtObject.voicemail.recipient, equals(recipient));
    expect(builtObject.voicemail.note, equals(note));

    builtObject =
        model.IvrEntry.parse('3:   voicemail   $vmBox   $recipient   ($note)');

    expect(builtObject.digits, equals('3'));
    expect(builtObject, const TypeMatcher<model.IvrVoicemail>());
    expect(builtObject.voicemail.vmBox, equals(vmBox));
    expect(builtObject.voicemail.recipient, equals(recipient));
    expect(builtObject.voicemail.note, equals(note));

    builtObject = model.IvrEntry.parse('3: voicemail $vmBox ($note)');

    expect(builtObject.digits, equals('3'));
    expect(builtObject, const TypeMatcher<model.IvrVoicemail>());
    expect(builtObject.voicemail.vmBox, equals(vmBox));
    expect(builtObject.voicemail.recipient, isEmpty);
    expect(builtObject.voicemail.note, equals(note));
  }

  static void parseTopmenu() {
    model.IvrTopmenu builtObject = model.IvrEntry.parse('*: topmenu');

    expect(builtObject.digits, equals('*'));
    expect(builtObject, const TypeMatcher<model.IvrEntry>());
  }

  static void parseUndefined() {
    final String filename = 'somefile.wav';
    //final String note = 'Just a test';

    expect(() => model.IvrEntry.parse('1: wrong-wrong-wrong '),
        throwsA(const TypeMatcher<FormatException>()));

    ///Wrong digit length.
    expect(() => model.IvrEntry.parse('12: $filename'),
        throwsA(const TypeMatcher<FormatException>()));
  }
}
