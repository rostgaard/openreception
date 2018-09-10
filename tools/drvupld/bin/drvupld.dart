/*                 Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

library drvupld;

import 'dart:async';
import 'dart:io';

import 'package:googleapis/drive/v2.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:logging/logging.dart';
import 'package:orf/model.dart' as ORModel;
import 'package:orf/service-io.dart' as ORTransport;
import 'package:orf/service.dart' as ORService;
import 'package:path/path.dart' as path;

import 'config.dart';

part '../lib/exceptions.dart';
part '../lib/nameparts.dart';

typedef Future<ORModel.Reception> ORFReception(int receptionID);
typedef Future<Iterable<ORModel.ActiveRecording>> ORFRecordings();
typedef Future<ORModel.User> ORFUser(int userID);

/**
 * Uploads all files found in [Config.localDirectory] to the Google Drive
 * folders set in config.dart. See README.md for information about required file
 * naming format.
 */
main() async {
  auth.AutoRefreshingAuthClient client;
  final Config config = new Config();
  final Logger log = setupLogging();

  try {
    final auth.ServiceAccountCredentials serviceAccountCredentials =
        new auth.ServiceAccountCredentials.fromJson(
            config.serviceAccountFile.readAsStringSync(),
            impersonatedUser: config.impersonatedUser);
    final ORModel.ClientConfiguration configORF =
        await getConfigORF(config, log);

    /// Lets make these ORF functions local.
    getReception = new ORService.RESTReceptionStore(
            configORF.receptionServerUri,
            config.orfToken,
            new ORTransport.Client())
        .get;
    getRecordings = new ORService.CallFlowControl(configORF.callFlowServerUri,
            config.orfToken, new ORTransport.Client())
        .activeRecordings;
    getUser = new ORService.RESTUserStore(
            configORF.userServerUri, config.orfToken, new ORTransport.Client())
        .get;

    client = await auth.clientViaServiceAccount(
        serviceAccountCredentials, config.scopes);
  } catch (error, stackTrace) {
    log.severe('main() dying with ${error.message} - $stackTrace');
    exit(1);
  }

  client.credentialUpdates.listen((auth.AccessCredentials newCredentials) {
    log.info('client.credentialUpdates.listen() ignoring ${newCredentials}');
  });

  try {
    await Future.doWhile(() async {
      try {
        await go(
            new drive.DriveApi(client),
            config.localDirectory,
            config.allFolder,
            config.agentsFolder,
            config.receptionsFolder,
            log);

        await new Future.delayed(config.uploadInterval);
      } catch (error) {
        log.severe('main() the go() function failed with ${error}');
      }

      return true;
    });
  } catch (error) {
    log.severe('main() Future.doWhile failed with ${error}');
  }

  log.severe('main() why am I dying? I am supposed to run forever!');
}

/// Creates [folder] in the [parent] folder and returns its id.
///
/// Throws if the folder cannot be created.
Future<String> createFolderAndReturnId(drive.DriveApi driveApi,
    drive.ParentReference parent, String folder, Logger log) async {
  try {
    drive.File driveFolder = new drive.File()
      ..title = folder
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = [parent];

    driveFolder = await driveApi.files.insert(driveFolder);

    log.info(
        'createFolderAndReturnId() created folder ${folder} with ID ${driveFolder.id}');

    return driveFolder.id;
  } catch (error) {
    log.warning(
        'createFolderAndReturnId() create new folder ${folder} failed with ${error}');
    throw error;
  }
}

/// Delete [file].
///
/// Logs success to info and failure to severe.
///
/// Does not throw.
void delete(File file, Logger log) {
  try {
    file.deleteSync();
    log.info('delete() deleted local file ${file.path}');
  } catch (error) {
    log.severe('delete() could not delete file ${file.path}');
  }
}

