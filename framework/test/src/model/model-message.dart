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

void _testModelMessage() {
  group('Model.Message', () {
    test('deserialization', _ModelMessage.deserialization);
    test('serialization', _ModelMessage.serialization);
    test('buildObject', _ModelMessage.buildObject);
    test('messageFlag', _ModelMessage.messageFlag);
  });
}

abstract class _ModelMessage {
  static void deserialization() {
    model.Message obj = buildObject();
    model.Message deserializedObj = new model.Message.fromJson(
        _json.decode(_json.encode(obj)) as Map<String, dynamic>);

    expect(obj.body, equals(deserializedObj.body));
    expect(
        obj.callerInfo.toJson(), equals(deserializedObj.callerInfo.toJson()));
    expect(obj.callId, equals(deserializedObj.callId));

    expect(obj.createdAt.difference(deserializedObj.createdAt).abs(),
        lessThan(new Duration(seconds: 1)));

    expect(obj.flag.called, equals(deserializedObj.flag.called));
    expect(obj.flag.pleaseCall, equals(deserializedObj.flag.pleaseCall));
    expect(obj.flag.urgent, equals(deserializedObj.flag.urgent));
    expect(obj.flag.willCallBack, equals(deserializedObj.flag.willCallBack));
    expect(obj.id, equals(deserializedObj.id));
    expect(obj.context.toJson(), equals(deserializedObj.context.toJson()));
    expect(
        obj.recipients.toList(), equals(deserializedObj.recipients.toList()));
    expect(obj.sender.id, equals(deserializedObj.sender.id));

    expect(obj.toJson(), equals(deserializedObj.toJson()));
  }

  static void serialization() {
    model.Message builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  /// Build an object, and check that the expected values are present.
  static model.Message buildObject() {
    final model.CallerInfo info = new model.CallerInfo.empty()
      ..cellPhone = 'Drowned'
      ..company = 'Shifty eyes inc.'
      ..localExtension = 'Just ask for Bob'
      ..name = 'Ian Malcom'
      ..phone = 'Out of order';

    final model.User sender = _ModelUser.buildObject();
    final String callId = 'bad-ass-call';

    Set<model.MessageEndpoint> rlist = new Set<model.MessageEndpoint>()
      ..addAll(<model.MessageEndpoint>[
        new model.MessageEndpoint.empty()
          ..address = 'somewhere'
          ..name = 'someone'
          ..note = 'The Office'
          ..type = model.MessageEndpointType.types.first
      ]);

    final String messageBody = 'You should really clean up.';
    final DateTime createdAt = new DateTime.now();
    final int id = 42;

    final model.MessageContext context = new model.MessageContext.empty()
      ..cid = 2
      ..contactName = 'John Doe'
      ..rid = 4
      ..receptionName = 'Nowhere';

    final model.MessageState state = model.MessageState.values.last;

    final model.Message obj = new model.Message.empty()
      ..body = messageBody
      ..callId = callId
      ..callerInfo = info
      ..createdAt = createdAt
      ..flag.called = true
      ..flag.pleaseCall = true
      ..flag.urgent = true
      ..flag.willCallBack = true
      ..id = id
      ..context = context
      ..recipients = rlist
      ..sender = sender
      ..state = state;

    expect(obj.body, equals(messageBody));
    expect(obj.callerInfo.toJson(), equals(info.toJson()));
    expect(obj.callId, equals(callId));
    expect(obj.createdAt, equals(createdAt));
    expect(obj.flag.called, isTrue);
    expect(obj.flag.pleaseCall, isTrue);
    expect(obj.flag.urgent, isTrue);
    expect(obj.flag.willCallBack, isTrue);
    expect(obj.id, equals(id));
    expect(obj.context.toJson(), equals(context.toJson()));
    expect(obj.recipients.toList(), equals(rlist.toList()));
    expect(obj.sender.toJson(), equals(sender.toJson()));
    expect(obj.state, equals(state));

    return obj;
  }

  static void messageFlag() {
    model.Message builtObject = buildObject();

    builtObject.flag = new model.MessageFlag.empty();
    builtObject.flag.pleaseCall = false;
    builtObject.flag.willCallBack = false;
    builtObject.flag.called = false;
    builtObject.flag.urgent = false;
    expect(builtObject.flag.pleaseCall, equals(false));
    expect(builtObject.flag.willCallBack, equals(false));
    expect(builtObject.flag.called, equals(false));
    expect(builtObject.flag.urgent, equals(false));

    builtObject.flag = new model.MessageFlag.empty();
    builtObject.flag.pleaseCall = true;
    builtObject.flag.willCallBack = true;
    builtObject.flag.called = true;
    builtObject.flag.urgent = true;
    expect(builtObject.flag.pleaseCall, equals(true));
    expect(builtObject.flag.willCallBack, equals(true));
    expect(builtObject.flag.called, equals(true));
    expect(builtObject.flag.urgent, equals(true));
  }
}
