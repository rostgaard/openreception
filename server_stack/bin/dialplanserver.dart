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

library ors.dialplan;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:orf/dialplan_tools.dart' as dialplanTools;
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/gzip_cache.dart' as gzip_cache;
import 'package:orf/service-io.dart' as service;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors'
    '/controller/controller-ivr.dart' as controller;
import 'package:ors'
    '/controller/controller-peer_account.dart' as controller;
import 'package:ors'
    '/controller/controller-reception_dialplan.dart' as controller;
import 'package:ors/router/router-dialplan.dart' as router;

Future main(List<String> args) async {
  ///Init logging.
  Logger.root.level = config.dialplanserver.log.level;
  Logger.root.onRecord.listen(config.dialplanserver.log.onRecord);
  Logger _log = new Logger('dialplan_server');

  ///Handle argument parsing.
  final ArgParser parser = new ArgParser()
    ..addFlag('help', help: 'Output this help', negatable: false)
    ..addOption('filestore', abbr: 'f', help: 'Path to the filestore backend')
    ..addOption('playback-prefix',
        help: ''
            'Defaults to ${config.dialplanserver.playbackPrefix}',
        defaultsTo: config.dialplanserver.playbackPrefix)
    ..addOption('freeswitch-conf-path',
        help: 'Path to the FreeSWITCH conf directory.'
            'Defaults to ${config.dialplanserver.freeswitchConfPath}',
        defaultsTo: config.dialplanserver.freeswitchConfPath)
    ..addOption('httpport',
        abbr: 'p',
        defaultsTo: config.dialplanserver.httpPort.toString(),
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
    ..addFlag('experimental-revisioning',
        defaultsTo: false,
        help: 'Enable or disable experimental Git revisioning on this server');

  final ArgResults parsedArgs = parser.parse(args);

  void exitWithError(String error) {
    if (error.isNotEmpty) {
      stderr.writeln(error + '\n');
    }
    print(parser.usage);
    exit(1);
  }

  if (parsedArgs['help']) {
    exitWithError('');
  }

  final String playbackPrefix = parsedArgs['playback-prefix'];
  final String fsConfPath = parsedArgs['freeswitch-conf-path'];

  final String filepath = parsedArgs['filestore'];
  if (filepath == null || filepath.isEmpty) {
    stderr.writeln('Filestore path is required');
    print('');
    print(parser.usage);
    exit(1);
  }

  /// Parse port argument;
  int port;
  try {
    port = _parsePort(parsedArgs['httpport']);
  } on FormatException {
    exitWithError('Bad port argument: ${parsedArgs['httpport']}');
  }

  /// Parse authserver argument;
  Uri authUri;
  try {
    authUri = Uri.parse(parsedArgs['auth-uri']);
  } on FormatException {
    exitWithError('Bad auth-uri argument: ${parsedArgs['auth-uri']}');
  }

  final EslConfig eslConfig = new EslConfig(
      hostname: parsedArgs['esl-hostname'],
      password: parsedArgs['esl-password'],
      port: int.parse(parsedArgs['esl-port']));

  final bool revisioning = parsedArgs['experimental-revisioning'];

  final service.Authentication _authentication = new service.Authentication(
      authUri, config.userServer.serverToken, new service.Client());

  /**
   * Controllers.
   */

  final filestore.Ivr _ivrStore = new filestore.Ivr(filepath + '/ivr',
      revisioning ? new filestore.GitEngine(filepath + '/ivr') : null);

  final filestore.ReceptionDialplan _dpStore = new filestore.ReceptionDialplan(
      filepath + '/dialplan',
      revisioning ? new filestore.GitEngine(filepath + '/dialplan') : null);

  final filestore.Reception _rStore =
      new filestore.Reception(filepath + '/reception');
  final filestore.User _userStore = new filestore.User(filepath + '/user');

  /// Setup dialplan tools.
  final dialplanTools.DialplanCompiler compiler =
      new dialplanTools.DialplanCompiler(new dialplanTools.DialplanCompilerOpts(
          goLive: config.dialplanserver.goLive,
          greetingDir: playbackPrefix,
          testNumber: config.dialplanserver.testNumber,
          testEmail: config.dialplanserver.testEmail,
          callerIdName: config.callFlowControl.callerIdName,
          callerIdNumber: config.callFlowControl.callerIdNumber));

  _log.info('Dialplan tools are ${compiler.option.goLive ? 'live ' : 'NOT live '
      'diverting all voicemails to ${compiler.option.testEmail} and directing '
      'all calls to ${compiler.option.testNumber}'}');
  _log.fine('Deploying generated xml files to $fsConfPath subdirs');

  gzip_cache.DialplanCache _cache =
      new gzip_cache.DialplanCache(_dpStore, _dpStore.onChange);

  final controller.Ivr ivrHandler =
      new controller.Ivr(_ivrStore, compiler, _authentication, fsConfPath);

  final controller.ReceptionDialplan receptionDialplanHandler =
      new controller.ReceptionDialplan(_dpStore, _rStore, _authentication,
          compiler, ivrHandler, fsConfPath, eslConfig);

  final controller.PeerAccount peerAccountHandler =
      new controller.PeerAccount(_userStore, compiler, fsConfPath);

  await receptionDialplanHandler.ready;
  await router.Dialplan(_authentication, ivrHandler, peerAccountHandler,
          receptionDialplanHandler)
      .listen(hostname: parsedArgs['host'], port: port);
  _log.info('Ready to handle requests');
}

int _parsePort(String value) {
  int port = int.parse(value);
  if (port < 1 || port > 65535) {
    throw new FormatException();
  }
  return port;
}
