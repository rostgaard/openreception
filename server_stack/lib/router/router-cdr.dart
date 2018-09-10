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

library ors.cdr_server.router;

import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:orf/exceptions.dart';
import 'package:orf/service.dart' as Service;
import 'package:ors/controller/controller-cdr.dart' as controller;
import 'package:shelf/shelf.dart' as shelf;

const String libraryName = 'cdrserver.router';
final Logger log = Logger(libraryName);

const Map<String, String> corsHeaders = const {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE'
};

Future<io.HttpServer> start(Service.Authentication authService,
    {String hostname: '0.0.0.0', int port: 4090}) async {
  final controller.Cdr cdrController = controller.Cdr();

  Future<shelf.Response> _lookupToken(shelf.Request request) async {
    String token = request.requestedUri.queryParameters['token'];

    try {
      await authService.validate(token);
    } on NotFound {
      return shelf.Response.forbidden('Invalid token');
    } on io.SocketException {
      return shelf.Response.internalServerError(
          body: 'Cannot reach authserver');
    } catch (error, stackTrace) {
      log.severe('Authentication validation lookup failed: $error:$stackTrace');

      return shelf.Response.internalServerError(body: error.toString());
    }

    /// Do not intercept the request, but let the next handler take care of it.
    return null;
  }

  /**
   * Authentication middleware.
   */
  shelf.Middleware checkAuthentication = shelf.createMiddleware(
      requestHandler: _lookupToken, responseHandler: null);

//  var router = shelf_route.router(fallbackHandler: send404)
//    ..get('/from/{from}/to/{to}/kind/{kind}', cdrController.process);
//
//  var handler = const shelf.Pipeline()
//      .addMiddleware(
//          shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
//      .addMiddleware(checkAuthentication)
//      .addMiddleware(shelf.logRequests(logger: config.accessLog.onAccess))
//      .addHandler(router.handler);
//
//  log.fine('Serving interfaces:');
//  shelf_route.printRoutes(router, printer: (String item) => log.fine(item));
//
//  return await shelf_io.serve(handler, hostname, port);
}
