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
library ors.controller.message;

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/gzip_cache.dart' as gzip_cache;
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:orf/storage.dart' as storage;
import 'package:orf/exceptions.dart';
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart' as shelf_route;

const _json = const JsonCodec();

class Message {
  final Logger _log = new Logger('controller.message');
  final service.Authentication _authService;
  final service.NotificationService _notification;
  final gzip_cache.MessageCache _cache;

  final filestore.Message _messageStore;
  final storage.MessageQueue _messageQueue;

  Message(this._messageStore, this._messageQueue, this._authService,
      this._notification, this._cache);

  /**
   * HTTP Request handler for returning a single message resource.
   */
  Future<shelf.Response> get(shelf.Request request) async {
    final String midStr = shelf_route.getPathParameter(request, 'mid');
    int mid;

    try {
      mid = int.parse(midStr);
    } on FormatException {
      final msg = 'Bad message id: $midStr';
      _log.warning(msg);

      return clientError(msg);
    }

    try {
      model.Message message = await _messageStore.get(mid);

      return okJson(message);
    } on NotFound {
      return notFound('Not found: $mid');
    } catch (error, stackTrace) {
      final String msg = 'Failed to retrieve message with ID $mid';
      _log.severe(msg, error, stackTrace);

      return serverError(msg);
    }
  }

  /**
   * HTTP Request handler for updating a single message resource.
   */
  Future<shelf.Response> update(shelf.Request request) async {
    model.User modifier;

    /// User object fetching.
    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (error, stackTrace) {
      final String msg = 'Failed to contact authserver';
      _log.severe(msg, error, stackTrace);

      return authServerDown();
    }

    String content;
    model.Message message;
    try {
      content = await request.readAsString();
      message = new model.Message.fromJson(
          _json.decode(content) as Map<String, dynamic>)..sender = modifier;
      if (message.id == model.Message.noId) {
        return clientError('Refusing to update a non-existing message. '
            'set messageID or use the PUT method instead.');
      }
    } catch (error, stackTrace) {
      final msg = 'Failed to parse message in POST body. body:$content';
      _log.severe(msg, error, stackTrace);

      return clientError(msg);
    }

    model.Message createdMessage =
        await _messageStore.update(message, modifier);

    final evt = new event.MessageChange.update(
        createdMessage.id, modifier.id, message.state, message.createdAt);

    try {
      await _notification.broadcastEvent(evt);
    } catch (e) {
      _log.warning('$e: Failed to send $evt');
    }
    return okJson(createdMessage);
  }

  /**
   * HTTP Request handler for removing a single message resource.
   */
  Future<shelf.Response> remove(shelf.Request request) async {
    model.User modifier;

    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    final int mid = int.parse(shelf_route.getPathParameter(request, 'mid'));

    try {
      await _messageStore.remove(mid, modifier);

      final evt = new event.MessageChange.delete(
          mid, modifier.id, model.MessageState.unknown, new DateTime.now());

      try {
        await _notification.broadcastEvent(evt);
      } catch (e) {
        _log.warning('$e: Failed to send $evt');
      }
    } on NotFound {
      return notFound('$mid');
    }

    return okJson(const {});
  }

  /**
   * Builds a list of previously stored messages left on a single day.
   */
  Future<shelf.Response> list(shelf.Request request) async {
    final String dayStr = shelf_route.getPathParameter(request, 'day');
    DateTime day;

    try {
      final List<String> part = dayStr.split('-');

      day = new DateTime(
          int.parse(part[0]), int.parse(part[1]), int.parse(part[2]));
    } catch (e) {
      final String msg = 'Day parsing failed: $dayStr';
      _log.warning(msg, e);
      return clientError(msg);
    }

    try {
      return okGzip(new Stream.fromIterable([await _cache.list(day)]));
    } catch (error, stackTrace) {
      _log.severe(error, stackTrace);
      return serverError(error.toString);
    }
  }

