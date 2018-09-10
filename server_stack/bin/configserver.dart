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

library ors.configuration;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-config.dart' as controller;
import 'package:ors/router/router-config.dart' as router;

/// The OR-Stack configuration server. Provides a REST configuration interface.
Future main(List<String> args) async {
  ///Init logging.
  Logger.root.level = config.configserver.log.level;
  Logger.root.onRecord.listen(config.configserver.log.onRecord);
  Logger log = new Logger('configuration_server');

  ///Handle argument parsing.
  ArgParser parser = new ArgParser()
    ..addFlag('help', help: 'Output this help', negatable: false)
    ..addOption('httpport',
        abbr: 'p',
        defaultsTo: config.configserver.httpPort.toString(),
        help: 'The port the HTTP server listens on.')
    ..addOption('host',
        abbr: 'h',
        defaultsTo: config.configserver.externalHostName,
        help: 'The hostname or IP listen-address for the HTTP server');

  ArgResults parsedArgs = parser.parse(args);

  if (parsedArgs['help']) {
    print(parser.usage);
    exit(1);
  }

  /// Initialize and start the HTTP service
  controller.Config configController = new controller.Config();
  router.Config configRouter = new router.Config(configController);

  await configRouter.listen(
      hostname: parsedArgs['host'], port: int.parse(parsedArgs['httpport']));
  log.info('Ready to handle requests');
}
