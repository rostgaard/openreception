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

library ors.reception;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/service-io.dart' as service;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-organization.dart' as controller;
import 'package:ors/controller/controller-reception.dart' as controller;
import 'package:ors/router/router-reception.dart' as router;

Future main(List<String> args) async {
  ///Init logging.
  final Logger log = Logger('server.message');
  Logger.root.level = config.receptionServer.log.level;
  Logger.root.onRecord.listen(config.receptionServer.log.onRecord);

  ///Handle argument parsing.
  ArgParser parser = ArgParser()
    ..addFlag('help', help: 'Output this help', negatable: false)
    ..addOption('filestore', abbr: 'f', help: 'Path to the filestore backend')
    ..addOption('httpport',
        abbr: 'p',
        defaultsTo: config.receptionServer.httpPort.toString(),
        help: 'The port the HTTP server listens on.')
    ..addOption('host',
        abbr: 'h',
        defaultsTo: config.receptionServer.externalHostName,
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

  final bool revisioning = parsedArgs['experimental-revisioning'];

  final receptionRevisionEngine = revisioning
      ? filestore.GitEngine(parsedArgs['filestore'] + '/reception')
      : null;

  final contactRevisionEngine = revisioning
      ? filestore.GitEngine(parsedArgs['filestore'] + '/contact')
      : null;

  final organizationRevisionEngine = revisioning
      ? filestore.GitEngine(parsedArgs['filestore'] + '/organization')
      : null;

  final service.Authentication _authService = service.Authentication(
      Uri.parse(parsedArgs['auth-uri']),
      config.userServer.serverToken,
      service.Client());

  final service.NotificationService _notification =
  service.NotificationService(Uri.parse(parsedArgs['notification-uri']),
      config.userServer.serverToken, service.Client());

  final filestore.Reception rStore =
  filestore.Reception(filepath + '/reception', receptionRevisionEngine);

  final filestore.Contact cStore = filestore.Contact(
      rStore, filepath + '/contact', contactRevisionEngine);

  final filestore.Organization oStore = filestore.Organization(
      cStore, rStore, filepath + '/organization', organizationRevisionEngine);

  final controller.Organization organization = controller.Organization(
      oStore,
      _notification,
      _authService);

  controller.Reception reception = controller.Reception(
      rStore,
      _notification,
      _authService);

  await (router.Reception(
      _authService, _notification, reception, organization)
      .listen(
      hostname: parsedArgs['host'],
      port: int.parse(parsedArgs['httpport'])));
  log.info('Ready to handle requests');
}