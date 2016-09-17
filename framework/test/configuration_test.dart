/*                  This file is part of OpenReception
                   Copyright (C) 2016-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

library orf.test.validation;

import 'dart:convert';

import 'package:orf/configuration.dart' as config;
import 'package:test/test.dart';

import 'src/log_setup.dart';

void main() {
  setupLogging();
  _eslTests();
  _configTests();
}

void _eslTests() {
  group('config.EslConfig', () {
    test('serialization', () {
      final config.EslConfig conf = new config.EslConfig();
      final String serialized = JSON.encode(conf);

      expect(serialized, isNotNull);
      expect(serialized, isNotEmpty);
    });

    test('deserialization', () {
      final String hostname = 'testy-mc-host';
      final String password = 'secretty-dollface';
      final int port = 18021;

      final config.EslConfig conf = new config.EslConfig(
          hostname: hostname, password: password, port: port);

      final String serialized = JSON.encode(conf);
      final config.EslConfig deserialized =
          new config.EslConfig.fromJson(JSON.decode(serialized));

      expect(deserialized, isNotNull);
      expect(conf.hostname, equals(deserialized.hostname));
      expect(conf.password, equals(deserialized.password));
      expect(conf.port, equals(deserialized.port));
    });

    test('buildObject', () {
      final String hostname = 'testy-mc-host';
      final String password = 'secretty-dollface';
      final int port = 18021;

      final config.EslConfig conf = new config.EslConfig(
          hostname: hostname, password: password, port: port);

      expect(conf.hostname, equals(hostname));
      expect(conf.password, equals(password));
      expect(conf.port, equals(port));
    });
  });
}

void _configTests() {
  group('config.Configuration', () {
    test('serialization', () {
      final config.Configuration conf = new config.Configuration.defaults();
      final String serialized = JSON.encode(conf);

      expect(serialized, isNotNull);
      expect(serialized, isNotEmpty);
    });

    test('deserialization', () {
      final config.CdrServer cdr = new config.CdrServer(
          port: 14090, pathToCdrCtl: '/point/of/no/return');

      final smtpDefaults = const config.SmtpConfig();
      final config.SmtpConfig smtp = new config.SmtpConfig(
          hostname: smtpDefaults.hostname + 'test1',
          ignoreBadCertificate: !smtpDefaults.ignoreBadCertificate,
          name: smtpDefaults.name + 'test2',
          username: smtpDefaults.username + 'test3',
          secure: !smtpDefaults.secure,
          password: smtpDefaults.password + 'test4',
          port: smtpDefaults.port + 10000);

      final config.EslConfig esl = new config.EslConfig(
          hostname: 'test', password: 'secretty-dollface', port: 10821);

      final config.CallFlowControl callflow = new config.CallFlowControl();

      final config.CalendarServer calendarServer =
          const config.CalendarServer();
      final config.ConfigServer configServer = const config.ConfigServer();
      final config.ContactServer contactServer = const config.ContactServer();
      final config.DialplanServer dialplanServer =
          const config.DialplanServer();
      final config.MessageServer messageServer = const config.MessageServer();
      final config.MessageDispatcher messageDispatcher =
          const config.MessageDispatcher();
      final config.NotificationServer notificationServer =
          const config.NotificationServer();
      final config.AuthServer authServer = const config.AuthServer();

      final config.Configuration conf = new config.Configuration(
          esl,
          smtp,
          '',
          'testy-mc-host',
          authServer,
          callflow,
          calendarServer,
          configServer,
          contactServer,
          cdr,
          dialplanServer,
          messageDispatcher,
          messageServer,
          notificationServer);

      final encoder = new JsonEncoder.withIndent('  ');

      print(encoder.convert(conf));

      final String serialized = JSON.encode(conf);
      final config.Configuration deserialized =
          new config.Configuration.fromJson(JSON.decode(serialized));

      expect(conf.esl.hostname, equals(deserialized.esl.hostname));
      expect(conf.esl.password, equals(deserialized.esl.password));
      expect(conf.esl.port, equals(deserialized.esl.port));
      expect(conf.externalHostname, equals(deserialized.externalHostname));

      expect(conf.smtp.hostname, equals(deserialized.smtp.hostname));
      expect(conf.smtp.password, equals(deserialized.smtp.password));
      expect(conf.smtp.port, equals(deserialized.smtp.port));
      expect(conf.smtp.ignoreBadCertificate,
          equals(deserialized.smtp.ignoreBadCertificate));
      expect(conf.smtp.name, equals(deserialized.smtp.name));
      expect(conf.smtp.username, equals(deserialized.smtp.username));
      expect(conf.smtp.secure, equals(deserialized.smtp.secure));
    });

    test('buildObject', () {
      final String hostname = 'testy-mc-host';
      final String password = 'secretty-dollface';
      final int port = 18021;

      final config.EslConfig conf = new config.EslConfig(
          hostname: hostname, password: password, port: port);

      expect(conf.hostname, equals(hostname));
      expect(conf.password, equals(password));
      expect(conf.port, equals(port));
    });
  });
}
