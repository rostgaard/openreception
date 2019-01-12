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

library ors.controller.calendar;

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/gzip_cache.dart' as gzip_cache;
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart' as shelf_route;

const _json = const JsonCodec();

/**
 * Ivr menu controller class.
 */
class Calendar {
  final service.Authentication _authService;
  final gzip_cache.CalendarCache _cache;
  final filestore.Contact _contactStore;
  final Logger _log = new Logger('ors.controller.calendar');
  final service.NotificationService _notification;
  final filestore.Reception _receptionStore;

  /**
   *
   */
  Calendar(this._contactStore, this._receptionStore, this._authService,
      this._notification, this._cache);

  /**
   * Rebuilds the entire cache.
   */
  Future<shelf.Response> cachePrefill(shelf.Request request) async {
    List<model.Owner> owners = [];

    (await _contactStore.list()).forEach((model.BaseContact bc) {
      owners.add(new model.OwningContact(bc.id));
    });

    (await _receptionStore.list()).forEach((model.ReceptionReference rRef) {
      owners.add(new model.OwningReception(rRef.id));
    });

    await _cache.prefill(owners);

    return cacheStats(request);
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
  Future<shelf.Response> changes(shelf.Request request) async {
    final int eid = shelf_route.getPathParameter(request, 'eid') != null
        ? int.parse(shelf_route.getPathParameter(request, 'eid'))
        : null;

    final String type = shelf_route.getPathParameter(request, 'type');
    final String oid = shelf_route.getPathParameter(request, 'oid');
    model.Owner owner;
    try {
      owner = new model.Owner.parse('$type:$oid');
    } catch (e) {
      final String msg = 'Could parse owner: $type:$oid';
      _log.warning(msg, e);
      return clientError(e.toString(msg));
    }

    try {
      if (owner is model.OwningContact) {
        return okJson((await _contactStore.calendarStore.changes(owner, eid))
            .toList(growable: false));
      } else if (owner is model.OwningReception) {
        return okJson((await _receptionStore.calendarStore.changes(owner, eid))
            .toList(growable: false));
      } else {
        return clientError('Could not find suitable for store '
            'for owner type: ${owner.runtimeType}');
      }
    } on NotFound {
      return notFound('No event with id $eid');
    }
  }

  /**
   *
   */
  Future<shelf.Response> create(shelf.Request request) async {
    model.User modifier;
    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e, s) {
      _log.warning('Could not connect to auth server', e, s);
      return authServerDown();
    }

    model.Owner owner;
    final String type = shelf_route.getPathParameter(request, 'type');
    final String oid = shelf_route.getPathParameter(request, 'oid');
    try {
      owner = new model.Owner.parse('$type:$oid');
    } catch (e) {
      final String msg = 'Could parse owner: $type:$oid';
      _log.warning(msg, e);
      return clientError(e.toString(msg));
    }

    final model.CalendarEntry entry = new model.CalendarEntry.fromJson(
        _json.decode(await request.readAsString()) as Map<String, dynamic>);

    model.CalendarEntry created;

    try {
      if (owner is model.OwningContact) {
        created =
            await _contactStore.calendarStore.create(entry, owner, modifier);
      } else if (owner is model.OwningReception) {
        created =
            await _receptionStore.calendarStore.create(entry, owner, modifier);
      } else {
        return clientError('Could not find suitable for store '
            'for owner type: ${owner.runtimeType}');
      }
    } on ClientError {
      return clientError('Could not create new object.');
    }

    event.CalendarChange changeEvent =
        new event.CalendarChange.create(created.id, owner, modifier.id);
    _log.finest('User id:${modifier.id} created entry for $owner');

    try {
      await _notification.broadcastEvent(changeEvent);
    } catch (e) {
      _log.warning('$e: Failed to send $changeEvent');
    }

    return okJson(created);
  }

  /**
   *
   */
  Future<shelf.Response> emptyCache(shelf.Request request) async {
    _cache.emptyAll();

    return cacheStats(request);
  }

  /**
   *
   */
  Future<shelf.Response> get(shelf.Request request) async {
    final int eid = int.parse(shelf_route.getPathParameter(request, 'eid'));

    model.Owner owner;
    final String type = shelf_route.getPathParameter(request, 'type');
    final String oid = shelf_route.getPathParameter(request, 'oid');
    try {
      owner = new model.Owner.parse('$type:$oid');
    } catch (e) {
      final String msg = 'Could parse owner: $type:$oid';
      _log.warning(msg, e);
      return clientError(e.toString(msg));
    }

    try {
      return okGzip(new Stream.fromIterable([await _cache.get(eid, owner)]));
    } on ClientError catch (e) {
      return clientError(e.toString());
    } on NotFound {
      return notFound('No event with id $eid');
    }
  }

