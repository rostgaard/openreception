/*                  This file is part of OpenReception
                   Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

library ors.controller.dialplan;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:esl/esl.dart' as esl;
import 'package:esl/util.dart' as esl;
import 'package:esl/constants.dart' as esl;
import 'package:logging/logging.dart';
import 'package:orf/dialplan_tools.dart' as dialplanTools;
import 'package:orf/exceptions.dart';
import 'package:orf/filestore.dart' as database;
import 'package:orf/gzip_cache.dart' as gzip_cache;

import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:ors/configuration.dart';
import 'package:ors/controller/controller-ivr.dart';
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart' as shelf_route;

const _json = const JsonCodec();

/**
 * ReceptionDialplan controller class.
 */
class ReceptionDialplan {
  final database.ReceptionDialplan _receptionDialplanStore;
  final database.Reception _receptionStore;
  final dialplanTools.DialplanCompiler compiler;
  final String fsConfPath;
  final Ivr _ivrController;
  final service.Authentication _authService;
  final gzip_cache.DialplanCache _cache;

  final Logger _log = new Logger('server.controller.dialplan');
  esl.Connection _eslClient;
  final EslConfig eslConfig;

  /**
   *
   */
  ReceptionDialplan(
      this._receptionDialplanStore,
      this._receptionStore,
      this._authService,
      this.compiler,
      this._ivrController,
      this.fsConfPath,
      this.eslConfig,
      this._cache) {
    _connectESLClient();
  }

  /**
   *
   */
  Future<shelf.Response> analyze(shelf.Request request) async {
    final String extension = shelf_route.getPathParameter(request, 'extension');

    List<String> collectErrors(model.ReceptionDialplan rdp) =>
        throw new UnimplementedError();

    List<String> errors = [];
    try {
      errors = collectErrors(await _receptionDialplanStore.get(extension));
    } on FormatException {
      /// Could not parse dialplan
    } on NotFound {
      return notFound({});
    }

    return errors.isEmpty ? okJson({}) : clientErrorJson(errors);
  }

  /**
   *
   */
  Future<shelf.Response> create(shelf.Request request) async {
    final model.ReceptionDialplan rdp = new model.ReceptionDialplan.fromJson(
        _json.decode(await request.readAsString()) as Map<String, dynamic>);

    model.User user;
    try {
      user = await _authService.userOf(tokenFrom(request));
    } catch (e, s) {
      _log.warning('Could not connect to auth server', e, s);
      return authServerDown();
    }

    await _receptionDialplanStore.create(rdp, user);

    try {
      return okGzip(new Stream.fromIterable([await _cache.get(rdp.extension)]));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /**
   *
   */
  Future<shelf.Response> deploy(shelf.Request request) async {
    final String extension = shelf_route.getPathParameter(request, 'extension');
    final int rid = int.parse(shelf_route.getPathParameter(request, 'rid'));

    model.ReceptionDialplan rdp;
    model.Reception r;
    try {
      rdp = await _receptionDialplanStore.get(extension);
      r = await _receptionStore.get(rid);
    } on NotFound {
      return notFound('No dialplan with extension $extension');
    }
    final String xmlFilePath =
        fsConfPath + '/dialplan/receptions/$extension.xml';
    final List<String> generatedFiles = new List<String>.from([xmlFilePath]);

    _log.fine('Deploying new dialplan to file $xmlFilePath');
    await new File(xmlFilePath).writeAsString(compiler.dialplanToXml(rdp, r));

    /// Generate associated voicemail acccounts.
    final Iterable<model.Voicemail> voicemailAccounts =
        rdp.allActions.where((a) => a is model.Voicemail);

    generatedFiles.addAll((await writeVoicemailfiles(
        voicemailAccounts, compiler, _log, fsConfPath)));

    // /// Generate associated IVR menus.
    Iterable<model.Ivr> ivrMenus = rdp.allActions.where((a) => a is model.Ivr);

    generatedFiles.addAll(await _ivrController.writeIvrfiles(
        ivrMenus.map((menuAction) => menuAction.menuName), compiler, _log));

    return okJson(generatedFiles);
  }

  /**
   *
   */
  Future<shelf.Response> get(shelf.Request request) async {
    final String extension = shelf_route.getPathParameter(request, 'extension');

    try {
      return okGzip(new Stream.fromIterable([await _cache.get(extension)]));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /**
   *
   */
  Future<shelf.Response> list(shelf.Request request) async {
    try {
      return okGzip(new Stream.fromIterable(
          [(await _cache.list()).toList(growable: false)]));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /**
   *
   */
  Future<shelf.Response> reloadConfig(shelf.Request request) async {
    shelf.Response logAndReturn(esl.Response response) {
      final msg =
          'Failed to reload: PBX response: "${response.content}", status: ${response.status}';
      _log.shout(msg);
      return serverError(msg);
    }

    final esl.Response r = await _eslClient.api('reloadxml');

    if (r.isOk) {
      await _eslClient.eventStream.firstWhere((esl.Event e) {
        return e.eventName == 'RELOADXML';
      });

      return okJson(const {});
    } else {
      return logAndReturn(r);
    }
  }

  /**
   *
   */
  Future<shelf.Response> remove(shelf.Request request) async {
    final String extension = shelf_route.getPathParameter(request, 'extension');
    model.User user;

    try {
      user = await _authService.userOf(tokenFrom(request));
    } catch (e, s) {
      _log.warning('Could not connect to auth server', e, s);
      return authServerDown();
    }

    try {
      return okJson(await _receptionDialplanStore.remove(extension, user));
    } on NotFound {
      return notFound('No dialplan with extension $extension');
    }
  }

  /**
   *
   */
  Future<shelf.Response> update(shelf.Request request) async {
    final model.ReceptionDialplan rdp = new model.ReceptionDialplan.fromJson(
        _json.decode(await request.readAsString()) as Map<String, dynamic>);

    model.User user;
    try {
      user = await _authService.userOf(tokenFrom(request));
    } catch (e, s) {
      _log.warning('Could not connect to auth server', e, s);
      return authServerDown();
    }

    return okJson(await _receptionDialplanStore.update(rdp, user));
  }

/**
 * ESL client setup
 */
  Future _connectESLClient() async {
    //Duration period = new Duration(seconds: 3);
    final String hostname = eslConfig.hostname;
    final String password = eslConfig.password;

    final int port = eslConfig.port;

    _log.info('Connected to $hostname:$port');
    _eslClient = new esl.Connection(await Socket.connect(hostname, port));
    await esl.authHandler(_eslClient, password);
    _log.info('Connecting to $hostname:$port');

    await _eslClient.event(['RELOADXML'], format: esl.EventFormat.json);
  }

  /**
   *
   */
  Future<shelf.Response> history(shelf.Request request) async =>
      okJson((await _receptionDialplanStore.changes()).toList(growable: false));

  /**
   *
   */
  Future<shelf.Response> objectHistory(shelf.Request request) async {
    final String extension = shelf_route.getPathParameter(request, 'extension');

    if (extension == null || extension.isEmpty) {
      return clientError('Bad extension: $extension');
    }

    return okJson((await _receptionDialplanStore.changes(extension))
        .toList(growable: false));
  }

  /**
   *
   */
  Future<shelf.Response> changelog(shelf.Request request) async {
    final String extension = shelf_route.getPathParameter(request, 'extension');

    if (extension == null || extension.isEmpty) {
      return clientError('Bad extension: $extension');
    }

    return ok((await _receptionDialplanStore.changeLog(extension)));
  }
}
