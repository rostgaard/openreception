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

library ors.call_flow_control_server.router;

import 'dart:async';
import 'dart:io' as io;

import 'package:logging/logging.dart';
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-active_recording.dart' as controller;
import 'package:ors/controller/controller-call.dart' as controller;
import 'package:ors/controller/controller-channel.dart' as controller;
import 'package:ors/controller/controller-peer.dart' as controller;
import 'package:ors/controller/controller-state_reload.dart' as controller;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;
import 'package:shelf_router/shelf_router.dart' as shelf_route;

const Map<String, String> corsHeaders = const {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE'
};

/**
 *
 */
class Call {
  Call(
      this._callController,
      this._channelController,
      this._activeRecordingController,
      this._phoneStateController,
      this._peerController);

  final Logger _log = new Logger('server.router.call');
  final controller.PhoneState _phoneStateController;
  final controller.Peer _peerController;
  final controller.Call _callController;
  final controller.Channel _channelController;
  final controller.ActiveRecording _activeRecordingController;

  /**
   *
   */
  void bindRoutes(dynamic router) {
    router
      ..get('/peer', _peerController.list)
      ..get('/peer/<peerid>', _peerController.get)
      ..get('/call/<callid>', _callController.get)
      ..post('/call/<callid>', _callController.update)
      ..delete('/call/<callid>', _callController.remove)
      ..get('/call', _callController.list)
      ..post('/state/reload', _phoneStateController.reloadAll)
      ..get('/channel', _channelController.list)
      ..get('/channel/<chanid>', _channelController.get)
      ..get('/activerecording', _activeRecordingController.list)
      ..get('/activerecording/<cid>', _activeRecordingController.get)
      ..post('/call/<callid>/hangup', _callController.hangupSpecific)
      ..post('/call/<callid>/pickup', _callController.pickup)
      ..post('/call/<callid>/park', _callController.park)
      ..post(
          '/call/originate/<extension>/dialplan/<dialplan>'
          '/reception/<rid>/contact/<cid>',
          _callController.originate)
      ..post(
          '/call/originate/<extension>/dialplan/<dialplan>'
          '/reception/<rid>/contact/<cid>/call/<callId>',
          _callController.originate)
      ..post('/call/<aleg>/transfer/<bleg>', _callController.transfer)
      ..all('/<catch-all|.*>', (Request request) {
        return Response.notFound('Page not found');
      });
  }

  Future<io.HttpServer> start(
      {String hostname: '0.0.0.0', int port: 4242}) async {
    _log.info('Starting client notifier');

    final router = shelf_route.Router();
    bindRoutes(router);

    var handler = const Pipeline()
        .addMiddleware(
            shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
        .addMiddleware(logRequests(logger: config.accessLog.onAccess))
        .addHandler(router.handler);

    _log.fine('Accepting incoming REST requests on http://$hostname:$port');

    final server = await io.HttpServer.bind(hostname, port, shared: true);

    shelf_io.serveRequests(server, handler);

    return server;
  }
}
