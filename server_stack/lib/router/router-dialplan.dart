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

library ors.router.dialplan;

import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:orf/exceptions.dart';
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors'
    '/controller/controller-ivr.dart' as controller;
import 'package:ors'
    '/controller/controller-peer_account.dart' as controller;
import 'package:ors'
    '/controller/controller-reception_dialplan.dart' as controller;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;
import 'package:shelf_router/shelf_router.dart';

/// Dialplan router class.
class Dialplan {
  Dialplan(this._authService, this._ivrController, this._paController,
      this._rdpController);

  final Logger _log = Logger('server.router.dialplan');
  final controller.Ivr _ivrController;
  final controller.PeerAccount _paController;
  final controller.ReceptionDialplan _rdpController;
  final service.Authentication _authService;

  /// Validate a token by looking it up on the authentication server.
  Future<Response> _lookupToken(Request request) async {
    final token = request.url.queryParameters['token'];
    try {
      await _authService.validate(token);
    } on NotFound {
      return Response.forbidden('Invalid token');
    } on io.SocketException {
      return authServerDown();
    } catch (error, stackTrace) {
      _log.severe(
          'Authentication validation lookup failed: $error:$stackTrace');

      return Response.internalServerError(body: error.toString());
    }

    /// Do not intercept the request, but let the next handler take care of it.
    return null;
  }

  /**
   *
   */
  void bindRoutes(final Router router) {
    router
      ..post('/peeraccount/user/<uid>/deploy', _paController.deploy)
      ..get('/peeraccount', _paController.list)
      ..get('/peeraccount/<aid>', _paController.get)
      ..delete('/peeraccount/<aid>', _paController.remove)
      ..get('/ivr', _ivrController.list)
      ..get('/ivr/<name>', _ivrController.get)
      ..put('/ivr/<name>', _ivrController.update)
      ..post('/ivr/<name>/deploy', _ivrController.deploy)
      ..delete('/ivr/<name>', _ivrController.remove)
      ..get('/ivr/<name>/history', _ivrController.objectHistory)
      ..get('/ivr/<name>/changelog', _ivrController.changelog)
      ..post('/ivr', _ivrController.create)
      ..get('/ivr/history', _ivrController.history)
      ..get('/receptiondialplan', _rdpController.list)
      ..get('/receptiondialplan/<extension>', _rdpController.get)
      ..put('/receptiondialplan/<extension>', _rdpController.update)
      ..post('/receptiondialplan/reloadConfig', _rdpController.reloadConfig)
      ..get('/receptiondialplan/<extension>/history',
          _rdpController.objectHistory)
      ..get(
          '/receptiondialplan/<extension>/changelog', _rdpController.changelog)
      ..delete('/receptiondialplan/<extension>', _rdpController.remove)
      ..post('/receptiondialplan', _rdpController.create)
      ..get('/receptiondialplan/history', _rdpController.history)
      ..post('/receptiondialplan/<extension>/analyze', _rdpController.analyze)
      ..post(
          '/receptiondialplan/<extension>/deploy/<rid>', _rdpController.deploy)
      ..all('/<catch-all|.*>', (Request request) {
        return Response.notFound('Page not found');
      });
  }

  /**
   *
   */
  Future<io.HttpServer> listen(
      {String hostname: '0.0.0.0', int port: 4060}) async {
    /**
     * Authentication middleware.
     */
    // Middleware checkAuthentication =
    //     createMiddleware(requestHandler: _lookupToken, responseHandler: null);

    final router = Router();
    bindRoutes(router);

    final handler = const Pipeline()
        .addMiddleware(
            shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
        //.addMiddleware(_lookupToken)
        .addMiddleware(logRequests(logger: config.accessLog.onAccess))
        .addHandler(router.handler);

    _log.fine('Accepting incoming requests on $hostname:$port:');
    _log.fine('Using server on ${_authService.host} as authentication backend');

    //shelf_route.printRoutes(router, printer: (String item) => _log.fine(item));

    return await io.serve(handler, hostname, port);
  }
}
