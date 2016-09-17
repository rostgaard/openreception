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

/**
 * The OR-Stack calendar server. Provides a REST calendar interface.
 */
library ors.calendar;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/gzip_cache.dart' as gzip_cache;
import 'package:orf/service-io.dart' as service;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:orf/configuration.dart';

import 'package:ors/controller/controller-calendar.dart' as controller;

import 'package:ors/router/router-calendar.dart' as router;

ArgResults _parsedArgs;
ArgParser _parser = new ArgParser();

Future main(List<String> args) async {
  ///Init logging.
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);
  Logger log = new Logger('calendarserver');

  //Handle argument parsing.
  final ArgParser parser = calendarServerArgParser();

  final ArgResults parsed = parser.parse(args);
  final List<String> configFilePaths = parsed['config-file'] != null
      ? [parsed['config-file']]
      : defaultConfigPaths;

  Map loadedConf = loadConfig(paths: configFilePaths);
  Map mergedConf = mergeConfigArgResults(parsed, loadedConf);

  if (parsed['help']) {
    print(parser.usage);
    exit(1);
  }

  final config = new Configuration.fromJson(mergedConf);

  if (config.filestorePath.isEmpty) {
    stderr.writeln('Filestore path is required');
    print('');
    print(parser.usage);
    exit(1);
  }

  filestore.GitEngine contactRevisionEngine = config.experimentalRevisioning
      ? new filestore.GitEngine(config.filestorePath + '/contact')
      : null;

  filestore.GitEngine receptionRevisionEngine = config.experimentalRevisioning
      ? new filestore.GitEngine(config.filestorePath + '/reception')
      : null;

  final service.Authentication _authentication = new service.Authentication(
      Uri.parse(authServerUri(config)),
      config.serverToken,
      new service.Client());

  final service.NotificationService _notification =
      new service.NotificationService(Uri.parse(notificationServerUri(config)),
          config.serverToken, new service.Client());

  final filestore.Reception rStore = new filestore.Reception(
      config.filestorePath + '/reception', receptionRevisionEngine);

  final filestore.Contact cStore = new filestore.Contact(
      rStore, config.filestorePath + '/contact', contactRevisionEngine);

  final controller.Calendar _calendarController = new controller.Calendar(
      cStore,
      rStore,
      _authentication,
      _notification,
      new gzip_cache.CalendarCache(cStore.calendarStore, rStore.calendarStore, [
        cStore.calendarStore.changeStream,
        rStore.calendarStore.changeStream,
      ]));

  final router.Calendar calendarRouter =
      new router.Calendar(_authentication, _notification, _calendarController);

  await calendarRouter.listen(config);

  log.info('Ready to handle requests');
}
