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

library openreception.cdr_server;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';

import '../lib/cdr_server/configuration.dart' as json;
import '../lib/configuration.dart';
import '../lib/cdr_server/database.dart';
import 'package:openreception_framework/httpserver.dart' as http;
import '../lib/cdr_server/router.dart' as router;


Logger log = new Logger ('CDRServer');
ArgResults parsedArgs;
ArgParser  parser = new ArgParser();

void main(List<String> args) {
  ///Init logging.
  Logger.root.level = Configuration.cdrServer.log.level;
  Logger.root.onRecord.listen(Configuration.cdrServer.log.onRecord);

  try {
    Directory.current = dirname(Platform.script.toFilePath());

    registerAndParseCommandlineArguments(args);

    if(showHelp()) {
      print(parser.usage);
    } else {
      json.config = new json.Configuration(parsedArgs);
      json.config.whenLoaded()
        .then((_) => startDatabase())
        .then((_) => http.start(json.config.httpport, router.setup))
        .catchError(log.shout);
    }
  } catch(error, stackTrace) {
    log.shout (error, stackTrace);
  }
}

void registerAndParseCommandlineArguments(List<String> arguments) {
  parser.addFlag  ('help', abbr: 'h', help: 'Output this help');
  parser.addOption('configfile',      help: 'The JSON configuration file. Defaults to config.json');
  parser.addOption('httpport',        help: 'The port the HTTP server listens on.  Defaults to 8080');
  parser.addOption('dbuser',          help: 'The database user');
  parser.addOption('dbpassword',      help: 'The database password');
  parser.addOption('dbhost',          help: 'The database host. Defaults to localhost');
  parser.addOption('dbport',          help: 'The database port. Defaults to 5432');
  parser.addOption('dbname',          help: 'The database name');

  parsedArgs = parser.parse(arguments);
}

bool showHelp() => parsedArgs['help'];
