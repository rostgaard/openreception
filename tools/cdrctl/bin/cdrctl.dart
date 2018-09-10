/*                 Copyright (C) 2016-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

library cdrctl;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../src/configuration.dart';
import '../src/dumpconfig-command.dart';
import '../src/logger.dart';
import '../src/report-command.dart';
import '../src/store-command.dart';
import 'config.dart';

Future main(List<String> args) async {
  final Logger log = new Logger();
  final Configuration cfg = await loadConfig(log, config);
  CommandRunner runner;

  final String description =
      '''Parse, store, summarize and query FreeSWITCH CDR files.

CDR entries and summaries are stored to local disk as JSON.
The raw CDR files are stored at Google Cloud Storage.
See more at https://github.com/Bitstackers/cdrctl.''';

  try {
    runner = new CommandRunner('cdrctl', description)
      ..addCommand(new DumpConfigCommand(args, cfg, log))
      ..addCommand(new ReportCommand(args, cfg, log))
      ..addCommand(new StoreCommand(args, cfg, log));

    await runner.run(args);
  } catch (error, stackTrace) {
    if (error is FormatException || error is UsageException) {
      log.error(error.message);
      if (runner != null) {
        log.info(runner.usage);
      }
      exit(64); // usage error.
    } else {
      log.error('cdrctl failed with ${error} - ${stackTrace}');
    }
  }
}

/**
 * Try to locate and load the configuration from one of the following paths:
 *
 *  1. cdrctl.json
 *  2. ~/cdrctl/cdrctl.json
 *  3. /etc/cdrctl/cdrctl.json
 *
 * The first one found is read and returned. If none is found, return [config].
 */
Future<Configuration> loadConfig(Logger log, Configuration config) async {
  final List<File> configFiles = new List<File>()
    ..addAll([
      new File('cdrctl.json'),
      new File('${Platform.environment['HOME']}/.cdrctl/cdrctl.json'),
      new File('/etc/cdrctl/cdrctl.json')
    ]);
  final File configFile =
      configFiles.firstWhere((File f) => f.existsSync(), orElse: () => null);

  if (configFile != null) {
    return new Configuration.fromJson(
        json.decode(configFile.readAsStringSync()));
  }

  return config;
}