/// Returns true if the [nameParts] file is found in [parent], else false.
///
/// This checks both the title and ASCII only title of [nameParts].
///
/// Returns false if the Google Drive check throws.
Future<bool> exists(drive.DriveApi driveApi, drive.ParentReference parent,
    NameParts nameParts, Logger log) async {
  try {
    final String query = '"${parent.id}" in parents and '
        '(title = "${nameParts.title}" or title = "${nameParts.titleASCIIOnly()}")';

    return (await driveApi.files.list(q: query)).items.isNotEmpty;
  } catch (error) {
    log.warning(
        'exists() failed with ${error} - will err on safe side and return false');
    return false;
  }
}

/// Return a folder id for [folder] with parent [parent]. If [folder] does not
/// exist, then create it and return the new id.
///
/// Returns an empty String on errors. Does not throw.
Future<String> folderId(drive.DriveApi driveApi, drive.ParentReference parent,
    String folder, Logger log) async {
  String id;

  try {
    id = await folderIdIfExists(driveApi, parent, folder, log);
    log.info('folderId() got id ${id} for the  ${folder} folder');
  } on NoFolderFoundException catch (_) {
    try {
      id = await createFolderAndReturnId(driveApi, parent, folder, log);
    } catch (error) {
      log.severe(
          'folderId() creating the ${folder} folder failed with ${error}');
      id = '';
    }
  } catch (error) {
    log.severe(
        'folderId() find id of the ${folder} folder failed with ${error}');
    id = '';
  }

  return id;
}

/// Returns the id of [folder], if [folder] as a child of [parent] exists.
///
/// Throws [NoFolderFoundException] if [folder] does not exist or if it is marked
/// trashed.
///
/// Throws [ApiRequestError] if the call to Google Drive fails.
Future<String> folderIdIfExists(drive.DriveApi driveApi,
    drive.ParentReference parent, String folder, Logger log) async {
  final String query = '"${parent.id}" in parents'
      ' and mimeType = "application/vnd.google-apps.folder"'
      ' and title = "${folder}"';
  final drive.FileList list = await driveApi.files.list(q: query);

  if (list.items.length > 1) {
    log.warning(
        'folderIdIfExists() multiple folders named ${folder} - returning id of first');
  } else if (list.items.isEmpty) {
    throw new NoFolderFoundException(
        'folderIdIfExists() cannot locate folder named ${folder}');
  } else if (list.items.first.labels.trashed) {
    throw new NoFolderFoundException(
        'folderIdIfExists() The folder ${folder} is trashed');
  }

  return list.items.first.id;
}

/// Fetch a [ORModel.ClientConfiguration] object.
///
/// Throws [ORFException] on failure.
Future<ORModel.ClientConfiguration> getConfigORF(
    Config config, Logger log) async {
  try {
    return await new ORService.RESTConfiguration(
            config.orfConfigUrl, new ORTransport.Client())
        .clientConfig();
  } catch (error) {
    log.severe('getConfigORF() failed with ${error}');
    throw new ORFException(error);
  }
}

/// Returns a [ORModel.Reception] object if the given [receptionID] resolves to a
/// reception.
///
/// Throws [ORFException] if no reception is found.
ORFReception getReception;

/// Returns a [ORModel.ActiveRecording] object if then given [channel] resolves
/// to an active call.
///
/// Throws [ORFException] if no call is found.
ORFRecordings getRecordings;

/// Returns a [ORModel.User] object if the given [userID] resolves to an user.
///
/// Throws [ORFException] if no user is found.
ORFUser getUser;

/// Start an upload session.
///
/// Logs if it finds a suspicious amount of files in the [recordingsDirectory].
/// It is considered suspicious if there are more than 500 files sitting there.
///
/// Does not throw. Terminal errors are logged to severe.
Future go(
    drive.DriveApi driveApi,
    Directory recordingsDirectory,
    drive.ParentReference allParent,
    drive.ParentReference agentParent,
    drive.ParentReference receptionParent,
    Logger log) async {
  try {
    final List<FileSystemEntity> files = recordingsDirectory.listSync();
    List<ORModel.ActiveRecording> activeRecordings =
        new List<ORModel.ActiveRecording>();

    files.removeWhere((file) => file is Directory);

    if (files.isNotEmpty) {
      activeRecordings = await getRecordings();
    }

    log.info('go() found ${files.length} files in ${recordingsDirectory}');
    log.info('go() found ${activeRecordings.length} ongoing recordings');

    if (files.length > 500) {
      log.severe(
          'go() suspiciously many files found in ${recordingsDirectory.path}');
    }

    await upload(driveApi, files, activeRecordings, allParent, agentParent,
        receptionParent, log);
  } catch (error) {
    log.severe('go() failed with ${error}');
  }
}

