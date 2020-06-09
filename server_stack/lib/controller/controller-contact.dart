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

library ors.controller.contact;

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

class Contact {
  Contact(this._contactStore, this._notification, this._authService);

  final service.Authentication _authService;
  final filestore.Contact _contactStore;
  final service.NotificationService _notification;
  final Logger _log = Logger('ors.controller.reception');

  /// Retrieves a single base contact based on contactID.
  Future<Response> base(Request request, String cidParam) async {
    final int cid = int.parse(cidParam);

    try {
      return okJson(await _contactStore.get(cid));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /// Creates a base contact.
  Future<Response> create(Request request) async {
    model.BaseContact contact;
    model.User modifier;

    try {
      contact =
          model.BaseContact.fromJson(json.decode(await request.readAsString()));
    } on FormatException {
      return clientError('Failed to parse contact object');
    }

    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    final cRef = await _contactStore.create(contact, modifier);

    final createEvent = event.ContactChange.create(cRef.id, modifier.id);

    try {
      await _notification.broadcastEvent(createEvent);
    } catch (e) {
      _log.shout('Failed to send event $createEvent');
    }

    return okJson(cRef);
  }

  /// Retrieves a single base contact based on contact ID.
  Future<Response> listBase(Request request) async {
    try {
      return okJson((await _contactStore.list()).toList(growable: false));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /// Retrieves a list of base contacts associated with the provided
  /// organization ID.
  Future<Response> listByOrganization(Request request, String oidParam) async {
    final int oid = int.parse(oidParam);

    return okJson((await _contactStore.organizationContacts(oid))
        .toList(growable: false));
  }

  /// Retrieves a single contact based on receptionID and contactID.
  Future<Response> get(
      Request request, String cidParam, String ridParam) async {
    final int cid = int.parse(cidParam);
    final int rid = int.parse(ridParam);

    try {
      final attr = await _contactStore.data(cid, rid);
      return okJson((attr));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /// Returns the id's of all organizations that a contact is associated to.
  Future<Response> organizations(Request request, String cidParam) async {
    final int cid = int.parse(cidParam);

    return okJson(
        ((await _contactStore.organizations(cid)).toList(growable: false)));
  }

  /// Returns the id's of all receptions that a contact is associated to.
  Future<Response> receptions(Request request, String cidParam) async {
    final int cid = int.parse(cidParam);

    return okJson(
        (await _contactStore.receptions(cid)).toList(growable: false));
  }

  /// Removes a single contact from the data store.
  Future<Response> remove(Request request, String cidParam) async {
    final int cid = int.parse(cidParam);
    model.User modifier;

    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    try {
      await _contactStore.remove(cid, modifier);
      event.ContactChange changeEvent =
          event.ContactChange.delete(cid, modifier.id);

      try {
        await _notification.broadcastEvent(changeEvent);
      } catch (e) {
        _log.shout('Failed to send event $changeEvent');
      }

      return okJson(const {});
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /// Update the base information of a contact
  Future<Response> update(Request request, String cidParam) async {
    final int cid = int.parse(cidParam);

    model.User modifier;
    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    model.BaseContact contact;

    try {
      contact =
          model.BaseContact.fromJson(json.decode(await request.readAsString()));
    } catch (error) {
      final Map response = {
        'status': 'bad request',
        'description': 'passed contact argument '
            'is too long, missing or invalid',
        'error': error.toString()
      };

      return clientErrorJson(response);
    }

    try {
      final cRef = await _contactStore.update(contact, modifier);
      event.ContactChange changeEvent =
          event.ContactChange.update(cid, modifier.id);

      try {
        await _notification.broadcastEvent(changeEvent);
      } catch (e) {
        _log.shout('Failed to send event $changeEvent');
      }

      return okJson(cRef);
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /// Gives a lists of every contact in an reception.
  Future<Response> listByReception(Request request, final String rid) async {
    try {
      return okJson((await _contactStore.receptionContacts(int.parse(rid))).toList(growable: false));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /**
   *
   */
  Future<Response> addToReception(
      Request request, String cidParam, String ridParam) async {
    //final int rid = int.parse(cidParam);

    model.ReceptionAttributes attr;
    model.User modifier;

    try {
      Map<String, dynamic> data = json.decode(await request.readAsString());
      attr = model.ReceptionAttributes.fromJson(data);
    } catch (error) {
      final Map response = {
        'status': 'bad request',
        'description': 'passed contact argument '
            'is too long, missing or invalid',
        'error': error.toString()
      };
      return clientErrorJson(response);
    }

    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    final ref = await _contactStore.addData(attr, modifier);

    event.ReceptionData changeEvent =
        event.ReceptionData.create(attr.cid, attr.receptionId, modifier.id);

    try {
      await _notification.broadcastEvent(changeEvent);
    } catch (e) {
      _log.shout('Failed to send event $changeEvent');
    }

    return okJson(ref);
  }

  /**
   *
   */
  Future<Response> updateInReception(
      Request request, String cidParam, String ridParam) async {
    //final int rid = int.parse(shelf_route.getPathParameter(request, 'rid'));

    model.User modifier;
    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    model.ReceptionAttributes attr;
    try {
      attr = model.ReceptionAttributes.fromJson(
          json.decode(await request.readAsString()));
    } catch (error) {
      Map response = {
        'status': 'bad request',
        'description': 'passed contact argument '
            'is too long, missing or invalid',
        'error': error.toString()
      };

      return clientErrorJson(response);
    }

    try {
      final ref = await _contactStore.updateData(attr, modifier);
      event.ReceptionData changeEvent =
          event.ReceptionData.update(attr.cid, attr.receptionId, modifier.id);

      try {
        await _notification.broadcastEvent(changeEvent);
      } catch (e) {
        _log.shout('Failed to send event $changeEvent');
      }

      return okJson(ref);
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /**
   *
   */
  Future<Response> removeFromReception(
      Request request, String cidParam, String ridParam) async {
    final int cid = int.parse(cidParam);
    final int rid = int.parse(ridParam);

    model.User modifier;
    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    try {
      await _contactStore.removeData(cid, rid, modifier);

      event.ReceptionData changeEvent =
          event.ReceptionData.update(cid, rid, modifier.id);

      try {
        await _notification.broadcastEvent(changeEvent);
      } catch (e) {
        _log.shout('Failed to send event $changeEvent');
      }

      return okJson(const {});
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /**
   *
   */
  Future<Response> history(Request request) async =>
      okJson((await _contactStore.changes()).toList(growable: false));

  /**
   *
   */
  Future<Response> objectHistory(Request request, String cidParam) async {
    int cid;
    try {
      cid = int.parse(cidParam);
    } on FormatException {
      return clientError('Bad cid: $cidParam');
    }

    return okJson((await _contactStore.changes(cid)).toList(growable: false));
  }

  /**
   *
   */
  Future<Response> receptionHistory(
      Request request, String cidParam, String ridParam) async {
    int cid;
    int rid;
    try {
      cid = int.parse(cidParam);
    } on FormatException {
      return clientError('Bad cid: $cidParam');
    }
    try {
      rid = int.parse(ridParam);
    } on FormatException {
      return clientError('Bad rid: $cidParam');
    }

    return okJson(
        (await _contactStore.changes(cid, rid)).toList(growable: false));
  }

  /**
   *
   */
  Future<Response> receptionChangelog(Request request, String cidParam) async {
    int cid;
    try {
      cid = int.parse(cidParam);
    } on FormatException {
      return clientError('Bad cid: $cidParam');
    }

    return ok(await _contactStore.receptionChangeLog(cid));
  }

  /**
   *
   */
  Future<Response> changelog(Request request, String cidParam) async {
    int cid;
    try {
      cid = int.parse(cidParam);
    } on FormatException {
      return clientError('Bad cid: $cidParam');
    }

    return ok(await _contactStore.changeLog(cid));
  }
}
