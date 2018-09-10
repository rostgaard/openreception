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

library ors.router.config;

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-config.dart' as controller;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;
import 'package:shelf_router/shelf_router.dart' as shelf_route;

/**
 *
 */
class Config {

  /**
   *
   */
  Config(this._configController);

  final Logger _log = Logger('server.router.config');
  final controller.Config _configController;


  /**
   *
   */
  void bindRoutes(dynamic router) {
    router
      ..get('/configuration', _configController.get)
      ..post('/configuration/register', _configController.register)
      ..all('/<catch-all|.*>', (Request request) {
        return Response.notFound('Page not found');
      });
  }

  /**
   *
   */
  Future<HttpServer> listen({String hostname: '0.0.0.0', int port: 4080}) {
    final router = shelf_route.Router();
    bindRoutes(router);

    final handler = const Pipeline()
        .addMiddleware(logRequests(logger: config.accessLog.onAccess))
        .addMiddleware(
        shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
        .addHandler(router.handler);

    _log.fine('Accepting incoming requests on $hostname:$port:');

    return shelf_io.serve(handler, hostname, port);
  }
}