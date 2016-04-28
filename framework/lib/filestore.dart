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

library openreception.framework.filestore;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:openreception.framework/model.dart' as model;
import 'package:openreception.framework/storage.dart' as storage;
import 'package:path/path.dart';

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

const String libraryName = 'openreception.filestore';

final JsonEncoder _jsonpp = new JsonEncoder.withIndent('  ');

final model.User _systemUser = new model.User.empty()
  ..name = 'System'
  ..address = 'root@localhost';

/**
 * Generate an author string.
 */
String _authorString(model.User user) =>
    new HtmlEscape(HtmlEscapeMode.ATTRIBUTE).convert('${user.name}') +
    ' <${user.address}>';

/**
 * Convenience functions
 */
bool isFile(FileSystemEntity fse) => fse is File && !fse.path.startsWith('.');

bool isDirectory(FileSystemEntity fse) =>
    fse is Directory && !fse.path.startsWith('.');
