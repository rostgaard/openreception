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

import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;

import '../response_utils.dart';

/// Ivr menu controller class.
class Calendar {
  Calendar(this._contactStore, this._receptionStore, this._authService,
      this._notification);

  final service.Authentication _authService;
  final filestore.Contact _contactStore;
  final Logger _log = Logger('ors.controller.calendar');
  final service.NotificationService _notification;
  final filestore.Reception _receptionStore;

  /**
   *
   */
  Future<Response> changes(Request request, String type, String oid,
      [String eventId]) async {
    final int eid = eventId != null ? int.parse(eventId) : null;

    model.Owner owner;
    try {
      owner = model.Owner.parse('$type:$oid');
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
  Future<Response> create(Request request, String type, String oid) async {
    model.User modifier;
    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e, s) {
      _log.warning('Could not connect to auth server', e, s);
      return authServerDown();
    }

    model.Owner owner;
    try {
      owner = model.Owner.parse('$type:$oid');
    } catch (e) {
      final String msg = 'Could parse owner: $type:$oid';
      _log.warning(msg, e);
      return clientError(e.toString(msg));
    }

    final model.CalendarEntry entry =
        model.CalendarEntry.fromJson(json.decode(await request.readAsString()));

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
      return clientError('Could not create object.');
    }

    event.CalendarChange changeEvent =
        event.CalendarChange.create(created.id, owner, modifier.id);
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
  Future<Response> get(
      Request request, String type, String oid, String eventId) async {
    final int eid = int.parse(eventId);

    model.Owner owner;
    try {
      owner = model.Owner.parse('$type:$oid');
    } catch (e) {
      final String msg = 'Could parse owner: $type:$oid';
      _log.warning(msg, e);
      return clientError(e.toString(msg));
    }

    try {
      if (owner is model.OwningContact) {
        return okJson(await _contactStore.calendarStore.get(eid, owner));
        ;
      } else if (owner is model.OwningReception) {
        return okJson(await _receptionStore.calendarStore.get(eid, owner));
      } else {
        throw new ClientError('Could not find suitable for store '
            'for owner type: ${owner.runtimeType}');
      }
    } on ClientError catch (e) {
      return clientError(e.toString());
    } on NotFound {
      return notFound('No event with id $eid');
    }
  }

  /**
   *
   */
  Future<Response> getDeleted(
      Request request, String type, String oid, String eventId) async {
    final int eid = int.parse(eventId);

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
  Future<Response> list(Request request, String type, String oid) async {
    model.Owner owner;

    try {
      owner = model.Owner.parse('$type:$oid');
    } catch (e) {
      final String msg = 'Could parse owner: $type:$oid';
      _log.warning(msg, e);
      return clientError(e.toString(msg));
    }

    try {
      if (owner is model.OwningContact) {
        return okJson(await _contactStore.calendarStore.list(owner));
        ;
      } else if (owner is model.OwningReception) {
        return okJson(await _receptionStore.calendarStore.list(owner));
      } else {
        throw new ClientError('Could not find suitable for store '
            'for owner type: ${owner.runtimeType}');
      }
    } on ClientError catch (e) {
      return clientError(e.toString());
    } on NotFound {
      return notFound('Non-existing owner $owner');
    }
  }

  /**
   *
   */
  Future<Response> remove(
      Request request, String type, String oid, String eventId) async {
    model.User modifier;
    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e) {
      _log.warning('Could not connect to auth server');
      return authServerDown();
    }

    final int eid = int.parse(eventId);

    model.Owner owner;
    try {
      owner = model.Owner.parse('$type:$oid');
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
        event.CalendarChange.delete(eid, owner, modifier.id);

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
  Future<Response> update(
      Request request, String type, String oid, String eventId) async {
    model.User modifier;

    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e, s) {
      _log.warning('Could not connect to auth server', e, s);
      return authServerDown();
    }

    model.Owner owner;
    try {
      owner = model.Owner.parse('$type:$oid');
    } catch (e) {
      final String msg = 'Could parse owner: $type:$oid';
      _log.warning(msg, e);
      return clientError(e.toString(msg));
    }

    final model.CalendarEntry entry =
        model.CalendarEntry.fromJson(json.decode(await request.readAsString()));

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
        event.CalendarChange.update(updated.id, owner, modifier.id);

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
  Future<Response> changelog(Request request, String type, String oid) async {
    model.Owner owner;
    try {
      owner = model.Owner.parse('$type:$oid');
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
