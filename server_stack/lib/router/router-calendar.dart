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

library ors.router.calendar;

import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:orf/exceptions.dart';
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-calendar.dart' as controller;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;

class Calendar {
  final Logger _log = new Logger('server.router.calendar');

  final service.Authentication _authService;
  final service.NotificationService _notification;
  final controller.Calendar _calendarController;

  Calendar(this._authService, this._notification, this._calendarController);

  /**
   * Validate a token by looking it up on the authentication server.
   */
  Future<shelf.Response> _lookupToken(shelf.Request request) async {
    var token = request.requestedUri.queryParameters['token'];

    try {
      await _authService.validate(token);
    } on NotFound {
      return new shelf.Response.forbidden('Invalid token');
    } on io.SocketException {
      return new shelf.Response.internalServerError(
          body: 'Cannot reach authserver');
    } catch (error, stackTrace) {
      _log.severe(
          'Authentication validation lookup failed: $error:$stackTrace');

      return new shelf.Response.internalServerError(body: error.toString());
    }

    /// Do not intercept the request, but let the next handler take care of it.
    return null;
  }

  /**
   *
   */
  void bindRoutes(dynamic router) {
    router
      ..get('/calendar/cache', _calendarController.cacheStats)
      ..post('/calendar/cache/prefill', _calendarController.cachePrefill)
      ..delete('/calendar/cache', _calendarController.emptyCache)
      ..get('/calendar/{type}:{oid}', _calendarController.list)
      ..get('/calendar/{type}:{oid}/change', _calendarController.changes)
      ..get('/calendar/{type}:{oid}/changelog', _calendarController.changelog)
      ..get('/calendar/{type}:{oid}/{eid}', _calendarController.get)
      ..get('/calendar/{type}:{oid}/{eid}/change', _calendarController.changes)
      ..get('/calendar/{type}:{oid}/{eid}/deleted',
          _calendarController.getDeleted)
      ..put('/calendar/{type}:{oid}/{eid}', _calendarController.update)
      ..post('/calendar/{type}:{oid}', _calendarController.create)
      ..delete('/calendar/{type}:{oid}/{eid}', _calendarController.remove);
  }

  /**
   *
   */
  Future<io.HttpServer> listen(
      {String hostname: '0.0.0.0', int port: 4110}) async {
    /**
     * Authentication middleware.
     */
    shelf.Middleware checkAuthentication = shelf.createMiddleware(
        requestHandler: _lookupToken, responseHandler: null);

    Router routes = new Router()
      ..get('/item/{itemid}', handler.doItem);

    var handler = const shelf.Pipeline()
        .addMiddleware(
            shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
        .addMiddleware(checkAuthentication)
        .addMiddleware(shelf.logRequests(logger: config.accessLog.onAccess))
    .
        .addHandler(router.handler);

    _log.fine('Using server on ${_authService.host} as authentication backend');
    _log.fine('Using server on ${_notification.host} as notification backend');
    _log.fine('Accepting incoming REST requests on http://$hostname:$port');
    _log.fine('Serving routes:');
    shelf_route.printRoutes(router, printer: (String item) => _log.fine(item));

    return await shelf_io.serve(handler, hostname, port);
  }
}
