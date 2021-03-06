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

library ors.cdr;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:orf/service-io.dart' as service;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/router/router-cdr.dart' as router;

/**
 * CDR server.
 */
Future main(List<String> args) async {
  ///Init logging.
  Logger.root.level = config.cdrServer.log.level;
  Logger.root.onRecord.listen(config.cdrServer.log.onRecord);
  Logger log = new Logger('cdrserver');

  final ArgParser parser = new ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Output this help')
    ..addOption('auth-uri',
        defaultsTo: config.authServer.externalUri.toString(),
        help: 'The uri of the authentication server')
    ..addOption('host',
        defaultsTo: config.calendarServer.externalHostName,
        help: 'The hostname or IP listen-address for the HTTP server')
    ..addOption('port',
        abbr: 'p',
        defaultsTo: config.cdrServer.httpPort.toString(),
        help: 'The port the HTTP server listens on.');
  final ArgResults parsedArgs = parser.parse(args);

  if (parsedArgs['help']) {
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

  final service.Authentication authService = new service.Authentication(
      Uri.parse(parsedArgs['auth-uri']),
      config.userServer.serverToken,
      new service.Client());

  await router.start(authService, port: port, hostname: parsedArgs['host']);

  log.info('Ready to handle requests');
}
