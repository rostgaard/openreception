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

library orf.resource;

import 'dart:convert';

import 'package:orf/model.dart' as model;
import 'package:orf/util.dart' as util;

part 'resource/resource-authentication.dart';
part 'resource/resource-calendar.dart';
part 'resource/resource-call_flow_control.dart';
part 'resource/resource-cdr.dart';
part 'resource/resource-config.dart';
part 'resource/resource-contact.dart';
part 'resource/resource-distribution_list.dart';
part 'resource/resource-endpoint.dart';
part 'resource/resource-ivr.dart';
part 'resource/resource-message.dart';
part 'resource/resource-notification.dart';
part 'resource/resource-organization.dart';
part 'resource/resource-peer_account.dart';
part 'resource/resource-reception.dart';
part 'resource/resource-reception_dialplan.dart';
part 'resource/resource-user.dart';

const JsonCodec _json = const JsonCodec();
