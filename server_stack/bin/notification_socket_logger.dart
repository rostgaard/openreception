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

/**
 * The OR-Stack command-line event logger.
 */
library ors.event_logger;

import 'dart:async';
import 'dart:convert';

import 'package:orf/service-io.dart' as transport;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';

const JsonCodec _json = const JsonCodec();

Future main(List<String> args) async {
  transport.WebSocketClient client = new transport.WebSocketClient();
  await client.connect(Uri.parse(
      '${config.configserver.notificationSocketUri}?token=${config.authServer.serverToken}'));

  service.NotificationSocket notificationSocket =
      new service.NotificationSocket(client);

  notificationSocket.onEvent.listen((event) {
    print(_json.encode(event));
  });
}
