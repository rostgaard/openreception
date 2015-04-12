import 'dart:async';

import '../lib/bus.dart';
import '../lib/model.dart'    as Model;
import '../lib/resource.dart' as Resource;
//import '../lib/service.dart'  as Service;
import 'data/testdata.dart'  as Test_Data;

//import 'package:logging/logging.dart';
import 'package:junitconfiguration/junitconfiguration.dart';
import 'package:unittest/unittest.dart';

void main() {
  //Logger.root.onRecord.listen(print);

  JUnitConfiguration.install();

  test('async openreception.bus test', () {
    final String testEvent = 'Foo!';
    Bus bus = new Bus<String>();
    Stream<String> stream = bus.stream;
    Timer timer;

    timer = new Timer(new Duration(seconds: 1), () {
      fail('testEvent not fired or caught within 1 second');
    });

    stream.listen(expectAsync((String value) {
      expect(value, equals(testEvent));

      if(timer != null) {
        timer.cancel();
      }
    }));

    bus.fire(testEvent);
  });

  test('service.ContactObject.serializationDeserialization', ContactObject.serializationDeserialization);

  group('service.MessageObject', () {
    test('serializationDeserialization', MessageObject.serializationDeserialization);
    test('serialization', MessageObject.serialization);
  });

  group('Resource.Authentication', () {
    test('userOf', ResourceAuthentication.userOf);
    test('validate', ResourceAuthentication.validate);
  });

  group('Resource.Message', () {
    test('singleMessage', ResourceMessage.singleMessage);
    test('send', ResourceMessage.send);
    test('list', ResourceMessage.list);
  });

  group('Resource.Reception', () {
    test('singleMessage', ResourceReception.single);
    test('list', ResourceReception.list);
    test('subset', ResourceReception.subset);
    test('calendar', ResourceReception.calendar);
    test('calendarEvent', ResourceReception.calendarEvent);
  });

  group('service.ResourceCallFlowControl', () {
    test('userStatusMap', ResourceCallFlowControl.userStatusMap);
    test('channelList', ResourceCallFlowControl.channelList);
    test('userStatusIdle', ResourceCallFlowControl.userStatusIdle);
    test('peerList', ResourceCallFlowControl.peerList);
    test('single', ResourceCallFlowControl.single);
    test('pickup', ResourceCallFlowControl.pickup);
    test('originate', ResourceCallFlowControl.originate);
    test('park', ResourceCallFlowControl.park);
    test('hangup', ResourceCallFlowControl.hangup);
    test('transfer', ResourceCallFlowControl.transfer);
    test('list', ResourceCallFlowControl.list);
  });
}

abstract class ResourceCallFlowControl {
  static Uri callFlowControlUri = Uri.parse('http://localhost:4242');

  static void userStatusMap () =>
      expect(Resource.CallFlowControl.userStatus(callFlowControlUri, 1),
        equals(Uri.parse('${callFlowControlUri}/userstate/1')));

  static void channelList () =>
      expect(Resource.CallFlowControl.channelList(callFlowControlUri),
        equals(Uri.parse('${callFlowControlUri}/channel/list')));

  static void userStatusIdle () =>
      expect(Resource.CallFlowControl.userStatusIdle(callFlowControlUri, 1),
        equals(Uri.parse('${callFlowControlUri}/userstate/1/idle')));

  static void peerList () =>
      expect(Resource.CallFlowControl.peerList(callFlowControlUri),
        equals(Uri.parse('${callFlowControlUri}/peer/list')));

  static void single () =>
      expect(Resource.CallFlowControl.single(callFlowControlUri, 'abcde'),
        equals(Uri.parse('${callFlowControlUri}/call/abcde')));

  static void pickup () =>
      expect(Resource.CallFlowControl.pickup(callFlowControlUri, 'abcde'),
        equals(Uri.parse('${callFlowControlUri}/call/abcde/pickup')));

  static void originate () =>
      expect(Resource.CallFlowControl.originate(callFlowControlUri, '12345678', 1, 2),
        equals(Uri.parse('${callFlowControlUri}/call/originate/12345678/reception/2/contact/1')));

  static void park () =>
      expect(Resource.CallFlowControl.park(callFlowControlUri, 'abcde'),
        equals(Uri.parse('${callFlowControlUri}/call/abcde/park')));

  static void hangup () =>
      expect(Resource.CallFlowControl.hangup(callFlowControlUri, 'abcde'),
        equals(Uri.parse('${callFlowControlUri}/call/abcde/hangup')));

  static void transfer () =>
      expect(Resource.CallFlowControl.transfer(callFlowControlUri, 'abcde', 'edcba'),
        equals(Uri.parse('${callFlowControlUri}/call/abcde/transfer/edcba')));

  static void list () =>
      expect(Resource.CallFlowControl.list(callFlowControlUri),
        equals(Uri.parse('${callFlowControlUri}/call')));

}

abstract class MessageObject {
  static void serializationDeserialization () =>
      expect(new Model.Message.fromMap(Test_Data.testMessage_1_Map).asMap,
        equals(Test_Data.testMessage_1_Map));

  /**
   * Merely asserts that no exceptions arise.
   */
  static void serialization () =>
      expect(new Model.Message.fromMap(Test_Data.testMessage_1_Map), isNotNull);
}

abstract class ContactObject {
  static void serializationDeserialization () =>
      expect(new Model.Contact.fromMap(Test_Data.testContact_1_2).asMap,
        equals(Test_Data.testContact_1_2));
}

abstract class ResourceReception {
  static Uri receptionServer = Uri.parse('http://localhost:4000');

  static void single () =>
      expect(Resource.Reception.single(receptionServer, 1),
        equals(Uri.parse('${receptionServer}/reception/1')));

  static void list () =>
      expect(Resource.Reception.list(receptionServer),
        equals(Uri.parse('${receptionServer}/reception')));

  static void subset () =>
      expect(Resource.Reception.subset(receptionServer, 10, 20),
        equals(Uri.parse('${receptionServer}/reception/10/limit/20')));

  static void calendar () =>
      expect(Resource.Reception.calendar(receptionServer, 1),
        equals(Uri.parse('${receptionServer}/reception/1/calendar')));

  static void calendarEvent () =>
      expect(Resource.Reception.calendarEvent(receptionServer, 1, 2),
        equals(Uri.parse('${receptionServer}/reception/1/calendar/event/2')));
}

abstract class ResourceMessage {
  static Uri messageServer = Uri.parse('http://localhost:4040');

  static void singleMessage () =>
      expect(Resource.Message.single(messageServer, 5),
        equals(Uri.parse('${messageServer}/message/5')));

  static void send () =>
      expect(Resource.Message.send(messageServer, 5),
        equals(Uri.parse('${messageServer}/message/5/send')));

  static void list () =>
      expect(Resource.Message.list(messageServer),
        equals(Uri.parse('${messageServer}/message/list')));
}

abstract class ResourceAuthentication {
  static final Uri authServer = Uri.parse('http://localhost:4050');

  static void userOf () =>
      expect(Resource.Authentication.tokenToUser(authServer, 'testtest'),
        equals(Uri.parse('${authServer}/token/testtest')));

  static void validate () =>
      expect(Resource.Authentication.validate(authServer, 'testtest'),
        equals(Uri.parse('${authServer}/token/testtest/validate')));
}
