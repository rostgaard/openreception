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

library ors.router.contact;

import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-contact.dart' as controller;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;
import 'package:shelf_router/shelf_router.dart' as shelf_route;

/**
 *
 */
class Contact {
  /**
   *
   */
  Contact(this._authService, this._notification, this._contactController);

  final Logger _log = Logger('server.router.contact');
  final controller.Contact _contactController;
  final service.Authentication _authService;

  final service.NotificationService _notification;


  /**
   *
   */
  void bindRoutes(dynamic router) {
    router
      ..get('/contact/history', _contactController.history)
      ..get('/contact/list/reception/<rid>', _contactController.listByReception)
      ..post(
          '/contact/<cid>/reception/<rid>', _contactController.addToReception)
      ..put('/contact/<cid>/reception/<rid>',
          _contactController.updateInReception)
      ..delete('/contact/<cid>/reception/<rid>',
          _contactController.removeFromReception)
      ..get('/contact/<cid>/reception/<rid>/history',
          _contactController.receptionHistory)
      ..get('/contact/<cid>/reception/changelog',
          _contactController.receptionChangelog)
      ..get('/contact/<cid>/reception/<rid>', _contactController.get)
      ..get('/contact/<cid>/reception', _contactController.receptions)
      ..get('/contact/<cid>/organization', _contactController.organizations)
      ..get('/contact/<cid>', _contactController.base)
      ..put('/contact/<cid>', _contactController.update)
      ..delete('/contact/<cid>', _contactController.remove)
      ..get('/contact/<cid>/history', _contactController.objectHistory)
      ..get('/contact/<cid>/changelog', _contactController.changelog)
      ..get('/contact', _contactController.listBase)
      ..post('/contact', _contactController.create)
      ..get(
          '/contact/organization/<oid>', _contactController.listByOrganization)
      ..get('/contact/reception/<rid>', _contactController.listByReception)
      ..all('/<catch-all|.*>', (shelf.Request request) {
        return shelf.Response.notFound('Page not found');
      });
  }

  /**
   *
   */
  Future<io.HttpServer> listen(
      {String hostname: '0.0.0.0', int port: 4010}) async {
    final router = shelf_route.Router();
    bindRoutes(router);

    var handler = const shelf.Pipeline()
        .addMiddleware(
        shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
        .addMiddleware(shelf.logRequests(logger: config.accessLog.onAccess))
        .addHandler(router.handler);

    _log.fine('Using server on ${_authService.host} as authentication backend');
    _log.fine('Using server on ${_notification.host} as notification backend');
    _log.fine('Accepting incoming REST requests on http://$hostname:$port');

    return await shelf_io.serve(handler, hostname, port);
  }
}