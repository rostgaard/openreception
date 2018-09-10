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

library configuration;

import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/storage/v1.dart' as blob;

JsonEncoder _encoder = new JsonEncoder.withIndent('  ');

class Configuration {
  /// Name of the Google Cloud Storage bucket where CDR files are stored.
  String bucket = 'bucket-name';

  /// Multiplier for call charges.
  num callChargeMultiplier = 1.0;

  /// Absolute path to where we search for CDR files in "daemon" mode.
  Directory cdrDirectory = new Directory('/tmp/cdr-json');

  /// Absolute path to where we save the individual CdrEntry objects.
  Directory cdrEntryStore = new Directory('/tmp/cdr-json-entry-store');

  /// Absolute path to where we save the CDR files that fail to upload.
  Directory cdrErrorsDirectory = new Directory('/tmp/cdr-json-errors');

  /// Absolute path to where we we save the partially stored CDR files.
  Directory cdrPartiallyStoredDirectory =
      new Directory('/tmp/cdr-partially-stored');

  /// Absolute path to where we save the summary JSON files.
  Directory cdrSummaryDirectory = new Directory('/tmp/cdr-summaries');

  /// The Google Service Account credentials.
  auth.ServiceAccountCredentials credentials;

  /// The Google Service Account key
  String _key;

  /// Calls with a length that is >= this are counted as long calls in Summary
  /// objects.
  int longCallBoundaryInSeconds = 300;

  /// Whether or not to save agent channel CDR data in the [cdrEntryStore].
  bool saveAgentChannelEntries = false;

  /// The list of scopes we need to get stuff done on Google Cloud.
  List<String> scopes = [blob.StorageApi.DevstorageReadWriteScope];

  /// Calls with a length that is <= this are counted as short calls in Summary
  /// objects.
  int shortCallBoundaryInSeconds = 5;

  /// The interval between searching [cdrDirectory] for new cdr.json files and
  /// uploading them to Google Cloud.
  int uploadIntervalInSeconds = 10;

  /**
   * Constructor.
   *
   * [key] must be a valid Google Service Account JSON key.
   */
  Configuration(String key) {
    credentials = new auth.ServiceAccountCredentials.fromJson(key);
    _key = key;
  }

  /**
   * JSON constructor.
   */
  Configuration.fromJson(Map cfgMap) {
    bucket = cfgMap['bucket'];
    callChargeMultiplier = cfgMap['callChargeMultiplier'];
    cdrDirectory = new Directory(cfgMap['cdrDirectory']);
    cdrErrorsDirectory = new Directory(cfgMap['cdrErrorsDirectory']);
    cdrPartiallyStoredDirectory =
        new Directory(cfgMap['cdrPartiallyStoredDirectory']);
    cdrSummaryDirectory = new Directory(cfgMap['cdrSummaryDirectory']);
    _key = json.encode(cfgMap['key']);
    longCallBoundaryInSeconds = cfgMap['longCallBoundaryInSeconds'];
    saveAgentChannelEntries = cfgMap['saveAgentChannelEntries'];
    scopes = cfgMap['scopes'] as List<String>;
    shortCallBoundaryInSeconds = cfgMap['shortCallBoundaryInSeconds'];
    uploadIntervalInSeconds = cfgMap['uploadIntervalInSeconds'];

    credentials = new auth.ServiceAccountCredentials.fromJson(_key);
  }

  Map toJson() => {
        'bucket': bucket,
        'callChargeMultiplier': callChargeMultiplier,
        'cdrDirectory': cdrDirectory.path,
        'cdrErrorsDirectory': cdrErrorsDirectory.path,
        'cdrPartiallyStoredDirectory': cdrPartiallyStoredDirectory.path,
        'cdrSummaryDirectory': cdrSummaryDirectory.path,
        'key': json.decode(_key),
        'longCallBoundaryInSeconds': longCallBoundaryInSeconds,
        'saveAgentChannelEntries': saveAgentChannelEntries,
        'scopes': scopes,
        'shortCallBoundaryInSeconds': shortCallBoundaryInSeconds,
        'uploadIntervalInSeconds': uploadIntervalInSeconds
      };

  String toString() {
    return _encoder.convert(this);
  }
}
