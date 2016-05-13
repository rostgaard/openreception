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
library openreception.server.controller.message;

import 'dart:async';
import 'dart:convert';

import 'package:openreception.server/response_utils.dart';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart' as shelf_route;
import 'package:logging/logging.dart';
import 'package:openreception.framework/event.dart' as event;
import 'package:openreception.framework/service.dart' as service;
import 'package:openreception.framework/storage.dart' as storage;
import 'package:openreception.framework/model.dart' as model;

/**
 * Response templates.
 */

class Message {
  final Logger log = new Logger('controller.message');
  final service.Authentication _authService;
  final service.NotificationService _notification;

  final storage.Message _messageStore;
  final storage.MessageQueue _messageQueue;

  Message(this._messageStore, this._messageQueue, this._authService,
      this._notification);

  String _filterFrom(shelf.Request request) =>
      request.requestedUri.queryParameters['filter'];

  /**
   * HTTP Request handler for returning a single message resource.
   */
  Future<shelf.Response> get(shelf.Request request) async {
    final String midStr = shelf_route.getPathParameter(request, 'mid');
    int mid;

    try {
      mid = int.parse(midStr);
    } on FormatException {
      final msg = 'Bad message id :$midStr';
      log.warning(msg);

      clientError(msg);
    }

    try {
      model.Message message = await _messageStore.get(mid);

      return okJson(message);
    } on storage.NotFound {
      return notFound('Not found: $mid');
    } catch (error, stackTrace) {
      final String msg = 'Failed to retrieve message with ID $mid';
      log.severe(msg, error, stackTrace);

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
      log.severe(msg, error, stackTrace);

      return authServerDown();
    }

    String content;
    model.Message message;
    try {
      content = await request.readAsString();
      message = new model.Message.fromMap(JSON.decode(content))
        ..sender = modifier;
      if (message.id == model.Message.noId) {
        return clientError('Refusing to update a non-existing message. '
            'set messageID or use the PUT method instead.');
      }
    } catch (error, stackTrace) {
      final msg = 'Failed to parse message in POST body. body:$content';
      log.severe(msg, error, stackTrace);

      return clientError(msg);
    }

    model.Message createdMessage =
        await _messageStore.update(message, modifier);

    _notification.broadcastEvent(
        new event.MessageChange.update(createdMessage.id, modifier.id));

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

      var e = new event.MessageChange.delete(mid, modifier.id);
      try {
        await _notification.broadcastEvent(e);
      } catch (error) {
        log.severe('Failed to dispatch event $e', error);
      }
    } on storage.NotFound {
      return notFound('$mid');
    }

    return okJson(const {});
  }

  /**
   * Builds a list of previously stored messages, filtering by the
   * parameters passed in the [queryParameters] of the request.
   */
  Future<shelf.Response> list(shelf.Request request) async {
    model.MessageFilter filter = new model.MessageFilter.empty();

    if (_filterFrom(request) != null) {
      try {
        Map map = JSON.decode(_filterFrom(request));
        filter = new model.MessageFilter.fromMap(map);
      } catch (error, stackTrace) {
        log.warning('Bad filter', error, stackTrace);

        return clientError('Bad filter');
      }
    }

    return await _messageStore
        .list(filter: filter)
        .then((Iterable<model.Message> messages) =>
            okJson(messages.toList(growable: false)))
        .catchError((error, stackTrace) {
      log.severe(error, stackTrace);
      return serverError(error.toString);
    });
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
      log.severe(msg, error, stackTrace);

      return authServerDown();
    }

    String content;
    model.Message message;
    try {
      content = await request.readAsString();
      message = new model.Message.fromMap(JSON.decode(content))..sender = user;

      if ([model.Message.noId, null].contains(message.id)) {
        return clientError('Invalid message ID');
      }
    } catch (error, stackTrace) {
      final msg = 'Failed to parse message in POST body. body:$content';
      log.severe(msg, error, stackTrace);

      return clientError(msg);
    }

    return await _messageQueue
        .enqueue(message)
        .then((model.MessageQueueEntry queueItem) {
      _notification
          .broadcastEvent(new event.MessageChange.update(message.id, user.id));

      return okJson(queueItem);
    });
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
      log.severe(msg, error, stackTrace);

      return authServerDown();
    }

    String content;
    model.Message message;
    try {
      content = await request.readAsString();
      message = new model.Message.fromMap(JSON.decode(content))
        ..sender = modifier
        ..createdAt = new DateTime.now();

      if (message.id != model.Message.noId) {
        return clientError('Refusing to re-create existing message. '
            'Remove messageID or use the POST method instead.');
      }
    } catch (error, stackTrace) {
      final msg = 'Failed to parse message in PUT body. body:$content';
      log.severe(msg, error, stackTrace);

      return clientError(msg);
    }

    return await _messageStore
        .create(message, modifier)
        .then((model.Message createdMessage) {
      _notification.broadcastEvent(
          new event.MessageChange.create(message.id, modifier.id));

      return okJson(createdMessage);
    });
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
}