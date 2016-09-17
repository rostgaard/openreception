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

library ors.router.authentication;

import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/configuration.dart';
import 'package:ors/controller/controller-authentication.dart' as controller;
import 'package:ors/response_utils.dart';
import 'package:ors/token_vault.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;
import 'package:shelf_route/shelf_route.dart' as shelf_route;

class Authentication {
  final Logger _log = new Logger('server.router.authentication');

  Future<io.HttpServer> start(Configuration config) async {
    final filestore.User _userStore =
        new filestore.User(config.filestorePath + '/user');
    final controller.Authentication authController =
        new controller.Authentication(config, _userStore, vault);

    var router = shelf_route.router()
      ..get('/token/create', authController.login)
      ..get('/token/oauth2callback', authController.oauthCallback)
      ..get('/token/{token}', authController.userinfo)
      ..get('/token/portraits', authController.userportraits)
      ..get('/token/{token}/validate', authController.validateToken)
      ..post('/token/{token}/invalidate', authController.invalidateToken)
      ..get('/token/{token}/refresh', authController.login);

    var handler = const shelf.Pipeline()
        .addMiddleware(
            shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
        //.addMiddleware(shelf.logRequests(logger: config.accessLog.onAccess))
        .addHandler(router.handler);

    _log.fine('Accepting incoming requests on '
        '${config.externalHostname}:${config.authServer.port}');
    shelf_route.printRoutes(router, printer: (String item) => _log.fine(item));

    return await shelf_io.serve(
        handler, config.externalHostname, config.authServer.port);
  }
}