  /**
   * Builds a list of draft messages, filtering by the parameters passed in
   * the queryParameters of the request.
   */
  Future<shelf.Response> listDrafts(shelf.Request request) async {
    try {
      return okGzip(new Stream.fromIterable([await _cache.listDrafts()]));
    } catch (error, stackTrace) {
      _log.severe(error, stackTrace);
      return serverError(error.toString);
    }
  }

  /**
   * Enqueues a messages for dispathing via the transport layer specified in
   * the endpoints belonging to the message recipients.
   */
  Future<shelf.Response> send(shelf.Request request) async {
    model.User user;

    /// User object fetching.
    try {
      user = await _authService.userOf(tokenFrom(request));
    } catch (error, stackTrace) {
      final String msg = 'Failed to contact authserver';
      _log.severe(msg, error, stackTrace);

      return authServerDown();
    }

    String content;
    model.Message message;
    try {
      content = await request.readAsString();
      message = new model.Message.fromJson(
          _json.decode(content) as Map<String, dynamic>)..sender = user;

      if ([model.Message.noId, null].contains(message.id)) {
        return clientError('Invalid message ID');
      }
    } catch (error, stackTrace) {
      final msg = 'Failed to parse message in POST body. body:$content';
      _log.severe(msg, error, stackTrace);

      return clientError(msg);
    }

    final model.MessageQueueEntry queueItem =
        await _messageQueue.enqueue(message);

    final evt = new event.MessageChange.update(
        message.id, user.id, message.state, message.createdAt);

    try {
      await _notification.broadcastEvent(evt);
    } catch (e) {
      _log.warning('$e: Failed to send $evt');
    }
    return okJson(queueItem);
  }

  /**
   * Persistently stores a messages. If the message already exists, a
   * [ClientError] is returned to the client.
   * the client.
   */
  Future<shelf.Response> create(shelf.Request request) async {
    model.User modifier;

    /// User object fetching.
    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (error, stackTrace) {
      final String msg = 'Failed to contact authserver';
      _log.severe(msg, error, stackTrace);

      return authServerDown();
    }

    String content;
    model.Message message;
    try {
      content = await request.readAsString();
      message = new model.Message.fromJson(
          _json.decode(content) as Map<String, dynamic>)
        ..sender = modifier
        ..createdAt = new DateTime.now();

      if (message.id != model.Message.noId) {
        return clientError('Refusing to re-create existing message. '
            'Remove messageID or use the POST method instead.');
      }
    } catch (error, stackTrace) {
      final msg = 'Failed to parse message in PUT body. body:$content';
      _log.severe(msg, error, stackTrace);

      return clientError(msg);
    }

    final model.Message createdMessage =
        await _messageStore.create(message, modifier);

    final evt = new event.MessageChange.create(createdMessage.id,
        createdMessage.id, createdMessage.state, createdMessage.createdAt);

    try {
      await _notification.broadcastEvent(evt);
    } catch (e) {
      _log.warning('$e: Failed to send $evt');
    }

    return okJson(createdMessage);
  }

  /**
   * Retrieves the history of the message store.
   */
  Future<shelf.Response> history(shelf.Request request) async =>
      okJson((await _messageStore.changes()).toList(growable: false));

  /**
   * Retrieves the history of a single message object.
   */
  Future<shelf.Response> objectHistory(shelf.Request request) async {
    final String midParam = shelf_route.getPathParameter(request, 'mid');
    int mid;
    try {
      mid = int.parse(midParam);
    } on FormatException {
      return clientError('Bad mid: $midParam');
    }

    return okJson((await _messageStore.changes(mid)).toList(growable: false));
  }

  /**
   *
   */
  Future<shelf.Response> queryById(shelf.Request request) async {
    final String body = await request.readAsString();

    List<int> ids;
    try {
      ids = _json.decode(body) as List<int>;
    } on FormatException {
      return clientError('Bad list: $body');
    }

    return okJson((await _messageStore.getByIds(ids)).toList(growable: false));
  }
}
