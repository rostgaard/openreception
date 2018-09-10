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

  final Logger _log = new Logger('cdr_server.controller.cdr');


  Future<Response> process(Request request) async {
    String direction = '';
    DateTime from;
    String kind;
    List<String> rids = new List<String>();
    DateTime to;
    List<String> uids = new List<String>();

    try {
      from =
          DateTime.parse(Uri.decodeComponent(request.path.variables['from']));
      to = DateTime.parse(Uri.decodeComponent(request.path.variables['to']));

      if (from.isAtSameMomentAs(to) || from.isAfter(to)) {
        throw new FormatException('Invalid timestamps. From must be before to');
      }

      kind = request.path.variables['kind'].toString().toLowerCase();
      if (!['list', 'summary'].contains(kind)) {
        throw new FormatException('Invalid kind value');
      }

      if (request.path.variables.containsKey('direction')) {
        direction = request.path.variables['direction'].toLowerCase();
        if (!['both', 'inbound', 'outbound'].contains(direction)) {
          throw new FormatException('Invalid direction value');
        }
      }

      if (request.path.variables.containsKey('rids')) {
        rids = request.path.variables['rids'].split(',');
      }

      if (request.path.variables.containsKey('uids')) {
        uids = request.path.variables['uids'].split(',');
      }
    } on FormatException catch (error) {
      _log.warning('Bad request string: ${request.path}');
      _log.warning(error.message);
      return new Response.serverError(
          body: 'Cannot parse request string');
    }

    final List<String> args = new List<String>()
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
    return new Response.ok(pr.stdout);
  }
}
