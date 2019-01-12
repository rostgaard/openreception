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

library ors.controller.channel;

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:ors/model.dart' as _model;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart' as shelf_route;
const _json = const JsonCodec();

class Channel {
  final Logger log =
      new Logger('openreception.call_flow_control_server.Channel');

  final _model.ChannelList _channelList;

  Channel(this._channelList);

  shelf.Response list(shelf.Request request) {
    try {
      List<Map> retval = new List<Map>();
      _channelList.forEach((channel) {
        retval.add(channel.toMap());
      });

      return new shelf.Response.ok(_json.encode(retval));
    } catch (error, stacktrace) {
      log.severe(error, stacktrace);
      return new shelf.Response.internalServerError(
          body: 'Failed to retrieve channel list');
    }
  }

  shelf.Response get(shelf.Request request) {
    final String channelId = shelf_route.getPathParameter(request, 'chanid');

    return new shelf.Response.ok(
        _json.encode(_channelList.get(channelId).toMap()));
  }
}
