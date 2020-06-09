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

library ors.user;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/model.dart' as model;
import 'package:orf/service-io.dart' as service;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-agent_statistics.dart' as controller;
import 'package:ors/controller/controller-client_notifier.dart' as controller;
import 'package:ors/controller/controller-group_notifier.dart' as controller;
import 'package:ors/controller/controller-user.dart' as controller;
import 'package:ors/controller/controller-user_state.dart' as controller;
import 'package:ors/model.dart' as model;
import 'package:ors/router/router-user.dart' as router;


Future main(List<String> args) async {
  ///Init logging. Inherit standard values.
  Logger.root.level = config.userServer.log.level;
  Logger.root.onRecord.listen(config.userServer.log.onRecord);

  Logger log = Logger('UserServer');

  final ArgParser parser = new ArgParser()
    ..addFlag('help', help: 'Output this help', negatable: false)
    ..addOption('filestore', abbr: 'f',
      defaultsTo: '/Users/krs/projects/openreception-filestore',
      help: 'Path to the filestore backend',)
    ..addOption('httpport',
        abbr: 'p',
        defaultsTo: config.userServer.httpPort.toString(),
        help: 'The port the HTTP server listens on.')
    ..addOption('host',
        abbr: 'h',
        defaultsTo: config.userServer.externalHostName,
        help: 'The hostname or IP listen-address for the HTTP server')
    ..addOption('auth-uri',
        defaultsTo: config.authServer.externalUri.toString(),
        help: 'The uri of the authentication server')
    ..addOption('notification-uri',
        defaultsTo: config.notificationServer.externalUri.toString(),
        help: 'The uri of the notification server')
    ..addFlag('experimental-revisioning',
        defaultsTo: false,
        help: 'Enable or disable experimental Git revisioning on this server');


  final ArgResults parsedArgs = parser.parse(args);

  if (parsedArgs['help']) {
    print(parser.usage);
    exit(1);
  }

  if (parsedArgs['filestore'] == null) {
    print('Filestore path is required');
    print(parser.usage);
    exit(1);
  }

  final service.Authentication _authService = service.Authentication.withHost(
      Uri.parse(parsedArgs['auth-uri']),
      config.userServer.serverToken);

  final service.NotificationService _notification =
  new service.NotificationService(Uri.parse(parsedArgs['notification-uri']),
      config.userServer.serverToken, null);

  final Uri notificationUri =
  Uri.parse('ws://${_notification.host.host}:${_notification.host.port}'
      '/notifications?token=${config.contactServer.serverToken}');

  final service.WebSocket wsClient =
  await (new service.WebSocketClient()).connect(notificationUri);

  final service.NotificationSocket _notificationSocket =
  new service.NotificationSocket(wsClient);

  final bool revisioning = parsedArgs['experimental-revisioning'];

  final gitEngine = revisioning
      ? new filestore.GitEngine(parsedArgs['filestore'] + '/user')
      : null;

  final filestore.User _userStore =
  new filestore.User(parsedArgs['filestore'] + '/user', gitEngine);

  final filestore.AgentHistory _agentHistory = new filestore.AgentHistory(
      parsedArgs['filestore'] + '/agent_history',
      _userStore,
      _notificationSocket.onEvent);

  final model.UserStatusList userStatus = new model.UserStatusList();
  final Map<int, event.WidgetSelect> _userUIState = {};
  final Map<int, event.FocusChange> _userFocusState = {};

  // Fill serviceagent cache initially.
  final List<int> _serviceAgentCache = await _loadServiceAgents(_userStore);

  final controller.GroupNotifier groupNotifier =
  new controller.GroupNotifier(_notification, _serviceAgentCache);

  _notificationSocket.onWidgetSelect.listen((event.WidgetSelect widgetSelect) {
    _userUIState[widgetSelect.uid] = widgetSelect;
  });

  _notificationSocket.onFocusChange.listen((event.FocusChange focusChange) {
    _userFocusState[focusChange.uid] = focusChange;
  });

  final _userController =
  new controller.User(_userStore, _notification, _authService);
  final _statsController = new controller.AgentStatistics(_agentHistory);

  final _userStateController =
  new controller.UserState(userStatus, _userUIState, _userFocusState);

  /// Client notification controller.
  new controller.ClientNotifier(_notification, userStatus.onChange);

  /// Respond to future user changes.
  _userStore.onUserChange.listen((event.UserChange uc) async {
    log.info('Reloading service agent cache');
    groupNotifier.recipientUids = await _loadServiceAgents(_userStore);
  });

  /// Forward events to service agents and administrators.
  groupNotifier.listenAll(
      [_notificationSocket.onWidgetSelect, _notificationSocket.onFocusChange]);

  await _agentHistory.initialized;

  await (new router.User(_notification, _userController, _statsController,
      _userStateController))
      .listen(
      hostname: parsedArgs['host'],
      port: int.parse(parsedArgs['httpport']));
  log.info('Ready to handle requests');
}

/**
 *
 */
Future<Iterable<int>> _loadServiceAgents(filestore.User userStore) async {
  final Iterable allUids = (await userStore.list()).map((u) => u.id);
  final List<String> saGroups =
      [model.UserGroups.serviceAgent, model.UserGroups.administrator];

  final List<int> uids = [];
  await Future.forEach(allUids, (uid) async {
    List<String> groups = (await userStore.get(uid)).groups;
    Set<String> commonGroups = groups.toSet().intersection(saGroups.toSet());

    if (commonGroups.isNotEmpty) {
      uids.add(uid);
    }
  });

  return uids;
}