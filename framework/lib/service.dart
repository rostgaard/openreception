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

library orf.service;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:orf/bus.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/src/constants/model.dart' as key;

import 'package:orf/model.dart' as model;
import 'package:orf/storage.dart' as storage;
import 'package:orf/api.dart' as api;

part 'service/service-auth.dart';
part 'service/service-calendar.dart';
part 'service/service-call_flow_control.dart';
part 'service/service-cdr.dart';
part 'service/service-configuration.dart';
part 'service/service-contact.dart';
part 'service/service-datastore.dart';
part 'service/service-dialplan.dart';
part 'service/service-ivr.dart';
part 'service/service-message.dart';
part 'service/service-notification.dart';
part 'service/service-organization.dart';
part 'service/service-peer_account.dart';
part 'service/service-reception.dart';
part 'service/service-user.dart';
part 'service/service-webservice.dart';
part 'service/service-websocket.dart';

const JsonCodec _json = const JsonCodec();

Uri _appendToken(Uri uri, String token) =>
    _appendParameter(uri, 'token', token);

Uri _appendParameter(Uri uri, String key, dynamic value) =>
    Uri.parse('$uri${uri.queryParameters.isEmpty ? '?' : '&'}$key=$value');
