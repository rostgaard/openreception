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

library ors.router.reception;

import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:orf/exceptions.dart';
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-organization.dart' as controller;
import 'package:ors/controller/controller-reception.dart' as controller;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;
import 'package:shelf_router/shelf_router.dart' as shelf_route;

class Reception {
  Reception(
      this._authService, this._notification, this.reception, this.organization);

  final Logger _log = Logger('server.router.reception');
  final service.Authentication _authService;
  final service.NotificationService _notification;
  final controller.Organization organization;
  final controller.Reception reception;

  /// Validate a token by looking it up on the authentication server.
  Future<shelf.Response> _lookupToken(shelf.Request request) async {
    var token = request.requestedUri.queryParameters['token'];

    try {
      await _authService.validate(token);
    } on NotFound {
      return shelf.Response.forbidden('Invalid token');
    } on io.SocketException {
      return shelf.Response.internalServerError(
          body: 'Cannot reach authserver');
    } catch (error, stackTrace) {
      _log.severe(
          'Authentication validation lookup failed: $error:$stackTrace');

      return shelf.Response.internalServerError(body: error.toString());
    }

    /// Do not intercept the request, but let the next handler take care of it.
    return null;
  }

  /**
   *
   */
  void bindRoutes(dynamic router) {
    router
      ..get('/organization', organization.list)
      ..get('/organization/receptionmap', organization.receptionMap)
      ..post('/organization', organization.create)
      ..get('/organization/history', organization.history)
      ..get('/organization/<oid>', organization.get)
      ..put('/organization/<oid>', organization.update)
      ..delete('/organization/<oid>', organization.remove)
      ..get('/organization/<oid>/history', organization.objectHistory)
      ..get('/organization/<oid>/changelog', organization.changelog)
      ..get('/organization/<oid>/contact', organization.contacts)
      ..get('/organization/<oid>/reception', organization.receptions)
      ..get('/reception', reception.list)
      ..post('/reception', reception.create)
      ..get('/reception/history', reception.history)
      ..get('/reception/<rid>', reception.get)
      ..put('/reception/<rid>', reception.update)
      ..delete('/reception/<rid>', reception.remove)
      ..get('/reception/<rid>/history', reception.objectHistory)
      ..get('/reception/<rid>/changelog', reception.changelog)
      ..all('/<catch-all|.*>', (shelf.Request request) {
        return shelf.Response.notFound('Page not found');
      });
  }

  /**
   *
   */
  Future<io.HttpServer> listen(
      {String hostname: '0.0.0.0', int port: 4010}) async {
    // Authentication middleware.
    shelf.Middleware checkAuthentication = shelf.createMiddleware(
        requestHandler: _lookupToken, responseHandler: null);

    // Controllers.
    final router = shelf_route.Router();
    bindRoutes(router);

    final handler = const shelf.Pipeline()
        .addMiddleware(
            shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
        .addMiddleware(checkAuthentication)
        .addMiddleware(shelf.logRequests(logger: config.accessLog.onAccess))
        .addHandler(router.handler);

    _log.fine('Using server on ${_authService.host} as authentication backend');
    _log.fine('Using server on ${_notification.host} as notification backend');
    _log.fine('Accepting incoming REST requests on http://$hostname:$port');

    return await shelf_io.serve(handler, hostname, port);
  }
}
