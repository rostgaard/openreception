/*                  This file is part of OpenReception
                   Copyright (C) 2016-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

/// File-based storage backend. Realizes the interfaces from [storage].
library orf.filestore;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:intl/intl.dart' show DateFormat;
import 'package:logging/logging.dart';
import 'package:orf/bus.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/gzip_cache.dart'
    show unpackAndDeserializeObject, serializeAndCompressObject;
import 'package:orf/model.dart' as model;
import 'package:orf/storage.dart' as storage;
import 'package:path/path.dart';

part 'filestore/filestore-agent_history.dart';
part 'filestore/filestore-calendar.dart';
part 'filestore/filestore-contact.dart';
part 'filestore/filestore-git_engine.dart';
part 'filestore/filestore-ivr.dart';
part 'filestore/filestore-message.dart';
part 'filestore/filestore-message_queue.dart';
part 'filestore/filestore-organization.dart';
part 'filestore/filestore-reception.dart';
part 'filestore/filestore-reception_dialplan.dart';
part 'filestore/filestore-sequencer.dart';
part 'filestore/filestore-user.dart';

const String _libraryName = 'openreception.filestore';

const JsonEncoder _jsonpp = const JsonEncoder.withIndent('  ');
const JsonCodec _json = const JsonCodec();

final model.User _systemUser = new model.User.empty()
  ..name = 'System'
  ..address = 'root@localhost';

/// Generate an author string from a [model.User] object.
///
/// The generated author string will have the form `$name <$email>` and will
/// be HTML-escaped.
String _authorString(model.User user) =>
    new HtmlEscape(HtmlEscapeMode.attribute).convert('${user.name}') +
    ' <${user.address}>';

/// Convenience function for checking that a [FileSystemEntity] is a
/// non-hidden file.
bool _isFile(FileSystemEntity fse) => fse is File && !fse.path.startsWith('.');

/// Convenience function for checking that a [FileSystemEntity] is a
/// non-hidden .json file.
bool _isJsonFile(FileSystemEntity fse) =>
    fse is File && !fse.path.startsWith('.') && fse.path.endsWith('.json');

/// Convenience function for checking that a [FileSystemEntity] is a
/// non-hidden directory.
bool _isDirectory(FileSystemEntity fse) =>
    !basename(fse.path).startsWith('.') && fse is Directory;

/// Filestore wrapper class that encloses all the filestores.
class DataStore {
  /// Calendar child store
  final Calendar calendarStore;

  /// Contact child store
  final Contact contactStore;

  /// Ivr menu child store
  final Ivr ivrStore;

  /// message child store
  final Message messageStore;

  /// Organization child store
  final Organization organizationStore;

  /// Reception child store
  final Reception receptionStore;

  /// Reception dialplan child store
  final ReceptionDialplan receptionDialplanStore;

  /// User child store
  final User userStore;

  /// Create a new [DataStore] in directory [path].
  ///
  /// If [path] exists, then the [DataStore] will reuse the existing objects
  /// in it.
  /// Optionally uses a [GitEngine] for revisioning.
  factory DataStore(String path, [GitEngine ge]) {
    Calendar calendarStore = new Calendar(path + '/calendar', ge);
    Reception receptionStore = new Reception(path + '/reception', ge);
    Contact contactStore = new Contact(receptionStore, path + '/contact', ge);
    Ivr ivrStore = new Ivr(path + '/ivr', ge);
    Message messageStore = new Message(path + '/message');
    Organization orgStore = new Organization(
        contactStore, receptionStore, path + '/organization', ge);
    ReceptionDialplan receptionDialplanStore =
        new ReceptionDialplan(path + '/dialplan', ge);
    User userStore = new User(path + '/user', ge);

    return new DataStore._internal(
        calendarStore,
        contactStore,
        ivrStore,
        messageStore,
        orgStore,
        receptionStore,
        receptionDialplanStore,
        userStore);
  }

  /// Internal constructor.
  ///
  /// Sets the finalized fields and performs no further initialization.
  DataStore._internal(
      Calendar this.calendarStore,
      Contact this.contactStore,
      Ivr this.ivrStore,
      Message this.messageStore,
      Organization this.organizationStore,
      Reception this.receptionStore,
      ReceptionDialplan this.receptionDialplanStore,
      User this.userStore);
}

/// Simple file-based [ChangeLogger] class that bumps serialized objects
/// (and the changetype) to a plain file.
class ChangeLogger {
  /// The [File] object changes are logged to
  final File logFile;

  /// Internal logger.
  final Logger _log = new Logger('orf.filestore.ChangeLogger');

  /// Create a new [ChangeLogger] in [filepath].
  ///
  /// The changelog file will be placed in a `changes.log` file within
  /// [filepath].
  ChangeLogger(String filepath)
      : logFile = new File(filepath + '/changes.log') {
    try {
      if (!logFile.existsSync()) {
        logFile.createSync();
      }
    } on FileSystemException catch (e) {
      _log.warning('Failed to create changelogfile', e);
    }
  }

  /// Append a [model.ChangelogEntry] to the [logFile].
  void add(model.ChangelogEntry object) {
    logFile.writeAsStringSync(_json.encode(object) + '\n',
        mode: FileMode.append);
  }

  /// Read the entire content of [logFile] into a [String] buffer.
  Future<String> contents() async => new File(logFile.path).existsSync()
      ? (await new File(logFile.path).readAsString())
      : '';
}
