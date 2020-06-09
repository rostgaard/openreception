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

library ors.controller.config;

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart';

/// Configuration controller class.
class Config {
  final Logger _log = Logger('controller.config');

  /// The current client configuration.
  final model.Configuration clientConfig =
      model.Configuration()
        ..authServerUri = config.configserver.authServerUri.toString()
        ..calendarServerUri = config.configserver.calendarServerUri.toString()
        ..callFlowServerUri = config.configserver.callFlowControlUri.toString()
        ..cdrServerUri = config.configserver.cdrServerUri.toString()
        ..contactServerUri = config.configserver.contactServerUri.toString()
        ..dialplanServerUri = config.configserver.dialplanServerUri.toString()
        ..hideInboundCallerId = config.hideInboundCallerId
        ..messageServerUri = config.configserver.messageServerUri.toString()
        ..myIdentifiers = config.myIdentifiers
        ..notificationServerUri = config.configserver.notificationServerUri.toString()
        ..notificationSocketUri = config.configserver.notificationSocketUri.toString()
        ..receptionServerUri = config.configserver.receptionServerUri.toString()
        ..systemLanguage = config.systemLanguage
        ..userServerUri = config.configserver.userServerUri.toString();

  /// Get the client configuration.
  Future<Response> get(Request request) async => okJson(clientConfig);

  /// Overload a server endpoint in the client configuration
  Future<Response> register(Request request) async {
    service.ServerType serverType;

    try {
      final Map<String, dynamic> body =
          json.decode(await request.readAsString());

      for (String value in body.keys) {
        serverType = service.decodeServerType(value);
        final uri = Uri.parse(body[value]).toString();
        switch (serverType) {
          case service.ServerType.authentication:
            clientConfig.authServerUri = uri;
            break;
          case service.ServerType.calendar:
            clientConfig.calendarServerUri = uri;
            break;
          case service.ServerType.callflow:
            clientConfig.callFlowServerUri = uri;
            break;
          case service.ServerType.cdr:
            clientConfig.cdrServerUri = uri;
            break;
          case service.ServerType.contact:
            clientConfig.contactServerUri = uri;
            break;
          case service.ServerType.dialplan:
            clientConfig.dialplanServerUri = uri;
            break;
          case service.ServerType.message:
            clientConfig.messageServerUri = uri;
            break;
          case service.ServerType.notification:
            clientConfig.notificationServerUri = uri;
            break;
          case service.ServerType.notificationSocket:
            clientConfig.notificationSocketUri = uri;
            break;
          case service.ServerType.reception:
            clientConfig.receptionServerUri = uri;
            break;
          case service.ServerType.user:
            clientConfig.userServerUri = uri;
            break;
          default:
            _log.warning('Uknown type of registration: $serverType');
        }
      }
    } on FormatException catch (e) {
      return clientError('Bad parameters: $e');
    } on StateError catch (e) {
      return clientError('Bad parameters: $e');
    } catch (e, s) {
      return clientError('Bad parameters: $e $s');
    }

    return okJson(const <String, String>{});
  }
}
