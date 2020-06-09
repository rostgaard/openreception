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

library ors.controller.organization;

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:orf/validation.dart';
import 'package:ors/response_utils.dart';

class Organization {
  /// Default constructor.
  Organization(this._orgStore, this._notification, this._authService);

  final filestore.Organization _orgStore;
  final service.Authentication _authService;
  final service.NotificationService _notification;
  final Logger _log = Logger('ors.controller.organization');

  Future<Response> list(Request request) async =>
      okJson(List.from(await _orgStore.list()));

  Future<Response> receptionMap(Request request) async =>throw UnimplementedError();

  Future<Response> get(Request request, String oidParam) async {
    final int oid = int.parse(oidParam);
    try {
      return okJson(await _orgStore.get(oid));
    } on NotFound catch (error) {
      return notFound(error.toString());
    }
  }

  /// Request handler for listing every contact associated with the
  /// organization.
  Future<Response> contacts(Request request, String oidParam) async {
    final int oid = int.parse(oidParam);

    return okJson(
        (await _orgStore.contacts(oid)).toList(growable: false));
  }

  /// Request handler for listing every reception associated with the
  /// organization.
  Future<Response> receptions(Request request, String oidParam) async {
    final int orgid = int.parse(oidParam);

    return okJson(
        (await _orgStore.receptions(orgid)).toList(growable: false));
  }

  /// Request handler for creating a organization.
  Future<Response> create(Request request) async {
    model.Organization organization;
    model.User creator;

    try {
      organization = model.Organization.fromJson(
          json.decode(await request.readAsString()));

      final List<ValidationException> errors =
          validateOrganization(organization);

      if (errors.isNotEmpty) {
        throw errors.first;
      }
    } on ValidationException catch (error) {
      Map response = {
        'status': 'bad request',
        'description': 'passed organization argument '
            'is too long, missing or invalid',
        'error': error.toString()
      };
      return clientErrorJson(response);
    }

    try {
      creator = await _authService.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    final oRef = await _orgStore.create(organization, creator);
    final evt = event.OrganizationChange.create(oRef.id, creator.id);

    try {
      await _notification.broadcastEvent(evt);
    } catch (e) {
      _log.warning('$e: Failed to send $evt');
    }

    return okJson(oRef);
  }

  /// Update an organization.
  Future<Response> update(Request request, String oidParam) async {
    model.Organization org;
    model.User modifier;
    try {
      org = model.Organization.fromJson(
          json.decode(await request.readAsString()));

      final List<ValidationException> errors = validateOrganization(org);

      if (errors.isNotEmpty) {
        throw errors.first;
      }
    } on FormatException catch (error) {
      Map response = {
        'status': 'bad request',
        'description': 'passed organization argument '
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

    try {
      final rRef = await _orgStore.update(org, modifier);
      final evt = event.OrganizationChange.update(rRef.id, modifier.id);

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

  /// Removes a single organization from the data store.
  Future<Response> remove(Request request, final String oidParam) async {
    final int oid = int.parse(oidParam);
    model.User modifier;

    try {
      modifier = await _authService.userOf(tokenFrom(request));
    } catch (e) {
      return authServerDown();
    }

    try {
      await _orgStore.remove(oid, modifier);
      final evt = event.OrganizationChange.delete(oid, modifier.id);

      try {
        await _notification.broadcastEvent(evt);
      } catch (e) {
        _log.warning('$e: Failed to send $evt');
      }

      return okJson(
          {'status': 'ok', 'description': 'Organization deleted'});
    } on NotFound {
      return notFoundJson({'description': 'No Organization found with ID $oid'});
    }
  }

  Future<Response> history(Request request) async =>
      okJson((await _orgStore.changes()).toList(growable: false));

  Future<Response> objectHistory(Request request, final String oidParam) async {
    int oid;
    try {
      oid = int.parse(oidParam);
    } on FormatException {
      return clientError('Bad oid: $oidParam');
    }

    return okJson(
        (await _orgStore.changes(oid)).toList(growable: false));
  }

  Future<Response> changelog(Request request, String oidParam) async {
    int oid;
    try {
      oid = int.parse(oidParam);
    } on FormatException {
      return clientError('Bad oid: $oidParam');
    }

    return okJson((await _orgStore.changeLog(oid)));
  }
}
