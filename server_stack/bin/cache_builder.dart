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
 * Builds a static file cache of gzipped filestore objects. Unused in the
 * current stack, but serves as example code for a basic caching frontend.
 */
library ors.cache_builder;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/gzip_cache.dart' as gzip_cache;
import 'package:orf/model.dart' as model;
import 'package:ors/configuration.dart';
import 'package:ors/model.dart' as model;

ArgResults _parsedArgs;
ArgParser _parser = new ArgParser();
Logger _log = new Logger('cache_server');

Future main(List<String> args) async {
  ///Init logging.
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen(config.calendarServer.log.onRecord);

  /// Code block that may be used by a caching service to respond to
  /// datastore changes.

  // final service.WebSocketClient ws = new service.WebSocketClient();
  // final service.NotificationSocket notification =
  //     new service.NotificationSocket(await ws.connect(Uri.parse(
  //         config.notificationServer.notificationUri.toString() +
  //             '?token=' +
  //             config.configserver.serverToken)));
  //
  // notification.eventStream.listen(print);

  ///Handle argument parsing.
  ArgParser parser = new ArgParser()
    ..addFlag('help', help: 'Output this help', negatable: false)
    ..addOption('filestore', abbr: 'f', help: 'Path to the filestore directory')
    ..addOption('notification-uri',
        defaultsTo: config.notificationServer.externalUri.toString(),
        help: 'The uri of the notification server');

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

  /// Initialize filestores
  final filestore.Reception rStore =
      new filestore.Reception(filepath + '/reception');
  final filestore.Contact cStore =
      new filestore.Contact(rStore, filepath + '/contact');
  final filestore.User userStore =
      new filestore.User(parsedArgs['filestore'] + '/user');
  final filestore.Ivr ivrStore = new filestore.Ivr(filepath + '/ivr');
  final filestore.ReceptionDialplan dpStore =
      new filestore.ReceptionDialplan(filepath + '/dialplan');
  final filestore.Message messageStore =
      new filestore.Message(filepath + '/message');
  final filestore.Organization oStore =
      new filestore.Organization(cStore, rStore, filepath + '/organization');

  /// Setup output directory
  Directory tmpDir = new Directory('/tmp/gzip-cache');
  print('Outputting cached object to directory: ' + tmpDir.path);

  /// Intialize gzip caches.
  gzip_cache.CalendarCache calendarCache = new gzip_cache.CalendarCache(
      cStore.calendarStore, rStore.calendarStore, []);

  gzip_cache.ReceptionCache receptionCache =
      new gzip_cache.ReceptionCache(rStore, rStore.onReceptionChange);

  gzip_cache.ContactCache contactCache = new gzip_cache.ContactCache(
      cStore,
      cStore.onContactChange,
      cStore.onReceptionDataChange,
      rStore.onReceptionChange,
      oStore.onOrganizationChange);

  gzip_cache.MessageCache messageCache =
      new gzip_cache.MessageCache(messageStore, messageStore.changeStream);

  gzip_cache.DialplanCache dialplanCache =
      new gzip_cache.DialplanCache(dpStore, dpStore.onChange);

  gzip_cache.IvrMenuCache ivrMenuCache =
      new gzip_cache.IvrMenuCache(ivrStore, ivrStore.onChange);

  gzip_cache.UserCache userCache =
      new gzip_cache.UserCache(userStore, userStore.onUserChange);

  /// Write the gzipped objects to [tmpDir]
  await buildContactObjects(cStore, contactCache, calendarCache, tmpDir.path);
  await buildMessageObjects(messageStore, messageCache, tmpDir.path);
  await buildReceptionObjects(
      rStore, receptionCache, calendarCache, tmpDir.path);
  await buildDialplanObjects(dpStore, dialplanCache, tmpDir.path);
  await buildIvrMenuObjects(ivrStore, ivrMenuCache, tmpDir.path);
  await buildUserObjects(userStore, userCache, tmpDir.path);
}

/**
 * Builds a gzipped version of all the [model.Message] object
 * in [messageStore].
 */
Future buildMessageObjects(filestore.Message messageStore,
    gzip_cache.MessageCache messageCache, String path,
    {int daysToFetch: 210}) async {
  new Directory('$path/message').createSync();
  final DateTime today = new DateTime.now();
  final DateTime cutOffDate = today.subtract(new Duration(days: daysToFetch));

  DateTime dayToFetch = today;
  await Future.doWhile(() async {
    final List<int> bytes = await messageCache.list(dayToFetch);

    if (!gzip_cache.isEmptyGzipList(bytes)) {
      final dayString = dayToFetch.toIso8601String().split('T').first;

      File listingFile = new File('$path/message/$dayString');
      if (!listingFile.existsSync()) {
        listingFile.writeAsBytesSync(bytes);
        _log.info('Writing file ${listingFile.path}');
      }
    }

    dayToFetch = dayToFetch.subtract(new Duration(days: 1));

    return dayToFetch.isAfter(cutOffDate);
  });
}

