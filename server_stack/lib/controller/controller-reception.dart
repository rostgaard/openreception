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

import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart';

class Reception {
  /// Default constructor.
  Reception(this._rStore, this._notification, this._authservice);

  final filestore.Reception _rStore;
  final service.Authentication _authservice;
  final service.NotificationService _notification;
  final Logger _log = Logger('ors.controller.reception');

  /**
   *
   */
  Future<Response> list(Request request) async {
    return okJson((await _rStore.list()).toList(growable: false));
  }

  Future<Response> get(Request request, String ridParam) async {
    final int rid = int.parse(ridParam);

    try {
      return okJson(await _rStore.get(rid));
    } on NotFound catch (error) {
      return notFound(error.toString());
    }
  }

  /// Request handler for creating a reception.
  Future<Response> create(Request request) async {
    model.Reception reception;
    model.User creator;
    try {
      reception =
          model.Reception.fromJson(json.decode(await request.readAsString()));
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

    final evt = event.ReceptionChange.create(rRef.id, creator.id);
    try {
      await _notification.broadcastEvent(evt);
    } catch (e) {
      _log.warning('$e: Failed to send $evt');
    }
    return okJson(rRef);
  }

  /// Update a reception.
  Future<Response> update(Request request, String ridParam) async {
    model.Reception reception;
    model.User modifier;
    try {
      reception =
          model.Reception.fromJson(json.decode(await request.readAsString()));
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

      final evt = event.ReceptionChange.update(rRef.id, modifier.id);
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

  /// Removes a single reception from the data store.
  Future<Response> remove(Request request, String ridParam) async {
    final int rid = int.parse(ridParam);
    model.User modifier;

    try {
      modifier = await _authservice.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    try {
      await _rStore.remove(rid, modifier);

      final evt = event.ReceptionChange.delete(rid, modifier.id);
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

  Future<Response> history(Request request) async =>
      okJson((await _rStore.changes()).toList(growable: false));

  Future<Response> objectHistory(Request request, String ridParam) async {
    int rid;
    try {
      rid = int.parse(ridParam);
    } on FormatException {
      return clientError('Bad rid: $ridParam');
    }

    return okJson((await _rStore.changes(rid)).toList(growable: false));
  }

  Future<Response> changelog(Request request, String ridParam) async {
    int rid;
    try {
      rid = int.parse(ridParam);
    } on FormatException {
      return clientError('Bad rid: $ridParam');
    }

    return ok((await _rStore.changeLog(rid)));
  }
}
