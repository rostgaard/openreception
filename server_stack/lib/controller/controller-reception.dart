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

library ors.controller.reception;

import 'dart:async';
import 'dart:convert';

import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/gzip_cache.dart' as gzip_cache;
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart' as shelf_route;
import 'package:logging/logging.dart';

const _json = const JsonCodec();

class Reception {
  final filestore.Reception _rStore;
  final service.Authentication _authservice;
  final service.NotificationService _notification;
  final gzip_cache.ReceptionCache _cache;
  final Logger _log = new Logger('ors.controller.reception');

  /**
   * Default constructor.
   */
  Reception(this._rStore, this._notification, this._authservice, this._cache);

  /**
   *
   */
  Future<shelf.Response> list(shelf.Request request) async {
    return okGzip(new Stream.fromIterable([await _cache.list()]));
  }

  /**
   *
   */
  Future<shelf.Response> get(shelf.Request request) async {
    final int rid = int.parse(shelf_route.getPathParameter(request, 'rid'));

    try {
      return okJson(await _rStore.get(rid));
    } on NotFound catch (error) {
      return notFound(error.toString());
    }
  }

  /**
   * shelf request handler for creating a new reception.
   */
  Future create(shelf.Request request) async {
    model.Reception reception;
    model.User creator;
    try {
      reception = await request.readAsString().then(_json.decode).then(
          (Map<String, dynamic> map) => new model.Reception.fromJson(map));
    } on FormatException catch (error) {
      Map response = {
        'status': 'bad request',
        'description': 'passed reception argument '
            'is too long, missing or invalid',
        'error': error.toString()
      };
      return clientErrorJson(response);
    }

    try {
      creator = await _authservice.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    final rRef = await _rStore.create(reception, creator);

    _cache.emptyList();

    final evt = new event.ReceptionChange.create(rRef.id, creator.id);
    try {
      await _notification.broadcastEvent(evt);
    } catch (e) {
      _log.warning('$e: Failed to send $evt');
    }
    return okJson(rRef);
  }

  /**
   * Update a reception.
   */
  Future update(shelf.Request request) async {
    model.Reception reception;
    model.User modifier;
    try {
      reception = await request.readAsString().then(_json.decode).then(
          (Map<String, dynamic> map) => new model.Reception.fromJson(map));
    } on FormatException catch (error) {
      Map response = {
        'status': 'bad request',
        'description': 'passed reception argument '
            'is too long, missing or invalid',
        'error': error.toString()
      };
      return clientErrorJson(response);
    }

    try {
      modifier = await _authservice.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    try {
      final rRef = await _rStore.update(reception, modifier);

      _cache.remove(rRef.id);
      _cache.emptyList();

      final evt = new event.ReceptionChange.update(rRef.id, modifier.id);
      try {
        await _notification.broadcastEvent(evt);
      } catch (e) {
        _log.warning('$e: Failed to send $evt');
      }
      return okJson(rRef);
    } on NotFound catch (e) {
      return notFound(e.toString());
    } on ClientError catch (e) {
      return clientError(e.toString());
    }
  }

  /**
   * Removes a single reception from the data store.
   */
  Future remove(shelf.Request request) async {
    final int rid = int.parse(shelf_route.getPathParameter(request, 'rid'));
    model.User modifier;

    try {
      modifier = await _authservice.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    try {
      await _rStore.remove(rid, modifier);

      _cache.remove(rid);

      _cache.emptyList();

      final evt = new event.ReceptionChange.delete(rid, modifier.id);
      try {
        await _notification.broadcastEvent(evt);
      } catch (e) {
        _log.warning('$e: Failed to send $evt');
      }

      return okJson({'status': 'ok', 'description': 'Reception deleted'});
    } on NotFound {
      return notFoundJson({'description': 'No reception found with ID $rid'});
    }
  }

  /**
   *
   */
  Future<shelf.Response> history(shelf.Request request) async =>
      okJson((await _rStore.changes()).toList(growable: false));

  /**
   *
   */
  Future<shelf.Response> objectHistory(shelf.Request request) async {
    final String ridParam = shelf_route.getPathParameter(request, 'rid');
    int rid;
    try {
      rid = int.parse(ridParam);
    } on FormatException {
      return clientError('Bad rid: $ridParam');
    }

    return okJson((await _rStore.changes(rid)).toList(growable: false));
  }

  /**
   *
   */
  Future<shelf.Response> changelog(shelf.Request request) async {
    final String ridParam = shelf_route.getPathParameter(request, 'rid');
    int rid;
    try {
      rid = int.parse(ridParam);
    } on FormatException {
      return clientError('Bad rid: $ridParam');
    }

    return ok((await _rStore.changeLog(rid)));
  }
}
