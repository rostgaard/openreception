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

/// The OR-Stack datastore server. Provides a REST calendar interface.
library ors.datastore;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:orf/dialplan_tools.dart' as dialplanTools;
import 'package:orf/filestore.dart' as fileStore;
import 'package:orf/service-io.dart' as service;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-agent_statistics.dart' as controller;
import 'package:ors/controller/controller-calendar.dart' as controller;
import 'package:ors/controller/controller-client_notifier.dart' as controller;
import 'package:ors/controller/controller-contact.dart' as controller;
import 'package:ors/controller/controller-ivr.dart' as controller;
import 'package:ors/controller/controller-organization.dart' as controller;
import 'package:ors/controller/controller-peer_account.dart' as controller;
import 'package:ors/controller/controller-reception.dart' as controller;
import 'package:ors/controller/controller-reception_dialplan.dart'
    as controller;
import 'package:ors/model.dart' as model;
import 'package:ors/router/router-calendar.dart' as router;
import 'package:ors/router/router-contact.dart' as router;
import 'package:ors/router/router-datastore.dart' as router;
import 'package:ors/router/router-dialplan.dart' as router;
import 'package:ors/router/router-reception.dart' as router;

Future main(List<String> args) async {
  ///Init logging.
  Logger.root.level = config.calendarServer.log.level;
  Logger.root.onRecord.listen(config.calendarServer.log.onRecord);
  Logger _log = new Logger('datastoreserver');

  ///Handle argument parsing.
  ArgParser parser = new ArgParser()
    ..addFlag('help', help: 'Output this help', negatable: false)
    ..addOption('filestore', abbr: 'f', help: 'Path to the filestore backend')
    ..addOption('port',
        abbr: 'p',
        defaultsTo: config.calendarServer.httpPort.toString(),
        help: 'The port the HTTP server listens on.')
    ..addOption('host',
        abbr: 'h',
        defaultsTo: config.calendarServer.externalHostName,
        help: 'The hostname or IP listen-address for the HTTP server')
    ..addOption('auth-uri',
        defaultsTo: config.authServer.externalUri.toString(),
        help: 'The uri of the authentication server')
    ..addOption('notification-uri',
        defaultsTo: config.notificationServer.externalUri.toString(),
        help: 'The uri of the notification server')
    ..addOption('playback-prefix',
        help: ''
            'Defaults to ${config.dialplanserver.playbackPrefix}',
        defaultsTo: config.dialplanserver.playbackPrefix)
    ..addOption('freeswitch-conf-path',
        help: 'Path to the FreeSWITCH conf directory.'
            'Defaults to ${config.dialplanserver.freeswitchConfPath}',
        defaultsTo: config.dialplanserver.freeswitchConfPath)
    ..addOption('esl-hostname',
        defaultsTo: config.callFlowControl.eslConfig.hostname,
        help: 'The hostname of the ESL server')
    ..addOption('esl-password',
        defaultsTo: config.callFlowControl.eslConfig.password,
        help: 'The password for the ESL server')
    ..addOption('esl-port',
        defaultsTo: config.callFlowControl.eslConfig.port.toString(),
        help: 'The port of the ESL server')
    ..addFlag('experimental-revisioning',
        defaultsTo: false,
        help: 'Enable or disable experimental Git revisioning on this server');

  ArgResults parsedArgs = parser.parse(args);

  if (parsedArgs['help']) {
    print(parser.usage);
    exit(1);
  }

  final String filepath = parsedArgs['filestore'];
  if (filepath == null || filepath.isEmpty) {
    stderr.writeln('Filestore path is required');
    print('');
    print(parser.usage);
    exit(1);
  }

  int port;
  try {
    port = int.parse(parsedArgs['port']);
    if (port < 1 || port > 65535) {
      throw new FormatException();
    }
  } on FormatException {
    stderr.writeln('Bad port argument: ${parsedArgs['port']}');
    print('');
    print(parser.usage);
    exit(1);
  }

  final bool revisioning = parsedArgs['experimental-revisioning'];

  final String playbackPrefix = parsedArgs['playback-prefix'];
  final String fsConfPath = parsedArgs['freeswitch-conf-path'];

  final EslConfig eslConfig = new EslConfig(
      hostname: parsedArgs['esl-hostname'],
      password: parsedArgs['esl-password'],
      port: int.parse(parsedArgs['esl-port']));

  final fileStore.GitEngine revisionEngine =
      revisioning ? new fileStore.GitEngine(filepath) : null;

  final fileStore.DataStore dataStore =
      new fileStore.DataStore(filepath, revisionEngine);

  /// Setup dialplan tools.
  final dialplanTools.DialplanCompiler compiler =
      new dialplanTools.DialplanCompiler(new dialplanTools.DialplanCompilerOpts(
          goLive: config.dialplanserver.goLive,
          greetingDir: playbackPrefix,
          testNumber: config.dialplanserver.testNumber,
          testEmail: config.dialplanserver.testEmail,
          callerIdName: config.callFlowControl.callerIdName,
          callerIdNumber: config.callFlowControl.callerIdNumber));

  _log.info('Dialplan tools are ${compiler.option.goLive ? 'live ' : 'NOT live '
                'diverting all voicemails to ${compiler.option.testEmail} and directing '
                'all calls to ${compiler.option.testNumber}'}');
  _log.fine('Deploying generated xml files to $fsConfPath subdirs');

  /// Service clients.
  final service.Authentication authService = new service.Authentication(
      Uri.parse(parsedArgs['auth-uri']),
      config.userServer.serverToken,
      new service.Client());

  final service.NotificationService notificationService =
      new service.NotificationService(Uri.parse(parsedArgs['notification-uri']),
          config.userServer.serverToken, new service.Client());

  final controller.Calendar calendarController = new controller.Calendar(
      dataStore.contactStore,
      dataStore.receptionStore,
      authService,
      notificationService
      );

  controller.Contact contactController = new controller.Contact(
      dataStore.contactStore,
      notificationService,
      authService);

  final controller.Organization organization = new controller.Organization(
      dataStore.organizationStore,
      notificationService,
      authService);

  controller.Reception reception = new controller.Reception(
      dataStore.receptionStore,
      notificationService,
      authService);

  // Model classes.
  final model.UserStatusList userStatus = new model.UserStatusList();

  /// Create an anonymous client notifier.
  new controller.ClientNotifier(notificationService, userStatus.onChange);

  final controller.Ivr ivrHandler =
      new controller.Ivr(dataStore.ivrStore, compiler, authService, fsConfPath);
  final controller.ReceptionDialplan receptionDialplanHandler =
      new controller.ReceptionDialplan(
          dataStore.receptionDialplanStore,
          dataStore.receptionStore,
          authService,
          compiler,
          ivrHandler,
          fsConfPath,
          eslConfig);

  final controller.PeerAccount peerAccountHandler =
      new controller.PeerAccount(dataStore.userStore, compiler, fsConfPath);

  /// Routers
  final router.Calendar calendarRouter =
      new router.Calendar (authService, notificationService, calendarController);

  final router.Contact contactRouter =
      new router.Contact(authService, notificationService, contactController);

  final receptionRouter = router.ReceptionChannel();

  final dialplanRouter = new router.Dialplan(
      authService, ivrHandler, peerAccountHandler, receptionDialplanHandler);

  await router.Datastore().start(null,
      hostname: parsedArgs['host'], port: port);

  _log.info('Ready to handle requests');
}
