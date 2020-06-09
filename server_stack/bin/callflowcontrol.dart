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

library ors.call_flow;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:esl/constants.dart' as esl;
import 'package:esl/esl.dart' as esl;
import 'package:esl/util.dart' as esl;
import 'package:logging/logging.dart';
import 'package:orf/configuration.dart' as conf;
import 'package:orf/service-io.dart' as service;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-active_recording.dart' as controller;
import 'package:ors/controller/controller-call.dart' as controller;
import 'package:ors/controller/controller-channel.dart' as controller;
import 'package:ors/controller/controller-client_notifier.dart' as controller;
import 'package:ors/controller/controller-pbx.dart' as controller;
import 'package:ors/controller/controller-peer.dart' as controller;
import 'package:ors/controller/controller-state_reload.dart' as controller;
import 'package:ors/model.dart' as _model;
import 'package:ors/router/router-call.dart' as router;

Logger _log = Logger('callflow');
ArgResults _parsedArgs;
ArgParser _parser = ArgParser();

HttpServer _callflowChannel;

Future _startService(conf.EslConfig eslConf) async {
  final service.Authentication _authentication = service.Authentication(
      Uri.parse(_parsedArgs['auth-uri']),
      config.userServer.serverToken,
      service.Client());

  final service.NotificationService _notification =
      service.NotificationService(
          Uri.parse(_parsedArgs['notification-uri']),
          config.userServer.serverToken,
          service.Client());

  /// ESL clients.
  final esl.Connection eslClient = await _connectESLClient(eslConf);

  final _model.ChannelList channelList = _model.ChannelList();

  // PBX controller
  controller.PBX pbxController = controller.PBX(eslClient, channelList);

  // Local model classes
  final _model.CallList callList =
      _model.CallList(pbxController, channelList);
  final _model.PeerList peerList =
      _model.PeerList(_notification, channelList);
  final _model.ActiveRecordings activeRecordings =
      _model.ActiveRecordings();

  controller.Channel _channelController = controller.Channel(channelList);

  // Load initial state.
  await pbxController.loadPeers(peerList);
  await pbxController.loadChannels();

  callList.subscribe(eslClient.eventStream);

  // Send event subscription request to FreeSWITCH server.
  await eslClient.event(_model.PBXEvent.requiredSubscriptions,
      format: esl.EventFormat.json);

  controller.ClientNotifier(_notification, callList.onEvent);
  eslClient.eventStream.listen(channelList.handleEvent);
  eslClient.eventStream.listen(activeRecordings.handleEvent);

  controller.Call _callController = controller.Call(
      callList, channelList, peerList, pbxController, _authentication);

  final callRouter = router.Call(
      _callController,
      _channelController,
      controller.ActiveRecording(activeRecordings),
      controller.PhoneState(callList, peerList, pbxController),
      controller.Peer(peerList));

  pbxController.eslClient.eventStream.listen(peerList.handlePacket);

  _callflowChannel = await callRouter.start(
      hostname: _parsedArgs['host'], port: int.parse(_parsedArgs['httpport']));
  _log.fine(
      'Using server on ${_authentication.host} as authentication backend');
  _log.fine('Using server on ${_notification.host} as notification backend');
  _log.info('Ready to handle requests');
}

Future _stopService() async {
  await _callflowChannel.close();
}

/// Call-flow-control server.
Future main(List<String> args) async {
  ///Init logging. Inherit standard values.
  Logger.root.level = config.callFlowControl.log.level;
  Logger.root.onRecord.listen(config.callFlowControl.log.onRecord);

  _registerAndParseCommandlineArguments(args);

  if (_showHelp()) {
    print(_parser.usage);
    exit(1);
  }

  final String hostname = _parsedArgs['esl-hostname'];
  final String password = _parsedArgs['esl-password'];
  final int port = int.parse(_parsedArgs['esl-port']);

  await _startService(
      conf.EslConfig(hostname: hostname, password: password, port: port));
}

Future<esl.Connection> _connectESLClient(conf.EslConfig eslConf) async {
  final Duration reconnectPeriod = Duration(seconds: 3);

  Future<esl.Connection> tryConnect() async {
    _log.info('Connecting to ${eslConf.toDsn()}');

    try {
      final Socket socket =
          await Socket.connect(eslConf.hostname, eslConf.port);

      final esl.Connection connection =
          esl.Connection(socket, onDisconnect: () async {
        await _stopService();
        await socket.close();

        await _startService(eslConf);
      });

      // Await a successful authentication.
      await esl.authHandler(connection, eslConf.password);

      return connection;
    } on SocketException {
      _log.severe('ESL Connection failed - reconnecting '
          'in ${reconnectPeriod.inSeconds} seconds');

      await Future.delayed(reconnectPeriod);
      return tryConnect();
    } on esl.AuthenticationFailure {
      _log.severe('ESL Connection failed - reconnecting '
          'in ${reconnectPeriod.inSeconds} seconds');

      await Future.delayed(reconnectPeriod);
      return tryConnect();
    }
  }

  return tryConnect();
}

void _registerAndParseCommandlineArguments(List<String> arguments) {
  _parser
    ..addFlag('help', help: 'Output this help')
    ..addOption('httpport',
        defaultsTo: config.callFlowControl.httpPort.toString(),
        help: 'The port the HTTP server listens on.')
    ..addOption('host',
        abbr: 'h',
        defaultsTo: config.configserver.externalHostName,
        help: 'The hostname or IP listen-address for the HTTP server')
    ..addOption('esl-hostname',
        defaultsTo: config.callFlowControl.eslConfig.hostname,
        help: 'The hostname of the ESL server')
    ..addOption('esl-password',
        defaultsTo: config.callFlowControl.eslConfig.password,
        help: 'The password for the ESL server')
    ..addOption('esl-port',
        defaultsTo: config.callFlowControl.eslConfig.port.toString(),
        help: 'The port of the ESL server')
    ..addOption('auth-uri',
        defaultsTo: config.authServer.externalUri.toString(),
        help: 'The uri of the authentication server')
    ..addOption('notification-uri',
        defaultsTo: config.notificationServer.externalUri.toString(),
        help: 'The uri of the notification server');

  _parsedArgs = _parser.parse(arguments);
}

bool _showHelp() => _parsedArgs['help'];
