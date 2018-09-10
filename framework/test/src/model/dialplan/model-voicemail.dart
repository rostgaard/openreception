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

void _testModelVoicemail() {
  group('Model.Voicemail', () {
    test('deserialization', _ModelVoicemail.deserialization);
    test('serialization', _ModelVoicemail.serialization);
    test('buildObject', _ModelVoicemail.buildObject);
    test('multipleRecipients', _ModelVoicemail.multipleRecipients);
  });
}

abstract class _ModelVoicemail {
  static void serialization() {
    model.Voicemail builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void deserialization() {
    model.Voicemail builtObject = buildObject();

    model.Voicemail deserializedObject =
        model.Voicemail.parse(_json.decode(_json.encode(builtObject)) as String);

    expect(builtObject.toJson(), equals(deserializedObject.toJson()));

    expect(builtObject.vmBox, equals(deserializedObject.vmBox));
    expect(builtObject.recipient, equals(deserializedObject.recipient));
    expect(builtObject.note, equals(deserializedObject.note));
  }

  static model.Voicemail buildObject() {
    final String vmBox = 'vm-33114422';
    final String recipient = 'someone@email.dot';
    final String note = 'Someones email';

    model.Voicemail builtObject =
        new model.Voicemail(vmBox, recipient: recipient, note: note);

    expect(builtObject.vmBox, equals(vmBox));
    expect(builtObject.recipient, equals(recipient));
    expect(builtObject.note, equals(note));

    return builtObject;
  }

  static void multipleRecipients() {
    final String vmBox = 'vm-33114422';
    final String recipient1 = 'someone@email.dot';
    final String recipient2 = 'someoneelse@otheremail.prik';
    final String note = 'Someones email';
    final String recipients = <String>[recipient1, recipient2].join('');

    model.Voicemail builtObject =
        new model.Voicemail(vmBox, recipient: recipients, note: note);

    expect(builtObject.vmBox, equals(vmBox));
    expect(builtObject.recipient, equals(recipients));
    expect(builtObject.note, equals(note));
  }
}
