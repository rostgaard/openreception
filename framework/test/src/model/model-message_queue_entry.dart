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

void _testModelMessageQueueEntry() {
  group('Model.MessageQueueEntry', () {
    test('buildObject', _ModelMessageQueueEntry.buildObject);
    test('deserialization', _ModelMessageQueueEntry.deserialization);
    test('serialization', _ModelMessageQueueEntry.serialization);

    test('handleRecipient', _ModelMessageQueueEntry.handleRecipient);
  });
}

abstract class _ModelMessageQueueEntry {
  static void handleRecipient() {
    model.MessageQueueEntry obj = buildObject();

    final int origLen = obj.unhandledRecipients.length;
    expect(origLen, greaterThan(1));
    expect(obj.handledRecipients, isEmpty);

    model.MessageEndpoint handled = obj.unhandledRecipients.first;

    obj.handledRecipients = <model.MessageEndpoint>[handled];

    expect(obj.unhandledRecipients.length, equals(origLen - 1));
    expect(obj.handledRecipients.length, equals(1));

    expect(obj.unhandledRecipients.contains(handled), isFalse);
    expect(obj.handledRecipients.contains(handled), isTrue);
  }

  static void deserialization() {
    model.MessageQueueEntry obj = buildObject();
    model.MessageQueueEntry deserializedObj =
        new model.MessageQueueEntry.fromJson(
            _json.decode(_json.encode(obj)) as Map<String, dynamic>);

    expect(obj.id, equals(deserializedObj.id));

    expect(obj.message.toJson(), equals(deserializedObj.message.toJson()));

    expect(
        obj.unhandledRecipients, equals(deserializedObj.unhandledRecipients));
  }

  static void serialization() {
    model.MessageQueueEntry builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  /// Build an object manually.
  static model.MessageQueueEntry buildObject() {
    final int id = 666;
    //final lastTry = new DateTime.now();
    final model.Message message = _ModelMessage.buildObject();

    final List<model.MessageEndpoint> recipients = <model.MessageEndpoint>[
      new model.MessageEndpoint.empty()
        ..address = 'neverland'
        ..name = 'Unholy one'
        ..note = 'A hot place'
        ..type = model.MessageEndpointType.emailTo,
      new model.MessageEndpoint.empty()
        ..address = 'neverland 2'
        ..name = 'Unholy one jr.'
        ..note = 'A less hot place'
        ..type = model.MessageEndpointType.emailBcc,
    ];

    model.MessageQueueEntry obj = new model.MessageQueueEntry.empty()
      ..id = id
      ..message = message
      ..unhandledRecipients = recipients;

    expect(obj.id, equals(id));

    expect(obj.message.toJson(), equals(message.toJson()));

    expect(obj.unhandledRecipients, equals(recipients));

    return obj;
  }
}
