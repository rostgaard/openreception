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

library ors.controller.cdr;

import 'dart:async';
import 'dart:io' as io;

import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:ors/configuration.dart';

class Cdr {

  /// Constructor.
  Cdr();

  final Logger _log = Logger('cdr_server.controller.cdr');


  Future<Response> process(Request request, String fromParam, String toParam, String kind) async {
    String direction = '';
    DateTime from;
    String kind;
    List<String> rids = List<String>();
    DateTime to;
    List<String> uids = List<String>();

    try {
      from =
          DateTime.parse(Uri.decodeComponent(fromParam));
      to = DateTime.parse(Uri.decodeComponent(toParam));

      if (from.isAtSameMomentAs(to) || from.isAfter(to)) {
        throw FormatException('Invalid timestamps. From must be before to');
      }

      kind = kind.toLowerCase();
      if (!['list', 'summary'].contains(kind)) {
        throw FormatException('Invalid kind value');
      }

      if (request.url.queryParameters.containsKey('direction')) {
        direction = request.url.queryParameters['direction'].toLowerCase();
        if (!['both', 'inbound', 'outbound'].contains(direction)) {
          throw FormatException('Invalid direction value');
        }
      }

      if (request.url.queryParameters.containsKey('rids')) {
        rids = request.url.queryParameters['rids'].split(',');
      }

      if (request.url.queryParameters.containsKey('uids')) {
        uids = request.url.queryParameters['uids'].split(',');
      }
    } on FormatException catch (error) {
      _log.warning('Bad request string: ${request.requestedUri}');
      _log.warning(error.message);
      return Response.internalServerError(
          body: 'Cannot parse request string');
    }

    final List<String> args = List<String>()
      ..add(config.cdrServer.pathToCdrCtl)
      ..add('report')
      ..add('-k')
      ..add(kind)
      ..add('-f')
      ..add(from.toIso8601String())
      ..add('-t')
      ..add(to.toIso8601String())
      ..add('--json');

    if (direction.isNotEmpty) {
      args.add('-d');
      args.add(direction);
    }

    if (rids.isNotEmpty) {
      args.add('-r');
      args.add(rids.join(','));
    }

    if (uids.isNotEmpty) {
      args.add('-u');
      args.add(uids.join(','));
    }

    final io.ProcessResult pr = await io.Process.run('dart', args);
    _log.info('Executing dart ${args.join(' ')}');
    return Response.ok(pr.stdout);
  }
}