/// Returns the channel id part of the [file] file name.
///
/// See README.md for information on the required file name format.
String harvestChannelId(File file) {
  final List<String> parts =
      path.basenameWithoutExtension(file.path).split('_');
  return parts[0];
}

/// Harvest a [NameParts] object from [file].
///
/// This also fetches agent and reception related data using the ORF [getUser]
/// and [getReception] functions.
///
/// Throws [HarvestException] if the split fails.
Future<NameParts> harvestNameParts(File file, Logger log) async {
  try {
    String agentName;
    final int channelIdPos = 0;
    final int directionPos = 3;
    final int receptionIdPos = 2;
    String receptionExten;
    String receptionName;
    final int remotePos = 4;
    final int uuidPos = 1;
    final List<String> parts =
        path.basenameWithoutExtension(file.path).split('_');

    /// Split the agent-agentId-timestamp part of the file name.
    final List<String> channelIdParts = parts[channelIdPos].split('-');

    try {
      agentName = (await getUser(int.parse(channelIdParts[1]))).name;
    } catch (error) {
      log.warning('harvestNameParts() failed with ${error}');
      agentName = 'unknown';
    }

    try {
      final ORModel.Reception reception =
          await getReception(int.parse(parts[receptionIdPos]));
      receptionExten = reception.dialplan;
      receptionName = reception.name;
    } catch (error) {
      log.warning('harvestNameParts() failed with ${error}');
      receptionExten = 'unknown';
      receptionName = 'unknown';
    }

    return new NameParts()
      ..agentId = int.parse(channelIdParts[1])
      ..agentName = agentName
      ..callDirection = parts[directionPos]
      ..callStart =
          new DateTime.fromMillisecondsSinceEpoch(int.parse(channelIdParts[2]))
              .toUtc()
      ..channelId = parts[channelIdPos]
      ..receptionExten = receptionExten
      ..receptionId = parts[receptionIdPos]
      ..receptionName = receptionName
      ..remoteNumber = parts[remotePos]
      ..uuid = parts[uuidPos];
  } catch (error) {
    log.severe('harvestNameParts() failed for file ${file.path} with ${error}');
    throw new HarvestException(error);
  }
}