  /**
   *
   */
  Future<shelf.Response> getDeleted(shelf.Request request) async {
    final int eid = int.parse(shelf_route.getPathParameter(request, 'eid'));

    try {
      //return okJson(await _calendarStore.get(eid));
      return serverError('Not supported');
    } on NotFound {
      return notFound('No event with id $eid');
    }
  }

  /**
   *
   */
  Future<shelf.Response> list(shelf.Request request) async {
    model.Owner owner;
    final String type = shelf_route.getPathParameter(request, 'type');
    final String oid = shelf_route.getPathParameter(request, 'oid');
    try {
      owner = new model.Owner.parse('$type:$oid');
    } catch (e) {
      final String msg = 'Could parse owner: $type:$oid';
      _log.warning(msg, e);
      return clientError(e.toString(msg));
    }

    try {
      return okGzip(new Stream.fromIterable([await _cache.list(owner)]));
    } on ClientError catch (e) {
      return clientError(e.toString());
    } on NotFound {
      return notFound('Non-existing owner $owner');
    }
  }

  /**
   *
   */
  Future<shelf.Response> remove(shelf.Request request) async {
    model.User modifier;
    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e) {
      _log.warning('Could not connect to auth server');
      return authServerDown();
    }

    final int eid = int.parse(shelf_route.getPathParameter(request, 'eid'));
    final String type = shelf_route.getPathParameter(request, 'type');
    final String oid = shelf_route.getPathParameter(request, 'oid');
    model.Owner owner;
    try {
      owner = new model.Owner.parse('$type:$oid');
    } catch (e) {
      final String msg = 'Could parse owner: $type:$oid';
      _log.warning(msg, e);
      return clientError(e.toString(msg));
    }

    try {
      if (owner is model.OwningContact) {
        await _contactStore.calendarStore.remove(eid, owner, modifier);
      } else if (owner is model.OwningReception) {
        await _receptionStore.calendarStore.remove(eid, owner, modifier);
      } else {
        return clientError('Could not find suitable for store '
            'for owner type: ${owner.runtimeType}');
      }
    } on NotFound {
      return notFound('Non-existing owner $owner');
    }

    final event.CalendarChange changeEvent =
        new event.CalendarChange.delete(eid, owner, modifier.id);

    _log.finest('User id:${modifier.id} removed entry for $owner');

    try {
      await _notification.broadcastEvent(changeEvent);
    } catch (e) {
      _log.warning('$e: Failed to send $changeEvent');
    }

    return okJson('{}');
  }

  /**
   *
   */
  Future<shelf.Response> update(shelf.Request request) async {
    model.User modifier;

    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e, s) {
      _log.warning('Could not connect to auth server', e, s);
      return authServerDown();
    }

    final String type = shelf_route.getPathParameter(request, 'type');
    final String oid = shelf_route.getPathParameter(request, 'oid');
    model.Owner owner;
    try {
      owner = new model.Owner.parse('$type:$oid');
    } catch (e) {
      final String msg = 'Could parse owner: $type:$oid';
      _log.warning(msg, e);
      return clientError(e.toString(msg));
    }

    final model.CalendarEntry entry = new model.CalendarEntry.fromJson(
        _json.decode(await request.readAsString()) as Map<String, dynamic>);

    model.CalendarEntry updated;

    try {
      if (owner is model.OwningContact) {
        updated =
            await _contactStore.calendarStore.update(entry, owner, modifier);
      } else if (owner is model.OwningReception) {
        updated =
            await _receptionStore.calendarStore.update(entry, owner, modifier);
      } else {
        return clientError('Could not find suitable for store '
            'for owner type: ${owner.runtimeType}');
      }
    } on NotFound {
      return notFound('Non-existing owner $owner');
    }

    final event.CalendarChange changeEvent =
        new event.CalendarChange.update(updated.id, owner, modifier.id);

    _log.finest('User id:${modifier.id} updated entry for $owner');

    try {
      await _notification.broadcastEvent(changeEvent);
    } catch (e) {
      _log.warning('$e: Failed to send $changeEvent');
    }

    return okJson(updated);
  }

  /**
   *
   */
  Future<shelf.Response> changelog(shelf.Request request) async {
    final String type = shelf_route.getPathParameter(request, 'type');
    final String oid = shelf_route.getPathParameter(request, 'oid');
    model.Owner owner;
    try {
      owner = new model.Owner.parse('$type:$oid');
    } catch (e) {
      final String msg = 'Could parse owner: $type:$oid';
      _log.warning(msg, e);
      return clientError(e.toString(msg));
    }

    try {
      if (owner is model.OwningContact) {
        return ok(await _contactStore.calendarStore.changeLog(owner.id));
      } else if (owner is model.OwningReception) {
        return ok(await _receptionStore.calendarStore.changeLog(owner.id));
      } else {
        return clientError('Could not find suitable for store '
            'for owner type: ${owner.runtimeType}');
      }
    } on NotFound {
      return notFound('No event with owner $owner');
    }
  }
}