/**
 * Builds a gzipped version of all the [model.BaseContact] object
 * in [cStore]. Also builds associated [model.CalendarEntry] objects and
 * a gzipped list of all the [model.ReceptionAttributes] of the contact.
 */
Future buildContactObjects(
    filestore.Contact cStore,
    gzip_cache.ContactCache contactCache,
    gzip_cache.CalendarCache calendarCache,
    String path) async {
  await Future.forEach(await cStore.list(), (cRef) async {
    final owner = new model.OwningContact(cRef.id);

    new Directory('$path/contact/${owner.id}').createSync(recursive: true);

    File dataFile = new File('$path/contact/${owner.id}/data');
    if (!dataFile.existsSync()) {
      final bytes = await contactCache.get(cRef.id);

      dataFile.writeAsBytesSync(bytes);
      _log.info('Writing file ${dataFile.path}');
    }

    final rRefs = await cStore.receptions(cRef.id);

    List recs = [];
    await Future.forEach(rRefs, (rRef) async {
      // new Directory('${tmpDir.path}/contact/${owner.id}/receptions')
      //     .createSync();

      recs.add(await cStore.data(cRef.id, rRef.id));
    });
    File rFile = new File('$path/contact/${owner.id}/receptions');
    final bytes = gzip_cache.serializeAndCompressObject(recs);
    if (gzip_cache.isEmptyGzipList(bytes)) {
      rFile.writeAsBytesSync(bytes);
      _log.info('Writing file ${rFile.path}');
    }

    File f = new File('$path/contact/${owner.id}/calendar');
    if (!f.existsSync()) {
      final bytes = await calendarCache.list(owner);
      if (bytes != gzip_cache.emptyGzipList) {
        f.writeAsBytesSync(bytes);
        _log.info('Writing file ${f.path}');
      }
    }
  });
}

/**
 * Builds a gzipped version of all the [model.Reception] object
 * in [rStore]. Also builds associated [model.CalendarEntry] objects.
 */
Future buildReceptionObjects(
    filestore.Reception rStore,
    gzip_cache.ReceptionCache receptionCache,
    gzip_cache.CalendarCache calendarCache,
    String path) async {
  await Future.forEach(await rStore.list(), (rRef) async {
    /// Fetch calendar entries
    final owner = new model.OwningReception(rRef.id);

    new Directory('$path/reception/${owner.id}').createSync(recursive: true);

    File dataFile = new File('$path/reception/${owner.id}/data');
    if (!dataFile.existsSync()) {
      final bytes = await receptionCache.get(rRef.id);

      dataFile.writeAsBytesSync(bytes);
      _log.info('Writing file ${dataFile.path}');
    }

    File calendarFile = new File('$path/reception/${owner.id}/calendar');
    if (!calendarFile.existsSync()) {
      final bytes = await calendarCache.list(owner);
      if (bytes != gzip_cache.emptyGzipList) {
        calendarFile.writeAsBytesSync(bytes);
        _log.info('Writing file ${calendarFile.path}');
      }
    }
  });
}

/**
 * Builds a gzipped version of all the [model.ReceptionDialplan] object
 * in [dpStore].
 */
Future buildDialplanObjects(filestore.ReceptionDialplan dpStore,
    gzip_cache.DialplanCache dialplanCache, String path) async {
  await Future.forEach(await dpStore.list(),
      (model.ReceptionDialplan dp) async {
    new Directory('$path/dialplan').createSync(recursive: true);

    File dataFile = new File('$path/dialplan/${dp.extension}');
    if (!dataFile.existsSync()) {
      final bytes = await dialplanCache.get(dp.extension);

      dataFile.writeAsBytesSync(bytes);
      _log.info('Writing file ${dataFile.path}');
    }
  });
}

/**
 * Builds a gzipped version of all the [model.IvrMenu] object in [ivrStore].
 */
Future buildIvrMenuObjects(filestore.Ivr ivrStore,
    gzip_cache.IvrMenuCache ivrCache, String path) async {
  await Future.forEach(await ivrStore.list(), (model.IvrMenu menu) async {
    new Directory('$path/ivr').createSync(recursive: true);

    File dataFile = new File('$path/ivr/${menu.name}');
    if (!dataFile.existsSync()) {
      final bytes = await ivrCache.get(menu.name);

      dataFile.writeAsBytesSync(bytes);
      _log.info('Writing file ${dataFile.path}');
    }
  });
}

/**
 * Builds a gzipped version of all the [model.User] object in [userStore].
 */
Future buildUserObjects(filestore.User userStore,
    gzip_cache.UserCache userCache, String path) async {
  await Future.forEach(await userStore.list(), (model.UserReference user) async {
    new Directory('$path/user').createSync(recursive: true);

    File dataFile = new File('$path/user/${user.id}');
    if (!dataFile.existsSync()) {
      final bytes = await userCache.get(user.id);

      dataFile.writeAsBytesSync(bytes);
      _log.info('Writing file ${dataFile.path}');
    }
  });
}