/// Returns a list of [drive.ParentReference]s for the [nameParts] object that
/// will ultimately end up being uploaded.
///
/// If some of the needed parents are missing, this function will try to create
/// them.
///
/// Never returns an empty list. At a bare minimum it will contain [allFolder].
///
/// NOTE: The immediate folder child of parent [receptionsFolder] is named by the
/// first 6 characters of the [nameParts.receptionExten] string postfixed with
/// xx. What this basically means is that this will only really make sense for 8
/// character long danish telephone numbers.
///
/// Does not throw. Errors are logged and whatever parents might've been created
/// are returned.
Future<List<drive.ParentReference>> parents(
    drive.DriveApi driveApi,
    NameParts nameParts,
    drive.ParentReference allFolder,
    drive.ParentReference agentsFolder,
    drive.ParentReference receptionsFolder,
    Logger log) async {
  final List<drive.ParentReference> list = new List<drive.ParentReference>();

  try {
    final DateTime time = nameParts.callStart.toLocal();
    final String dateString = '${time.toIso8601String().split('T').first}';
    final String receptionShortString =
        '${nameParts.receptionExten.substring(0, 6)}xx';
    final String yearString = '${time.toLocal().year.toString()}';
    final drive.ParentReference agentDayFolder = new drive.ParentReference();
    final drive.ParentReference agentFolder = new drive.ParentReference();
    final drive.ParentReference agentYearFolder = new drive.ParentReference();
    final drive.ParentReference allDayFolder = new drive.ParentReference();
    final drive.ParentReference allYearFolder = new drive.ParentReference();
    final drive.ParentReference receptionShortFolder =
        new drive.ParentReference();
    final drive.ParentReference receptionDayFolder =
        new drive.ParentReference();
    final drive.ParentReference receptionFolder = new drive.ParentReference();
    final drive.ParentReference receptionYearFolder =
        new drive.ParentReference();

    /// AllFolder
    ///   |__ YearFolder
    ///         |__ DateFolder
    ///               |__ Files
    allYearFolder.id =
        await folderId(driveApi, allFolder, '${yearString} (all)', log);

    if (allYearFolder.id.isNotEmpty) {
      allDayFolder.id =
          await folderId(driveApi, allYearFolder, '${dateString} (all)', log);

      if (allDayFolder.id.isNotEmpty) {
        list.add(allDayFolder);
      }
    }

    if (list.isEmpty) {
      /// Something is amiss!
      /// Add allFolder to make sure no recordings are lost due to missing
      /// folders.
      list.add(allFolder);
    }

    /// AgentsFolder
    ///       |__ YearFolder
    ///             |__ DateFolder
    ///                   |__ AgentFolder
    ///                         |__ Files
    agentYearFolder.id =
        await folderId(driveApi, agentsFolder, '${yearString} (agent)', log);

    if (agentYearFolder.id.isNotEmpty) {
      agentDayFolder.id = await folderId(
          driveApi, agentYearFolder, '${dateString} (agent)', log);

      if (agentDayFolder.id.isNotEmpty) {
        agentFolder.id = await folderId(driveApi, agentDayFolder,
            '${nameParts.agentName} (${nameParts.agentId})', log);

        if (agentFolder.id.isNotEmpty) {
          list.add(agentFolder);
        }
      }
    }

    /// ReceptionsFolder
    ///       |__ YearFolder
    ///             |__ DateFolder
    ///                   |__ ReceptionShortFolder
    ///                         |__ ReceptionFolder
    ///                               |__ Files
    receptionYearFolder.id = await folderId(
        driveApi, receptionsFolder, '${yearString} (reception)', log);

    if (receptionYearFolder.id.isNotEmpty) {
      receptionDayFolder.id = await folderId(
          driveApi, receptionYearFolder, '${dateString} (reception)', log);

      if (receptionDayFolder.id.isNotEmpty) {
        receptionShortFolder.id = await folderId(
            driveApi, receptionDayFolder, receptionShortString, log);

        if (receptionShortFolder.id.isNotEmpty) {
          receptionFolder.id = await folderId(
              driveApi, receptionShortFolder, nameParts.receptionExten, log);

          if (receptionFolder.id.isNotEmpty) {
            list.add(receptionFolder);
          }
        }
      }
    }
  } catch (error) {
    log.warning('parents() failed with ${error}');
  }

  return list;
}


/// Returns a [Logger] with [Level.ALL].
///
/// [Level.INFO] and below is logged to STDOUT. Everything above [Level.INFO] is
/// sent to STDERR.
///
/// Does not throw.
Logger setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord record) {
    final String msg =
        '${record.level.name}: ${record.time}: ${record.message}';
    if (record.level.value > Level.INFO.value) {
      stderr.writeln(msg);
    } else {
      stdout.writeln(msg);
    }
  });

  return new Logger('drvupld');
}

