/*                  This file is part of OpenReception
                   Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

library ors.controller.agent_history;

import 'dart:async';

import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:orf/exceptions.dart';
import 'package:orf/filestore.dart' as filestore;

class AgentStatistics {
  AgentStatistics(this._agentHistory);

  final filestore.AgentHistory _agentHistory;
  Logger _log = Logger('ors.controller.agent_history');

  Future<Response> today(Request request) async {
    return okJson(_agentHistory.get(DateTime.now()));
  }

  Future<Response> summary(Request request, String dayParam) async {
    DateTime day;

    try {
      final List<String> part = dayParam.split('-');

      day = DateTime(
          int.parse(part[0]), int.parse(part[1]), int.parse(part[2]));
    } catch (e) {
      final String msg = 'Day parsing failed: $dayParam';
      _log.warning(msg, e);
      return ok(msg);
    }

    try {
      return okJson(await _agentHistory.agentSummay(day));
    } on NotFound {
      return notFound('No stats for the day $dayParam');
    }
  }

  Future<Response> get(Request request, String dayParam) async {
    DateTime day;

    try {
      final List<String> part = dayParam.split('-');

      day = DateTime(
          int.parse(part[0]), int.parse(part[1]), int.parse(part[2]));
    } catch (e) {
      final String msg = 'Day parsing failed: $dayParam';
      _log.warning(msg, e);
      return clientError(msg);
    }

    try {
      return okJson(_agentHistory.get(day));
    } on NotFound {
      return notFound('No stats for the day $dayParam');
    }
  }
}
