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
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-authentication.dart' as controller;
import 'package:ors/response_utils.dart';
import 'package:ors/token_vault.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;
import 'package:shelf_router/shelf_router.dart' as shelf_route;

class Authentication {
  Authentication(this._tokenVault, this._userStore);

  final Logger _log = Logger('server.router.authentication');

  final TokenVault _tokenVault;
  final filestore.User _userStore;

  Future<io.HttpServer> start(
      {String hostname: '0.0.0.0', int port: 4050}) async {
    final authController =
        controller.Authentication(config.authServer, _userStore, _tokenVault);

    var router = shelf_route.Router()
      ..get('/token/create', authController.login)
      ..get('/token/oauth2callback', authController.oauthCallback)
      ..get('/token/<token>', authController.userinfo)
      ..get('/token/portraits', authController.userportraits)
      ..get('/token/<token>/validate', authController.validateToken)
      ..post('/token/<token>/invalidate', authController.invalidateToken)
      ..get('/token/<token>/refresh', authController.refresher)
      ..all('/<catch-all|.*>', (shelf.Request request) {
        return shelf.Response.notFound('Page not found');
      });

    var handler = const shelf.Pipeline()
        .addMiddleware(
            shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
        .addMiddleware(shelf.logRequests(logger: config.accessLog.onAccess))
        .addHandler(router.handler);

    _log.fine('Accepting incoming requests on $hostname:$port:');

    return await shelf_io.serve(handler, hostname, port);
  }
}