/// Upload [file] to Google Drive.
///
/// All uploaded files will have the [allFolder] parent set. Depending on the
/// file name it will be assigned appropriate parent references in [agentFolder]
/// and [receptionFolder].
///
/// This calls itself recursively as long as there are files left in the [files]
/// list. One file is removed from the list on each call to [upload].
///
/// Exits drvupld if uploading a file takes more than 300 seconds.
///
/// Does not throw. Logs errors to warning and severe.
Future upload(
    drive.DriveApi driveApi,
    List<FileSystemEntity> files,
    Iterable<ORModel.ActiveRecording> recordings,
    drive.ParentReference allFolder,
    drive.ParentReference agentFolder,
    drive.ParentReference receptionFolder,
    Logger log) async {
  File file;

  if (files.isNotEmpty) {
    file = files.removeLast();
    if (file is Directory) {
      return;
    }
  } else {
    return;
  }

  final String filename = path.basename(file.path);

  int monitorCounter = 0;
  final Timer periodic = new Timer.periodic(new Duration(seconds: 10), (t) {
    monitorCounter++;
    log.info('upload() ${monitorCounter * 10} seconds passed since we began'
        ' processing $filename');
  });

  final Timer timeout = new Timer(new Duration(seconds: 300), () {
    log.severe(
        'upload() timeout - exiting drvupld due to apparent Google Drive API'
        ' failure while uploading $filename');
    exit(1);
  });

  try {
    log.info('upload() start processing $filename');

    final String channelId = harvestChannelId(file);
    if (recordings.any((ORModel.ActiveRecording recording) =>
        recording.agentChannel == channelId)) {
      throw new ActiveRecordingException(channelId);
    } else {
      log.info(
          'upload() ${channelId} not recording. $filename ready for upload');
    }

    final drive.Media media =
        new drive.Media(file.openRead(), file.lengthSync());
    final NameParts nameParts = await harvestNameParts(file, log);

    if (await exists(driveApi, allFolder, nameParts, log)) {
      log.warning(
          'upload() $filename seems to already be uploaded. Will not upload again');
    } else {
      final drive.File driveFile = new drive.File()
        ..title = nameParts.titleASCIIOnly()
        ..parents = await parents(
            driveApi, nameParts, allFolder, agentFolder, receptionFolder, log)
        ..modifiedDate = nameParts.callStart.toUtc()
        ..description = '#reception-id: ${nameParts.receptionId}\n'
            '#reception-extension: ${nameParts.receptionExten}\n'
            '#agent-id: ${nameParts.agentId}\n'
            '#call-start: ${saneTimeStamp(nameParts.callStart)}\n'
            '#call-direction: ${nameParts.callDirection}\n'
            '#remote-number: ${nameParts.remoteNumber}\n'
            '#channel-id: ${nameParts.channelId}\n'
            '#uuid: ${nameParts.uuid}\n';
      drive.File dFile =
          await driveApi.files.insert(driveFile, uploadMedia: media);

      log.info('upload() uploaded ${dFile.title}. Got id ${dFile.id}');

      /// Sadly we need to patch the uploaded file because the Google Drive API
      /// is having issues with getting content length right if one of the
      /// drive.File properties contains characters that are non-ASCII.
      dFile.title = nameParts.title();
      dFile.description = '#reception-name: ${nameParts.receptionName}\n'
          '#reception-id: ${nameParts.receptionId}\n'
          '#reception-extension: ${nameParts.receptionExten}\n'
          '#agent-name: ${nameParts.agentName}\n'
          '#agent-id: ${nameParts.agentId}\n'
          '#call-start: ${saneTimeStamp(nameParts.callStart)}\n'
          '#call-direction: ${nameParts.callDirection}\n'
          '#remote-number: ${nameParts.remoteNumber}\n'
          '#channel-id: ${nameParts.channelId}\n'
          '#uuid: ${nameParts.uuid}\n';

      try {
        dFile = await driveApi.files.patch(dFile, dFile.id);

        log.info('upload() patched ${dFile.id} with new title ${dFile.title} '
            'and description ${dFile.description.trim()}');
      } catch (error) {
        /// If patching fails, then it's just too bad. Hopefully this will
        /// rarely happen.
        log.warning('upload() patching file ${dFile.id} failed with ${error}');
      }
    }

    delete(file, log);

    log.info('upload() ${files.length} files to go');
  } on HarvestException catch (error) {
    log.warning(
        'upload() $filename - harvesting NameParts failed with ${error}');
  } on ActiveRecordingException catch (_) {
    log.info('upload() $filename is still recording. Ignoring.');
  } catch (error) {
    log.severe('upload() failed with ${error}');
  }

  periodic.cancel();
  timeout.cancel();

  await upload(driveApi, files, recordings, allFolder, agentFolder,
      receptionFolder, log);
}
