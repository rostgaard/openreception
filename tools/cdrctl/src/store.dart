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

library store;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis/storage/v1.dart' as blob;
import 'package:orf/model.dart';
import 'package:path/path.dart' as path;

import 'configuration.dart';
import 'google.dart';
import 'logger.dart';
import 'summary.dart';

/**
 * Upload [file] to Google Cloud Storage.
 *
 * Completes with an [Object] on success. Everything else is a failure.
 */
Future<dynamic> bUpload(File file, Google g, Configuration config) {
  final blob.Media media = new blob.Media(file.openRead(), file.lengthSync(),
      contentType: 'application/json');
  final blob.Object object = new blob.Object()
    ..name = path.basename(file.path).split('____').last;

  return g.blob.objects.insert(object, config.bucket, uploadMedia: media);
}

/**
 * Delete [file].
 *
 * Logs success to info and failure to severe.
 *
 * Does not throw.
 */
void delete(File file, Logger log) {
  try {
    file.deleteSync();
    log.info('store.delete() deleted local file ${file.path}');
  } catch (error) {
    log.error('store.delete() could not delete file ${file.path}');
  }
}

/**
 * Moves [file] to the partially stored directory. Files are moved here when one
 * of the store step fails.
 */
void moveToPartiallyStoredDirectory(File file, bool savedToDisk, String blobId,
    Configuration config, Logger log) {
  final StringBuffer filepath = new StringBuffer();

  filepath.write('${config.cdrPartiallyStoredDirectory.path}/');

  if (savedToDisk) {
    filepath.write('savedToDisk:${savedToDisk}____');
  }

  if (blobId.isNotEmpty) {
    filepath.write('blobId:${blobId}____');
  }

  filepath.write(path.basename(file.path).split('____').last);

  file.renameSync(filepath.toString());

  log.info(
      'store.moveToPartiallyStoredDirectory() moved ${path.basename(file.path)} to ${filepath.toString()}');
}

/**
 * Parse, store and summarize the last file from [files] to [google] Cloud
 * Storage and local disk.
 *
 * Summarize if [summarize] is true.
 *
 * Calls itself recursively until [files] is empty.
 */
Future parseStoreAndSummarize(List<FileSystemEntity> files, bool summarize,
    Google google, Configuration config, Logger log) async {
  String basename;
  String blobId = '';
  blob.Object blobResponse;
  CdrEntry cdrEntry;
  Map cdrJson;
  bool savedToDisk = false;
  File file;
  List<Future> futures = new List<Future>();

  try {
    if (files.isNotEmpty) {
      file = files.removeLast();

      basename = path.basename(file.path);
      cdrJson = json.decode(file.readAsStringSync());
      cdrEntry = new CdrEntry(cdrJson, basename.split('____').last);
    } else {
      return;
    }

    Future blob() async {
      blobResponse = await bUpload(file, google, config);
      blobId = path.basename(blobResponse.id);
      log.info(
          'store.parseStoreAndSummarize.blob() ${blobResponse.name} uploaded to bucket ${config.bucket} with id ${blobId}');
    }

    Future saveToDisk() async {
      if (cdrEntry.state != CdrEntryState.agentChannel ||
          config.saveAgentChannelEntries) {
        final DateTime stamp =
            new DateTime.fromMillisecondsSinceEpoch(cdrEntry.startEpoch * 1000);
        final String date = stamp.toIso8601String().split('T').first;
        final String state = cdrEntry.state.toString().split('.').last;
        final File cdrFileTmp = new File(
            '${config.cdrEntryStore.path}/${date}/${state}_start_${cdrEntry.startEpoch}_rid_${cdrEntry.rid}_uid_${cdrEntry.uid}_${cdrEntry.uuid}.json.tmp');
        final String cdrFilePath =
            '${config.cdrEntryStore.path}/${date}/${state}_start_${cdrEntry.startEpoch}_rid_${cdrEntry.rid}_uid_${cdrEntry.uid}_${cdrEntry.uuid}.json';
        await cdrFileTmp.createSync(recursive: true);
        await cdrFileTmp.writeAsString(json.encode(cdrEntry));
        await cdrFileTmp.rename(cdrFilePath);
        savedToDisk = true;
        log.info(
            'store.parseStoreAndSummarize.saveToDisk() saved ${cdrFilePath} to disk');
      } else {
        /// I know savedToDisk is poorly named, as we're not actually saving
        /// anything.
        /// In this context it just means that we've managed to "handle" the
        /// file without failure.
        savedToDisk = true;
        log.info(
            'store.parseStoreAndSummarize.saveToDisk() ignoring agentChannel ${cdrEntry.filename}');
      }
    }

    if (basename.startsWith('savedToDisk:')) {
      /// Already saved to local disk.
      futures.add(blob());
    } else if (basename.startsWith('blobId:')) {
      /// Already uploaded to Google Cloud Storage
      futures.add(saveToDisk());
    } else {
      /// Not uploaded to anything yet.
      futures.add(blob());
      futures.add(saveToDisk());
    }

    await Future.wait(futures);

    delete(file, log);

    if (summarize) {
      saveSummary(cdrEntry, config, log);
    }

    if (files.isEmpty) {
      log.info(
          'store.parseStoreAndSummarize() file list empty - no more to do right now...');
    } else {
      /// Limit uploads to one per 500 milliseconds.
      await new Future.delayed(new Duration(milliseconds: 500));
    }
  } on FormatException catch (error) {
    log.error(
        'store.parseStoreAndSummarize() parsing of JSON failed with ${error} on file ${file}');
    file.renameSync('${config.cdrErrorsDirectory}/${path.basename(file.path)}');
    log.info(
        'store.parseStoreAndSummarize() moved ${file} to ${config.cdrErrorsDirectory}/${path.basename(file.path)}');
  } catch (error, stackTrace) {
    log.error(
        'store.parseStoreAndSummarize() failed with ${error} - ${stackTrace} on file ${file.path}');
    moveToPartiallyStoredDirectory(file, savedToDisk, blobId, config, log);
  }

  await parseStoreAndSummarize(files, summarize, google, config, log);
}
