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

library ors.router.message;

import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-message.dart' as controller;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;
import 'package:shelf_router/shelf_router.dart' as shelf_route;

class Message {
  Message(this._authService, this._notification, this._msgController);

  final Logger _log = Logger('server.router.message');
  final service.Authentication _authService;
  final service.NotificationService _notification;

  final controller.Message _msgController;


  /**
   *
   */
  void bindRoutes(dynamic router) {
    router
      ..get('/message/list/drafts', _msgController.listDrafts)
      ..get('/message/list/<day>', _msgController.list)
      ..post('/message/list', _msgController.queryById)
      ..get('/message', _msgController.listToday)
      ..get('/message/history', _msgController.history)
      ..get('/message/<mid>', _msgController.get)
      ..put('/message/<mid>', _msgController.update)
      ..delete('/message/<mid>', _msgController.remove)
      ..post('/message/<mid>/send', _msgController.send)
      ..get('/message/<mid>/history', _msgController.objectHistory)
      ..post('/message', _msgController.create)
      ..all('/<catch-all|.*>', (shelf.Request request) {
        return shelf.Response.notFound('Page not found');
      });
  }

  /**
   *
   */
  Future<io.HttpServer> listen({String hostname: 'localhost', int port: 4040}) {
    final router = shelf_route.Router();
    bindRoutes(router);

    final handler = const shelf.Pipeline()
        .addMiddleware(
        shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
        .addMiddleware(shelf.logRequests(logger: config.accessLog.onAccess))
        .addHandler(router.handler);

    _log.fine('Using server on ${_authService.host} as authentication backend');
    _log.fine('Using server on ${_notification.host} as notification backend');
    _log.fine('Accepting incoming REST requests on http://$hostname:$port');

    return shelf_io.serve(handler, hostname, port);
  }
}