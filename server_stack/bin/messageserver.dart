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

library ors.message;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/service-io.dart' as service;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-message.dart' as controller;
import 'package:ors/router/router-message.dart' as router;

Future main(List<String> args) async {
  ///Init logging. Inherit standard values.
  Logger.root.level = config.messageServer.log.level;
  Logger.root.onRecord.listen(config.messageServer.log.onRecord);
  Logger log = new Logger('MessageServer');

  final ArgParser parser = new ArgParser()
    ..addFlag('help', help: 'Output this help', negatable: false)
    ..addOption('filestore', abbr: 'f', help: 'Path to the filestore backend')
    ..addOption('httpport',
        abbr: 'p',
        defaultsTo: config.messageServer.httpPort.toString(),
        help: 'The port the HTTP server listens on.')
    ..addOption('host',
        defaultsTo: config.messageServer.externalHostName,
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

  final ArgResults parsedArgs = parser.parse(args);

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

  final revisionEngine = revisioning
      ? new filestore.GitEngine(parsedArgs['filestore'] + '/message')
      : null;

  final service.Authentication _authService = new service.Authentication(
      Uri.parse(parsedArgs['auth-uri']),
      config.userServer.serverToken,
      new service.Client());

  final service.NotificationService _notification =
      new service.NotificationService(Uri.parse(parsedArgs['notification-uri']),
          config.userServer.serverToken, new service.Client());

  final filestore.Message _messageStore =
      new filestore.Message(filepath + '/message', revisionEngine);

  await _messageStore.rebuildSecondaryIndexes();

  final filestore.MessageQueue _messageQueue =
      new filestore.MessageQueue(filepath + '/message_queue');

  final controller.Message msgController = new controller.Message(
      _messageStore, _messageQueue, _authService, _notification);

  await (new router.Message(_authService, _notification, msgController)).listen(
      hostname: parsedArgs['host'], port: int.parse(parsedArgs['httpport']));
  log.info('Ready to handle requests');
}
