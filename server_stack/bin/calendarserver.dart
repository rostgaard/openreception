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

/// The OR-Stack calendar server. Provides a REST calendar interface.
library ors.calendar;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:orf/filestore.dart' as fileStore;
import 'package:orf/service-io.dart' as service;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-calendar.dart' as controller;
import 'package:ors/router/router-calendar.dart' as router;

Future main(List<String> args) async {
  ///Init logging.
  Logger.root.level = config.calendarServer.log.level;
  Logger.root.onRecord.listen(config.calendarServer.log.onRecord);
  Logger log = Logger('calendarserver');

  ///Handle argument parsing.
  ArgParser parser = ArgParser()
    ..addFlag('help', help: 'Output this help', negatable: false)
    ..addOption('filestore', abbr: 'f', help: 'Path to the filestore backend')
    ..addOption('httpport',
        abbr: 'p',
        defaultsTo: config.calendarServer.httpPort.toString(),
        help: 'The port the HTTP server listens on.')
    ..addOption('host',
        defaultsTo: config.calendarServer.externalHostName,
        help: 'The hostname or IP listen-address for the HTTP server')
    ..addOption('auth-uri',
        defaultsTo: config.authServer.externalUri.toString(),
        help: 'The uri of the authentication server')
    ..addOption('notification-uri',
        defaultsTo: config.notificationServer.externalUri.toString(),
        help: 'The uri of the notification server')
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
    port = int.parse(parsedArgs['httpport']);
    if (port < 1 || port > 65535) {
      throw FormatException();
    }
  } on FormatException {
    stderr.writeln('Bad port argument: ${parsedArgs['httpport']}');
    print('');
    print(parser.usage);
    exit(1);
  }

  final bool revisioning = parsedArgs['experimental-revisioning'];

  fileStore.GitEngine contactRevisionEngine = revisioning
      ? fileStore.GitEngine(parsedArgs['filestore'] + '/contact')
      : null;
  fileStore.GitEngine receptionRevisionEngine = revisioning
      ? fileStore.GitEngine(parsedArgs['filestore'] + '/reception')
      : null;

  final service.Authentication _authentication = service.Authentication(
      Uri.parse(parsedArgs['auth-uri']),
      config.calendarServer.serverToken,
      service.Client());

  final service.NotificationService _notification =
      service.NotificationService(Uri.parse(parsedArgs['notification-uri']),
          config.calendarServer.serverToken, service.Client());

  final fileStore.Reception rStore = fileStore.Reception(
      parsedArgs['filestore'] + '/reception', receptionRevisionEngine);

  final fileStore.Contact cStore = fileStore.Contact(
      rStore, parsedArgs['filestore'] + '/contact', contactRevisionEngine);

  final controller.Calendar _calendarController = controller.Calendar(
      cStore,
      rStore,
      _authentication,
      _notification);

  final router.Calendar calendarRouter =
  router.Calendar(_authentication, _notification, _calendarController);

  await calendarRouter.listen(port: port, hostname: parsedArgs['host']);

  log.info('Ready to handle requests');
}
