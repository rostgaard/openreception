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

import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/gzip_cache.dart' as gzip_cache;
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:logging/logging.dart';
import 'package:shelf_route/shelf_route.dart' as shelf_route;

const _json = const JsonCodec();

class Contact {
  final service.Authentication _authservice;
  final filestore.Contact _contactStore;
  final service.NotificationService _notification;
  final gzip_cache.ContactCache _cache;
  final Logger _log = new Logger('ors.controller.reception');

  Contact(
      this._contactStore, this._notification, this._authservice, this._cache);

  /**
   * Retrives a single base contact based on contactID.
   */
  Future<shelf.Response> base(shelf.Request request) async {
    final int cid = int.parse(shelf_route.getPathParameter(request, 'cid'));

    try {
      return okGzip(new Stream.fromIterable([await _cache.get(cid)]));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /**
   * Creates a new base contact.
   */
  Future<shelf.Response> create(shelf.Request request) async {
    model.BaseContact contact;
    model.User modifier;

    try {
      contact = await request.readAsString().then(_json.decode).then(
          (Map<String, dynamic> map) => new model.BaseContact.fromJson(map));
    } on FormatException {
      return clientError('Failed to parse contact object');
    }

    try {
      modifier = await _authservice.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    final cRef = await _contactStore.create(contact, modifier);

    final createEvent = new event.ContactChange.create(cRef.id, modifier.id);

    try {
      await _notification.broadcastEvent(createEvent);
    } catch (e) {
      _log.shout('Failed to send event $createEvent');
    }

    return okJson(cRef);
  }

  /**
   * Retrives a single base contact based on contact ID.
   */
  Future<shelf.Response> listBase(shelf.Request request) async {
    try {
      return okGzip(new Stream.fromIterable([await _cache.allContacts()]));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /**
   * Retrives a list of base contacts associated with the provided
   * organization ID.
   */
  Future<shelf.Response> listByOrganization(shelf.Request request) async {
    final int oid = int.parse(shelf_route.getPathParameter(request, 'oid'));

    return okJson((await _contactStore.organizationContacts(oid))
        .toList(growable: false));
  }

  /**
   * Retrives a single contact based on receptionID and contactID.
   */
  Future<shelf.Response> get(shelf.Request request) async {
    final int cid = int.parse(shelf_route.getPathParameter(request, 'cid'));
    final int rid = int.parse(shelf_route.getPathParameter(request, 'rid'));

    try {
      final attr = await _contactStore.data(cid, rid);
      return okJson((attr));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /**
   * Returns the id's of all organizations that a contact is associated to.
   */
  Future<shelf.Response> organizations(shelf.Request request) async {
    final int cid = int.parse(shelf_route.getPathParameter(request, 'cid'));

    return okJson(
        ((await _contactStore.organizations(cid)).toList(growable: false)));
  }

  /**
   * Returns the id's of all receptions that a contact is associated to.
   */
  Future<shelf.Response> receptions(shelf.Request request) async {
    final int cid = int.parse(shelf_route.getPathParameter(request, 'cid'));

    return okJson(
        (await _contactStore.receptions(cid)).toList(growable: false));
  }

  /**
   * Removes a single contact from the data store.
   */
  Future<shelf.Response> remove(shelf.Request request) async {
    final int cid = int.parse(shelf_route.getPathParameter(request, 'cid'));
    model.User modifier;

    try {
      modifier = await _authservice.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    try {
      await _contactStore.remove(cid, modifier);
      event.ContactChange changeEvent =
          new event.ContactChange.delete(cid, modifier.id);

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
   * Update the base information of a contact
   */
  Future<shelf.Response> update(shelf.Request request) async {
    final int cid = int.parse(shelf_route.getPathParameter(request, 'cid'));

    model.User modifier;
    try {
      modifier = await _authservice.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    model.BaseContact contact;

    try {
      contact = await request.readAsString().then(_json.decode).then(
          (Map<String, dynamic> map) => new model.BaseContact.fromJson(map));
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
          new event.ContactChange.update(cid, modifier.id);

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

  /**
   * Gives a lists of every contact in an reception.
   */
  Future<shelf.Response> listByReception(shelf.Request request) async {
    final int rid = int.parse(shelf_route.getPathParameter(request, 'rid'));

    try {
      return okGzip(
          new Stream.fromIterable([await _cache.receptionContacts(rid)]));
    } on NotFound catch (e) {
      return notFound(e.toString());
    }
  }

  /**
   *
   */
  Future<shelf.Response> addToReception(shelf.Request request) async {
    //final int rid = int.parse(shelf_route.getPathParameter(request, 'rid'));

    model.ReceptionAttributes attr;
    model.User modifier;

    try {
      Map data = _json.decode(await request.readAsString());
      attr =
          new model.ReceptionAttributes.fromJson(data as Map<String, dynamic>);
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
      modifier = await _authservice.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    final ref = await _contactStore.addData(attr, modifier);

    event.ReceptionData changeEvent =
        new event.ReceptionData.create(attr.cid, attr.receptionId, modifier.id);

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
  Future<shelf.Response> updateInReception(shelf.Request request) async {
    //final int rid = int.parse(shelf_route.getPathParameter(request, 'rid'));

    model.User modifier;
    try {
      modifier = await _authservice.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    model.ReceptionAttributes attr;
    try {
      attr = await request.readAsString().then(_json.decode).then(
          (Map<String, dynamic> map) =>
              new model.ReceptionAttributes.fromJson(map));
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
      event.ReceptionData changeEvent = new event.ReceptionData.update(
          attr.cid, attr.receptionId, modifier.id);

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
  Future<shelf.Response> removeFromReception(shelf.Request request) async {
    final int cid = int.parse(shelf_route.getPathParameter(request, 'cid'));
    final int rid = int.parse(shelf_route.getPathParameter(request, 'rid'));

    model.User modifier;
    try {
      modifier = await _authservice.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    try {
      await _contactStore.removeData(cid, rid, modifier);

      event.ReceptionData changeEvent =
          new event.ReceptionData.update(cid, rid, modifier.id);

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
  Future<shelf.Response> history(shelf.Request request) async =>
      okJson((await _contactStore.changes()).toList(growable: false));

  /**
   *
   */
  Future<shelf.Response> objectHistory(shelf.Request request) async {
    final String cidParam = shelf_route.getPathParameter(request, 'cid');
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
  Future<shelf.Response> receptionHistory(shelf.Request request) async {
    final String cidParam = shelf_route.getPathParameter(request, 'cid');
    final String ridParam = shelf_route.getPathParameter(request, 'rid');
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
  Future<shelf.Response> cacheStats(shelf.Request request) async {
    return okJson(_cache.stats);
  }

  /**
   *
   */
  Future<shelf.Response> cachePrefill(shelf.Request request) async {
    await _cache.prefill();
    return cacheStats(request);
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
  Future<shelf.Response> receptionChangelog(shelf.Request request) async {
    final String cidParam = shelf_route.getPathParameter(request, 'cid');
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
  Future<shelf.Response> changelog(shelf.Request request) async {
    final String cidParam = shelf_route.getPathParameter(request, 'cid');
    int cid;
    try {
      cid = int.parse(cidParam);
    } on FormatException {
      return clientError('Bad cid: $cidParam');
    }

    return ok(await _contactStore.changeLog(cid));
  }
}
