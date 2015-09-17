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

library openreception.call_flow_control_server.router;

import 'dart:async';
import 'dart:io' as IO;
import 'dart:convert';

import 'configuration.dart' as json;
import '../configuration.dart';

import 'controller.dart' as Controller;
import 'model/model.dart' as Model;

import 'package:openreception_framework/storage.dart'  as ORStorage;
import 'package:openreception_framework/service.dart' as Service;
import 'package:openreception_framework/service-io.dart' as Service_IO;
import 'package:openreception_framework/model.dart' as ORModel;
import 'package:openreception_framework/event.dart' as OREvent;

import 'package:logging/logging.dart';
import 'package:esl/esl.dart' as ESL;

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_route/shelf_route.dart' as shelf_route;
import 'package:shelf_cors/shelf_cors.dart' as shelf_cors;

part 'router/handler-user_state.dart';
part 'router/handler-call.dart';
part 'router/handler-channel.dart';
part 'router/handler-peer.dart';

const String libraryName = "callflowcontrol.router";
final Logger log = new Logger (libraryName);

const Map corsHeaders = const
  {'Access-Control-Allow-Origin': '*',
   'Access-Control-Allow-Methods' : 'GET, PUT, POST, DELETE'};

Service.Authentication AuthService = null;
Service.NotificationService Notification = null;

void connectAuthService() {
  AuthService = new Service.Authentication
      (json.config.authUrl, Configuration.callFlowControl.serverToken, new Service_IO.Client());
}

void connectNotificationService() {
  Notification = new Service.NotificationService
      (json.config.notificationServer, Configuration.callFlowControl.serverToken, new Service_IO.Client());
}

shelf.Middleware checkAuthentication =
  shelf.createMiddleware(requestHandler: _lookupToken, responseHandler: null);


Future<shelf.Response> _lookupToken(shelf.Request request) {
  var token = request.requestedUri.queryParameters['token'];

  return AuthService.validate(token).then((_) => null)
  .catchError((error) {
    if (error is ORStorage.NotFound) {
      return new shelf.Response.forbidden('Invalid token');
    }
    else if (error is IO.SocketException) {
      return new shelf.Response.internalServerError(body : 'Cannot reach authserver');
    }
    else {
      return new shelf.Response.internalServerError(body : error.toString());
    }
  });
}


/// Simple access logging.
void _accessLogger(String msg, bool isError) {
  if (isError) {
    log.severe(msg);
  } else {
    log.finest(msg);
  }
}

void startNotifier() {
  log.info('Starting client notifier');
  Model.CallList.instance.onEvent.listen(Notification.broadcastEvent);
}

Future<IO.HttpServer> start({String hostname : '0.0.0.0', int port : 4242}) {
  Controller.State stateController = new Controller.State();

  var router = shelf_route.router()
    ..get('/peer/list', Peer.list)
    ..get('/peer', Peer.list)
    ..get('/peer/{peerid}', Peer.get)
    ..get('/userstate/{uid}', UserState.get)
    //TODO: Dispatch to general UserState handler.
    ..post('/userstate/{uid}/idle', UserState.markIdle)
    ..post('/userstate/{uid}/loggedOut', UserState.logOut)
    ..post('/userstate/{uid}/paused', UserState.markPaused)
    ..post('/userstate/{uid}/keep-alive', UserState.keepAlive)
    ..get('/userstate', UserState.list)
    ..get('/call/{callid}', Call.get)
    ..get('/call', Call.list)
    ..post('/state/reload', stateController.reloadAll)
    ..get('/channel/list', Channel.list)
    ..get('/channel', Channel.list)
    ..post('/call/{callid}/hangup', Call.hangupSpecific)
    ..post('/call/{callid}/pickup', Call.pickupViaPark)
    ..post('/call/{callid}/park', Call.park)
    ..post('/call/originate/{extension}/reception/{rid}/contact/{cid}', Call.originateViaPark)
    ..post('/call/originate/{extension}@{host}:{port}/reception/{rid}/contact/{cid}', Call.originateViaPark)
    ..post('/call/{aleg}/transfer/{bleg}', Call.transfer)
    ..post('/call/reception/{rid}/record', Call.recordSound);

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf_cors.createCorsHeadersMiddleware(corsHeaders: corsHeaders))
      .addMiddleware(checkAuthentication)
      .addMiddleware(shelf.logRequests(logger : _accessLogger))
      .addHandler(router.handler);

  log.fine('Serving interfaces:');
  shelf_route.printRoutes(router, printer : log.fine);

  return shelf_io.serve(handler, hostname, port);
}

String _tokenFrom(shelf.Request request) =>
    request.requestedUri.queryParameters['token'];
