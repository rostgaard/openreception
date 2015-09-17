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

library openreception.call_flow_control_server;

import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';
import 'package:path/path.dart';

import '../lib/callflowcontrol/configuration.dart' as json;
import '../lib/callflowcontrol/router.dart' as router;
import '../lib/callflowcontrol/controller.dart' as Controller;
import '../lib/callflowcontrol/model/model.dart' as Model;
import 'package:esl/esl.dart' as ESL;
import 'package:logging/logging.dart';
import '../lib/configuration.dart';

Logger log = new Logger ('CallFlowControl');
ArgResults parsedArgs;
ArgParser parser = new ArgParser();

void main(List<String> args) {

  ///Init logging. Inherit standard values.
  Logger.root.level = Configuration.callFlowControl.log.level;
  Logger.root.onRecord.listen(Configuration.callFlowControl.log.onRecord);

  try {
    Directory.current = dirname(Platform.script.toFilePath());

    registerAndParseCommandlineArguments(args);

    if (showHelp()) {
      print(parser.usage);
    } else {
      json.config = new json.Configuration(parsedArgs);
      json.config.whenLoaded()
        .then((_) => router.connectAuthService())
        .then((_) => router.connectNotificationService())
        .then((_) => router.startNotifier())
        .then((_) => connectESLClient())
        .then((_) => router.start(port : json.config.httpport))
        .catchError(log.shout);
    }
  } catch(error, stackTrace) {
    log.shout(error, stackTrace);
  }
}

void connectESLClient() {

  Duration period = new Duration(seconds : 3);

  log.info('Connecting to ${json.config.eslHostname}:${json.config.eslPort}');

  Model.PBXClient.instance = new ESL.Connection();

  Model.CallList.instance.subscribe(Model.PBXClient.instance.eventStream);

  //TODO: Channel-List subscriptions.
  Model.CallList.instance.subscribeChannelEvents(Model.ChannelList.event);

  Model.PBXClient.instance.eventStream
    .listen(Model.ChannelList.instance.handleEvent)
    .onDone(connectESLClient); // Reconnect

  Model.PeerList.subscribe(Model.PBXClient.instance.eventStream);

  /// Respond to server requests.
  Model.PBXClient.instance.requestStream.listen((ESL.Packet packet) {
    switch (packet.contentType) {
      case (ESL.ContentType.Auth_Request):
        log.info('Connected to ${json.config.eslHostname}:${json.config.eslPort}');
        Model.PBXClient.instance.authenticate(json.config.eslPassword)
          .then((_) => Model.PBXClient.instance.event
             (Model.PBXEvent.requiredSubscriptions,
                format : ESL.EventFormat.Json)
            ..catchError(log.shout))
          .then((_) => Controller.PBX.loadPeers())
          .then((_) => Controller.PBX.loadChannels()
          .then((_) => Model.CallList.instance.reloadFromChannels
            (Model.ChannelList.instance)));

        break;

      default:
        break;
    }
  });

  void tryConnect () {
    Model.PBXClient.instance.connect(json.config.eslHostname, json.config.eslPort).catchError((error, stackTrace) {
      if (error is SocketException) {
        log.severe('ESL Connection failed - reconnecting in ${period.inSeconds} seconds');
        new Timer(period, tryConnect);

      } else {
        log.severe('Failed to connect to FreeSWTICH.', error, stackTrace);
      }
    });
  }

  tryConnect ();
}

void registerAndParseCommandlineArguments(List<String> arguments) {
  parser..addFlag('help', abbr: 'h', help: 'Output this help')
        ..addOption('configfile', help: 'The JSON configuration file. Defaults to config.json')
        ..addOption('httpport', help: 'The port the HTTP server listens on.  Defaults to ${json.Default.httpport}')
        ..addOption('servertoken', help: 'servertoken');

  parsedArgs = parser.parse(arguments);
}

bool showHelp() => parsedArgs['help'];

