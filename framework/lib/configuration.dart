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

/// Common configuration models and parsing functions.
///
/// Currently unused in the stack, but is meant to be implemented as a
/// common method for configuring and launching processes for use with,
/// among others, tests.
library orf.config;

import 'package:args/args.dart';
import 'package:orf/src/constants/configuration.dart' as key;
import 'package:orf/validation.dart';

part 'package:orf/src/configuration/authentication_server.dart';
part 'package:orf/src/configuration/calendar_server.dart';
part 'package:orf/src/configuration/callflow_control.dart';
part 'package:orf/src/configuration/dialplan_server.dart';
part 'package:orf/src/configuration/esl.dart';
part 'package:orf/src/configuration/smtp.dart';
part 'package:orf/src/configuration/cdr_server.dart';
part 'package:orf/src/configuration/contact_server.dart';
part 'package:orf/src/configuration/user_server.dart';
part 'package:orf/src/configuration/message_server.dart';
part 'package:orf/src/configuration/message_dispatcher.dart';
part 'package:orf/src/configuration/notification_server.dart';
part 'package:orf/src/configuration/config_server.dart';

/// Standard configuration values, common among all server configurations.
class Configuration {
  final EslConfig esl;

  final CallFlowControl callflowService;
  final SmtpConfig smtp;

  final CdrServer cdrServer;
  final CalendarServer calendarServer;
  final ConfigServer configServer;
  final ContactServer contactServer;
  final DialplanServer dialplanServer;
  final MessageServer messageServer;
  final MessageDispatcher messageDispatcher;
  final NotificationServer notificationServer;
  final AuthServer authServer;

  /// A list of telephone numbers that identify this system.
  final List<String> myIdentifiers = const [];

  /// Whether or not to hide the caller telephone number.
  final bool hideInboundCallerId = true;
  final String externalHostname;

  /// May be 'en' or 'da'
  final String systemLanguage = 'en';
  final String filestorePath;
  final bool experimentalRevisioning = false;

  const Configuration(
      this.esl,
      this.smtp,
      this.externalHostname,
      this.filestorePath,
      this.authServer,
      this.callflowService,
      this.calendarServer,
      this.configServer,
      this.contactServer,
      this.cdrServer,
      this.dialplanServer,
      this.messageDispatcher,
      this.messageServer,
      this.notificationServer);

  /// Default constructor.
  const Configuration.defaults()
      : this.esl = const EslConfig(),
        this.smtp = const SmtpConfig(),
        this.externalHostname = 'localhost',
        this.filestorePath = '',
        this.authServer = const AuthServer(),
        this.callflowService = const CallFlowControl(),
        this.calendarServer = const CalendarServer(),
        this.configServer = const ConfigServer(),
        this.contactServer = const ContactServer(),
        this.cdrServer = const CdrServer(),
        this.dialplanServer = const DialplanServer(),
        this.messageDispatcher = const MessageDispatcher(),
        this.messageServer = const MessageServer(),
        this.notificationServer = const NotificationServer();

  factory Configuration.fromJson(Map map) {
    final CalendarServer calendarServer = map.containsKey(key.calendarServer)
        ? new CalendarServer.fromJson(map[key.calendarServer])
        : const CalendarServer();

    final ConfigServer configServer = map.containsKey(key.configServer)
        ? new ConfigServer.fromJson(map[key.configServer])
        : const ConfigServer();

    final ContactServer contactServer = map.containsKey(key.contactServer)
        ? new ContactServer.fromJson(map[key.contactServer])
        : const ContactServer();

    final DialplanServer dialplanServer = map.containsKey(key.dialplanServer)
        ? new DialplanServer.fromJson(map[key.dialplanServer])
        : const DialplanServer();

    final MessageServer messageServer = map.containsKey(key.messageServer)
        ? new MessageServer.fromJson(map[key.messageServer])
        : const MessageServer();

    final MessageDispatcher messageDispatcher =
        map.containsKey(key.messageDispatcher)
            ? new MessageDispatcher.fromJson(map[key.messageDispatcher])
            : const MessageDispatcher();

    final NotificationServer notificationServer =
        map.containsKey(key.notificationServer)
            ? new NotificationServer.fromJson(map[key.notificationServer])
            : const NotificationServer();

    final AuthServer authServer = map.containsKey(key.authServer)
        ? new AuthServer.fromJson(map[key.authServer])
        : const AuthServer();

    final EslConfig esl = map.containsKey(key.esl)
        ? new EslConfig.fromJson(map[key.esl])
        : const EslConfig();

    final CdrServer cdr = map.containsKey(key.cdr)
        ? new CdrServer.fromJson(map[key.cdr])
        : const CdrServer();

    final CallFlowControl callflow = map.containsKey(key.callflow)
        ? new CallFlowControl.fromJson(map[key.callflow])
        : const CallFlowControl();

    final SmtpConfig smtp = map.containsKey(key.smtp)
        ? new SmtpConfig.fromJson(map[key.smtp])
        : const SmtpConfig();

    final String exthost = map.containsKey(key.externalHostname)
        ? map[key.externalHostname]
        : 'localhost';

    final String datastorePath =
        map.containsKey(key.datastorePath) ? map[key.datastorePath] : '';

    return new Configuration(
        esl,
        smtp,
        exthost,
        datastorePath,
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
  }

  final String serverToken = 'veeerysecret';

  Map<String, dynamic> toJson() => new Map.unmodifiable({
        key.externalHostname: externalHostname,
        key.datastorePath: filestorePath,
        key.serverToken: serverToken,
        key.esl: esl.toJson(),
        key.smtp: smtp.toJson(),
        key.authServer: authServer.toJson(),
        key.callflow: callflowService.toJson(),
        key.calendarServer: calendarServer.toJson(),
        key.cdr: cdrServer.toJson(),
        key.contactServer: contactServer.toJson(),
        key.configServer: configServer.toJson(),
        key.dialplanServer: dialplanServer.toJson(),
        key.messageDispatcher: messageDispatcher.toJson(),
        key.messageServer: messageServer.toJson(),
        key.notificationServer: notificationServer.toJson()
      });
}

class _ModifiableConfiguration implements Configuration {
  EslConfig esl;

  CallFlowControl callflowService;
  SmtpConfig smtp;

  CdrServer cdrServer;
  CalendarServer calendarServer;
  ConfigServer configServer;
  ContactServer contactServer;
  DialplanServer dialplanServer;
  MessageServer messageServer;
  MessageDispatcher messageDispatcher;
  NotificationServer notificationServer;
  AuthServer authServer;

  /// A list of telephone numbers that identify this system.
  List<String> myIdentifiers = const [];

  /// Whether or not to hide the caller telephone number.
  bool hideInboundCallerId = true;
  String externalHostname;

  /// May be 'en' or 'da'
  String systemLanguage = 'en';
  String filestorePath;
  bool experimentalRevisioning = false;
}

dynamic _coalesce(Iterable<dynamic> values) =>
    values.firstWhere((value) => value != null);

String authServerUri(Configuration config) =>
    'http://${config.externalHostname}:${config.authServer.port}';

String notificationServerUri(Configuration config) =>
    'http://${config.externalHostname}:${config.notificationServer.port}';
