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
import 'dart:convert';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:ors/router/router-authentication.dart' as router;
import 'package:ors/token_watcher.dart' as watcher;
import 'package:ors/token_vault.dart';
import 'package:ors/configuration.dart';
import 'package:orf/configuration.dart' as conf;

Future main(List<String> args) async {
  //Init logging.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);
  final Logger log = new Logger('authserver');

  //Handle argument parsing.
  final ArgParser parser = conf.authServerArgParser();

  final ArgResults parsedArgs = parser.parse(args);
  final List<String> configFilePaths = parsedArgs['config-file'] != null
      ? [parsedArgs['config-file']]
      : defaultConfigPaths;

  Map loadedConf = loadConfig(paths: configFilePaths);
  Map mergedConf = conf.mergeAuthArgResults(parsedArgs, loadedConf);

  if (parsedArgs['help']) {
    print(parser.usage);
    exit(1);
  }

  final config = new conf.Configuration.fromJson(mergedConf);

  if (config.filestorePath.isEmpty) {
    print('Filestore path is required');
    print(parser.usage);
    exit(1);
  }

  watcher.setup();
  await vault.loadFromDirectory(config.authServer.tokenDir);

  // Install "reload-token" mechanism.
  ProcessSignal.SIGHUP.watch().listen((_) async {
    log.info('SIGHUP caught. Reloading tokens');
    await vault.loadFromDirectory(parsedArgs['servertokendir']);
    log.info('Reloaded tokens from disk');
  });

  await (new router.Authentication()).start(config);
  log.info('Ready to handle requests');
}
