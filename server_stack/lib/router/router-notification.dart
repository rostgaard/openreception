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

library ors.router.notification;

import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:orf/exceptions.dart';
import 'package:orf/service-io.dart' as service;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-notification.dart' as controller;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;
import 'package:shelf_router/shelf_router.dart';

const String libraryName = "notificationserver.router";
final Logger _log = Logger(libraryName);

class Notification {

  Notification(this._authService) {
    _notificationController = controller.Notification(_authService);
  }

  final service.Authentication _authService;
  controller.Notification _notificationController;


  /**
   *
   */
  void bindRoutes(dynamic router) {
    router
      ..get('/notifications', _notificationController.handleWsConnect)
      ..post('/broadcast', _notificationController.broadcast)
      ..post('/send', _notificationController.send)
      ..get('/connection', _notificationController.connectionList)
      ..get('/stats', _notificationController.statistics)
      ..get('/connection/<uid>', _notificationController.connection)
      ..all('/<catch-all|.*>', (Request request) {
        return Response.notFound('Page not found');
      });
  }

  /**
   *
   */
  Future<io.HttpServer> start({String hostname: '0.0.0.0', int port: 4200}) {
    /**
     * Validate a token by looking it up on the authentication server.
     */
    Future<Response> _lookupToken(Request request) async {
      var token = request.requestedUri.queryParameters['token'];

      try {
        await _authService.validate(token);
      } on NotFound {
        return Response.forbidden('Invalid token');
      } on io.SocketException {
        return authServerDown();
      } catch (error, stackTrace) {
        _log.severe(
            'Authentication validation lookup failed: $error:$stackTrace');

        return authServerDown();
      }

      /// Do not intercept the request, but let the next handler take care of it.
      return null;
    }

    final Middleware checkAuthentication = createMiddleware(
        requestHandler: _lookupToken, responseHandler: null);

    var router = Router();
    bindRoutes(router);

    var handler = const Pipeline()
        .addMiddleware(
        shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
        .addMiddleware(checkAuthentication)
        .addMiddleware(logRequests(logger: config.accessLog.onAccess))
        .addHandler(router.handler);

    _log.fine('Using server on ${_authService.host} as authentication backend');
    _log.fine('Accepting incoming REST requests on http://$hostname:$port');

    return shelf_io.serve(handler, hostname, port);
  }
}