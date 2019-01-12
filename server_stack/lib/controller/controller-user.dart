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

import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/gzip_cache.dart' as gzip_cache;
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:ors/model.dart' as model;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart' as shelf_route;

const _json = const JsonCodec();

class User {
  static final Logger log = new Logger('server.controller.user');

  final filestore.User _userStore;
  final service.Authentication _authservice;
  final service.NotificationService _notification;
  final gzip_cache.UserCache _cache;

  User(this._userStore, this._notification, this._authservice, this._cache);

  /**
   * HTTP Request handler for returning a single user resource.
   */
  Future<shelf.Response> get(shelf.Request request) async {
    final int uid = int.parse(shelf_route.getPathParameter(request, 'uid'));

    try {
      return okGzip(new Stream.fromIterable([await _cache.get(uid)]));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /**
   * HTTP Request handler for returning a all user resources.
   */
  Future<shelf.Response> list(shelf.Request request) async {
    try {
      return okGzip(new Stream.fromIterable([await _cache.list()]));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /**
   * HTTP Request handler for removing a single user resource.
   */
  Future<shelf.Response> remove(shelf.Request request) async {
    final int uid = int.parse(shelf_route.getPathParameter(request, 'uid'));
    model.User modifier;

    try {
      modifier = await _authservice.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    try {
      await _userStore.remove(uid, modifier);

      var e = new event.UserChange.delete(uid, modifier.id);
      try {
        await _notification.broadcastEvent(e);
      } catch (error) {
        log.severe('Failed to dispatch event $e', error);
      }

      return okJson({'status': 'ok', 'description': 'User deleted'});
    } on NotFound {
      return notFoundJson({'description': 'No user found with id $uid'});
    }
  }

  /**
   * HTTP Request handler for creating a single user resource.
   */
  Future<shelf.Response> create(shelf.Request request) async {
    model.User user;
    model.User creator;
    try {
      user = await request
          .readAsString()
          .then((String buffer) => _json.decode(buffer))
          .then((Map<String, dynamic> map) => new model.User.fromJson(map));
    } on FormatException catch (error) {
      Map response = {
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

    var e = new event.UserChange.create(uRef.id, creator.id);
    try {
      await _notification.broadcastEvent(e);
    } catch (error) {
      log.severe('Failed to dispatch event $e', error);
    }
    return okJson(uRef);
  }

  /**
   * HTTP Request handler for updating a single user resource.
   */
  Future<shelf.Response> update(shelf.Request request) async {
    model.User user;
    model.User modifier;
    try {
      user = await request
          .readAsString()
          .then(_json.decode)
          .then((Map<String, dynamic> map) => new model.User.fromJson(map));
    } on FormatException catch (error) {
      Map response = {
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
      final uRef = await _userStore.update(user, modifier);

      var e = new event.UserChange.update(uRef.id, modifier.id);

      try {
        await _notification.broadcastEvent(e);
      } catch (error) {
        log.severe('Failed to dispatch event $e', error);
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

  /**
   * Response handler for the user of an identity.
   */
  Future<shelf.Response> userIdentity(shelf.Request request) async {
    String identity = shelf_route.getPathParameter(request, 'identity');
    String domain = shelf_route.getPathParameter(request, 'domain');

    if (domain != null) {
      identity = domain.isEmpty ? identity : '$identity@$domain';
    }

    try {
      return okJson(await _userStore.getByIdentity(identity));
    } on NotFound catch (error) {
      return notFound(error.toString());
    }
  }

  /**
   * List every available group in the store.
   */
  Future<shelf.Response> groups(shelf.Request request) async =>
      okJson((await _userStore.groups()).toList(growable: false));

  /**
   *
   */
  Future<shelf.Response> history(shelf.Request request) async =>
      okJson((await _userStore.changes()).toList(growable: false));

  /**
   *
   */
  Future<shelf.Response> objectHistory(shelf.Request request) async {
    final String uidParam = shelf_route.getPathParameter(request, 'uid');
    int uid;
    try {
      uid = int.parse(uidParam);
    } on FormatException {
      return clientError('Bad uid: $uidParam');
    }

    return okJson((await _userStore.changes(uid)).toList(growable: false));
  }

  /**
   *
   */
  Future<shelf.Response> changelog(shelf.Request request) async {
    final String uidParam = shelf_route.getPathParameter(request, 'uid');
    int uid;
    try {
      uid = int.parse(uidParam);
    } on FormatException {
      return clientError('Bad uid: $uidParam');
    }

    return ok((await _userStore.changeLog(uid)));
  }

  /**
   *
   */
  Future<shelf.Response> cacheStats(shelf.Request request) async {
    return okJson(_cache.stats);
  }

  /**
   *
   */
  Future<shelf.Response> emptyCache(shelf.Request request) async {
    await _cache.emptyAll();

    return cacheStats(request);
  }
}
