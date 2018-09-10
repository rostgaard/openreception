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

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:ors/model.dart' as _model;

class Channel {
  Channel(this._channelList);

  final Logger log =
      Logger('openreception.call_flow_control_server.Channel');

  final _model.ChannelList _channelList;


  Response list(Request request) {
    try {
      List<Map> retval = List<Map>();
      _channelList.forEach((channel) {
        retval.add(channel.toMap());
      });

      return Response.ok(json.encode(retval));
    } catch (error, stacktrace) {
      log.severe(error, stacktrace);
      return Response.internalServerError(
          body: 'Failed to retrieve channel list');
    }
  }

  Future<Response> get(
          Request request, final String channelId) async =>
      Response.ok(json.encode(_channelList.get(channelId).toMap()));
}
