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

///The OR-Stack authentication server. Provides a REST authentication interface.
library ors.authentication;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:ors/configuration.dart';
import 'package:ors/router/router-authentication.dart' as router;
import 'package:ors/token_vault.dart';
import 'package:ors/token_watcher.dart';


Future main(List<String> args) async {
  //Init logging.
  Logger.root.level = config.authServer.log.level;
  Logger.root.onRecord.listen(config.authServer.log.onRecord);
  final Logger log = new Logger('authserver');

  //Handle argument parsing.
  final ArgParser parser = new ArgParser()
    ..addFlag('help', help: 'Output this help', negatable: false)
    ..addOption('filestore', abbr: 'f', help: 'Path to the filestore backend')
    ..addOption('httpport',
        abbr: 'p',
        defaultsTo: config.authServer.httpPort.toString(),
        help: 'The port the HTTP server listens on.')
    ..addOption('host',
        abbr: 'h',
        defaultsTo: config.authServer.externalHostName,
        help: 'The hostname or IP listen-address for the HTTP server')
    ..addOption('servertokendir',
        abbr: 'd',
        help: 'Load predefined tokens from this path.',
        defaultsTo: config.authServer.serverTokendir);

  final ArgResults parsedArgs = parser.parse(args);

  if (parsedArgs.wasParsed('help')) {
    print(parser.usage);
    exit(1);
  }

  if (parsedArgs['filestore'] == null) {
    print('Filestore path is required');
    print(parser.usage);
    exit(1);
  }

  final Map<String,dynamic> context = <String,dynamic>{
    'servertokendir' : parsedArgs['servertokendir'],
    'filestore' : parsedArgs['filestore']
  };

  final String host = parsedArgs['host'].toString();
  final int port = int.parse(parsedArgs['httpport'].toString());


  final vault = TokenVault();

  final tokenWatcher = TokenWatcher(vault);
  final filestore.User _userStore = new filestore.User(parsedArgs['filestore'] + '/user');


  vault.loadFromDirectory(parsedArgs['servertokendir']);

  // Install "reload-token" mechanism.
  ProcessSignal.sighup.watch().listen((_) async {
    log.info('SIGHUP caught. Reloading tokens');
    vault.loadFromDirectory(parsedArgs['servertokendir']);
    log.info('Reloaded tokens from disk');
  });

  await (router.Authentication(vault, _userStore).start(
      hostname: host, port: port));
  log.info('Ready to handle requests');
}
