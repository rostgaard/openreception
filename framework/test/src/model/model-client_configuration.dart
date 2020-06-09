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

void _testModelClientConfiguration() {
  group('Model.ClientConfiguration', () {
    test('serializationDeserialization',
        _ModelClientConfiguration.serializationDeserialization);
    test('serialization', _ModelClientConfiguration.serialization);
    test('buildObject', _ModelClientConfiguration.buildObject);
  });
}

abstract class _ModelClientConfiguration {
  static void serialization() {
    model.ClientConfiguration builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void serializationDeserialization() {
    model.ClientConfiguration builtObject = buildObject();
    model.ClientConfiguration deserializedObject =
        new model.ClientConfiguration.fromJson(
            _json.decode(_json.encode(builtObject)) as Map<String, dynamic>);

    expect(builtObject.authServerUri, equals(deserializedObject.authServerUri));
    expect(builtObject.userServerUri, equals(deserializedObject.userServerUri));
    expect(builtObject.callFlowServerUri,
        equals(deserializedObject.callFlowServerUri));
    expect(builtObject.contactServerUri,
        equals(deserializedObject.contactServerUri));
    expect(builtObject.dialplanServerUri,
        equals(deserializedObject.dialplanServerUri));
    expect(builtObject.hideInboundCallerId,
        equals(deserializedObject.hideInboundCallerId));
    expect(builtObject.messageServerUri,
        equals(deserializedObject.messageServerUri));
    expect(builtObject.myIdentifiers, equals(deserializedObject.myIdentifiers));
    expect(builtObject.notificationServerUri,
        equals(deserializedObject.notificationServerUri));
    expect(builtObject.notificationSocketUri,
        equals(deserializedObject.notificationSocketUri));
    expect(builtObject.receptionServerUri,
        equals(deserializedObject.receptionServerUri));
    expect(
        builtObject.systemLanguage, equals(deserializedObject.systemLanguage));
  }

  /// Build an object, and check that the expected values are present.
  static model.ClientConfiguration buildObject() {
    final String authServerUri = Uri.parse('http://authserver.example.com').toString();
    final String userServerUri = Uri.parse('http://userserver.example.com').toString();
    final String callFlowServerUri = Uri.parse('http://callFlow.example.com').toString();
    final String contactServerUri = Uri.parse('http://contact.example.com').toString();
    final bool hideInboundCallerId = true;
    final String messageServerUri = Uri.parse('http://message.example.com').toString();
    final List<String> myIdentifiers = const <String>['123456789'];
    final String dialplanServerUri = Uri.parse('http://dialplan.example.com').toString();
    final String notificationServerUri =
        Uri.parse('http://notification.example.com').toString();
    final String notificationSocketUri =
        Uri.parse('ws://notification.example.com').toString();
    final String receptionServerUri = Uri.parse('http://reception.example.com').toString();
    final String systemLanguage = 'en';

    model.ClientConfiguration config = new model.ClientConfiguration.empty()
      ..authServerUri = authServerUri
      ..callFlowServerUri = callFlowServerUri
      ..contactServerUri = contactServerUri
      ..dialplanServerUri = dialplanServerUri
      ..hideInboundCallerId = hideInboundCallerId
      ..messageServerUri = messageServerUri
      ..myIdentifiers = myIdentifiers
      ..notificationServerUri = notificationServerUri
      ..notificationSocketUri = notificationSocketUri
      ..receptionServerUri = receptionServerUri
      ..userServerUri = userServerUri
      ..systemLanguage = systemLanguage;

    expect(config.authServerUri, equals(authServerUri));
    expect(config.userServerUri, equals(userServerUri));
    expect(config.callFlowServerUri, equals(callFlowServerUri));
    expect(config.contactServerUri, equals(contactServerUri));
    expect(config.dialplanServerUri, equals(dialplanServerUri));
    expect(config.hideInboundCallerId, equals(hideInboundCallerId));
    expect(config.messageServerUri, equals(messageServerUri));
    expect(config.myIdentifiers, equals(myIdentifiers));
    expect(config.notificationServerUri, equals(notificationServerUri));
    expect(config.notificationSocketUri, equals(notificationSocketUri));
    expect(config.receptionServerUri, equals(receptionServerUri));
    expect(config.systemLanguage, equals(systemLanguage));

    return config;
  }
}
