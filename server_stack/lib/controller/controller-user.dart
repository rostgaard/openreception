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

library ors.controller.user;

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:ors/model.dart' as model;
import 'package:ors/response_utils.dart';

class User {
  User(this._userStore, this._notification, this._authservice);

  final Logger _log = Logger('server.controller.user');

  final filestore.User _userStore;
  final service.Authentication _authservice;
  final service.NotificationService _notification;

  /// HTTP Request handler for returning a single user resource.
  Future<Response> get(Request request, String uidParam) async {
    final int uid = int.parse(uidParam);

    try {
      return okJson(await _userStore.get(uid));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /// HTTP Request handler for returning a all user resources.
  Future<Response> list(Request request) async {
    try {
      return okJson((await _userStore.list())
          .map((model.UserReference ref) => ref.toJson())
          .toList(growable: false));
    } on NotFound catch (e) {
      return notFound( e.toString());
    }
  }

  /// HTTP Request handler for removing a single user resource.
  Future<Response> remove(Request request, String uidParam) async {
    final int uid = int.parse(uidParam);
    model.User modifier;

    try {
      modifier = await _authservice.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    try {
      await _userStore.remove(uid, modifier);
      final e = event.UserChange.delete(uid, modifier.id);
      try {
        await _notification.broadcastEvent(e);
      } catch (error) {
        _log.severe('Failed to dispatch event $e', error);
      }

      return okJson({'status': 'ok', 'description': 'User deleted'});
    } on NotFound {
      return notFoundJson(
          {'description': 'No user found with id $uid'});
    }
  }

  /// HTTP Request handler for creating a single user resource.
  Future<Response> create(Request request) async {
    model.User user;
    model.User creator;
    try {
      final map = json.decode(await request.readAsString());
      user = model.User.fromJson(map);
    } on FormatException catch (error) {
      Map response = <String, String>{
        'status': 'bad request',
        'description': 'passed user argument '
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

    final uRef = await _userStore.create(user, creator);
    final e = event.UserChange.create(uRef.id, creator.id);
    try {
      await _notification.broadcastEvent(e);
    } catch (error) {
      _log.severe('Failed to dispatch event $e', error);
    }
    return okJson(await _userStore.get(uRef.id));
  }

  /// HTTP Request handler for updating a single user resource.
  Future<Response> update(Request request, String uidParam) async {
    final int uid = int.parse(uidParam);
    model.User user;
    model.User modifier;
    try {
      final map = json.decode(await request.readAsString());
      user = model.User.fromJson(map);

      user.id = uid;
    } on FormatException catch (error) {
      Map response = <String, String>{
        'status': 'bad request',
        'description': 'passed user argument '
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
      user.groups = user.groups.toSet().toList();
      user.identities = user.identities.toSet().toList();
      final uRef = await _userStore.update(user, modifier);
      final e = event.UserChange.update(uRef.id, modifier.id);

      try {
        await _notification.broadcastEvent(e);
      } catch (error) {
        _log.severe('Failed to dispatch event $e', error);
      }

      return okJson(uRef);
    } on Unchanged {
      return clientError('Unchanged');
    } on NotFound catch (e) {
      return notFound(e.toString());
    } on ClientError catch (e) {
      return clientError(e.toString());
    }
  }

  /// Response handler for the user of an identity.
  Future<Response> userIdentity(Request request, String identity) async {

    try {
      return okJson(await _userStore.getByIdentity(identity));
    } on NotFound catch (error) {
      return notFound(error.toString());
    }
  }

  /// List every available group in the store.
  Future<Response> groups(Request request) async =>
      okJson((await _userStore.groups()).toList(growable: false));

  Future<Response> history(Request request) async =>
      okJson((await _userStore.changes()).toList(growable: false));

  Future<Response> objectHistory(Request request, String uidParam) async {
    int uid;
    try {
      uid = int.parse(uidParam);
    } on FormatException {
      return clientError('Bad uid: $uidParam');
    }

    return okJson((await _userStore.changes(uid)).toList(growable: false));
  }

  Future<Response> changelog(Request request, String uidParam) async {
    int uid;
    try {
      uid = int.parse(uidParam);
    } on FormatException {
      return clientError('Bad uid: $uidParam');
    }

    return okJson((await _userStore.changeLog(uid)));
  }
}
