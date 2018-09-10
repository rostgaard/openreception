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

library orf.model;

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:orf/bus.dart';
import 'package:orf/event.dart' as _event;
import 'package:orf/model/dialplan/model-dialplan.dart';
import 'package:orf/pbx-keys.dart';
import 'package:orf/src/constants/model.dart' as key;
import 'package:orf/util.dart' as util;
import 'package:path/path.dart' as path;

export 'package:orf/model/dialplan/model-dialplan.dart';
export 'package:orf/model/model-monitoring.dart';

part 'model/model-active_recording.dart';
part 'model/model-agent_statistics.dart';
part 'model/model-audiofile.dart';
part 'model/model-base_contact.dart';
part 'model/model-calendar_entry.dart';
part 'model/model-calendar_entry_change.dart';
part 'model/model-call.dart';
part 'model/model-caller_info.dart';
part 'model/model-cdr_entry.dart';
part 'model/model-cdr_summary.dart';
part 'model/model-change.dart';
part 'model/model-channel.dart';
part 'model/model-client_configuration.dart';
part 'model/model-client_connection.dart';
part 'model/model-message.dart';
part 'model/model-message_context.dart';
part 'model/model-message_endpoint.dart';
part 'model/model-message_filter.dart';
part 'model/model-message_flag.dart';
part 'model/model-message_queue_item.dart';
part 'model/model-organization.dart';
part 'model/model-origination_context.dart';
part 'model/model-owner.dart';
part 'model/model-peer.dart';
part 'model/model-peer_account.dart';
part 'model/model-phone_number.dart';
part 'model/model-playlist.dart';
part 'model/model-reception.dart';
part 'model/model-reception_attributes.dart';
part 'model/model-template.dart';
part 'model/model-template_email.dart';
part 'model/model-template_sms.dart';
part 'model/model-user.dart';
part 'model/model-user_status.dart';
part 'model/model-when_what.dart';

const String _libraryName = "openreception.model";

List<String> stringList(final List<dynamic> list) {
  return list.map((dynamic element) {
    if (element is String) {
      return element;
    }
    throw ArgumentError.value(element, "Element in list is not String");
  }).toList();
}

/// [ChangelogEntry] interface.
abstract class ChangelogEntry {
  /// The time of the change.
  DateTime get timestamp;

  /// The type of change.
  ChangeType get changeType;

  /// The reference to the user who performed the change.
  UserReference get modifier;

  /// Serialization function.
  dynamic toJson();
}
