/*                  This file is part of OpenReception
                   Copyright (C) 2016-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/model.dart' as or_model;
import 'package:openreception_framework/model.dart' as old_or_model;
import 'package:openreception_framework/service-io.dart' as old_or_service;
import 'package:openreception_framework/service.dart' as old_or_service;

class MigrationEnvironment {
  final Logger _log = new Logger('or_migrate');

  final filestore.DataStore _dataStore;

  final modifier = new or_model.User.empty()..name = 'Import script';

  final old_or_service.RESTOrganizationStore organizationService;
  final old_or_service.RESTReceptionStore receptionService;
  final old_or_service.RESTContactStore contactService;
  final old_or_service.RESTUserStore userService;
  final old_or_service.RESTEndpointStore endpointService;
  final old_or_service.RESTIvrStore ivrService;
  final old_or_service.RESTDialplanStore dialplanService;
  final old_or_service.RESTCalendarStore calendarService;
  final old_or_service.RESTMessageStore messageService;

  /**
   *
   */
  MigrationEnvironment(
      this._dataStore,
      this.organizationService,
      this.receptionService,
      this.contactService,
      this.userService,
      this.endpointService,
      this.ivrService,
      this.dialplanService,
      this.calendarService,
      this.messageService);

  /**
   * Import messages.
   */
  Future importMessages() async {
    final Stopwatch timer = new Stopwatch()..start();
    final Iterable messages = await messageService.list(
        filter: new old_or_model.MessageFilter.empty()..limitCount = 100000000);

    Iterable<Future<or_model.Message>> converted = messages.map(convertMessage);

    for (Future<or_model.Message> msg in converted) {
      await _dataStore.messageStore
          .create(await msg, modifier, enforceId: true);
    }

    _log.info('Imported ${converted.length} messages'
        ' in ${timer.elapsedMilliseconds}ms');
  }

  /**
   * Imports users
   */
  Future importUsers() async {
    final Stopwatch timer = new Stopwatch()..start();
    final users = await userService.list();

    Iterable<or_model.User> converted =
        await Future.wait(users.map((old_or_model.User user) async {
      Iterable groups = await userService.userGroups(user.id);
      Iterable identities = await userService.identities(user.id);

      return convertUser(user, groups.map((group) => group.name),
          identities.map((iden) => iden.identity));
    }));

    await Future.wait(converted.map((or_model.User user) =>
        _dataStore.userStore.create(user, modifier, enforceId: true)));

    _log.info('Imported ${converted.length} users'
        ' in ${timer.elapsedMilliseconds}ms');
  }

  /// Imports dialplans
  Future importDialplans() async {
    final Stopwatch timer = new Stopwatch()..start();
    final Iterable dialplans = await dialplanService.list();

    Iterable<or_model.ReceptionDialplan> converted =
        dialplans.map(convertDialplan);

    await Future.forEach(
        converted,
        (or_model.ReceptionDialplan rdp) =>
            _dataStore.receptionDialplanStore.create(rdp, modifier));

    _log.info('Imported ${converted.length} dialplans'
        ' in ${timer.elapsedMilliseconds}ms');
  }

  /// Imports organizations
  Future importOrganizations() async {
    final Stopwatch timer = new Stopwatch()..start();
    final Iterable orgs = await organizationService.list();

    Iterable<or_model.Organization> converted = orgs.map(convertOrg);

    await Future.forEach(
        converted,
        (or_model.Organization org) => _dataStore.organizationStore
            .create(org, modifier, enforceId: true));

    _log.info('Imported ${converted.length} dialplans'
        ' in ${timer.elapsedMilliseconds}ms');
  }

  /// Imports receptions
  Future importReceptions() async {
    final Stopwatch timer = new Stopwatch()..start();
    final Iterable recs = await receptionService.list();

    int skipped = 0;
    int failed = 0;
    List<or_model.Reception> converted = [];
    recs.forEach(((rec) {
      try {
        converted.add(convertReception(rec));
      } catch (e, stackTrace) {
        failed++;
        _log.shout('Failed to import ${rec.name} (rid:${rec.ID})');
        print(e);
        print(stackTrace);
      }
    }));

    await Future.forEach(converted, (or_model.Reception rec) async {
      if (rec.enabled) {
        _log.finest('Importing ${rec.name} (rid:${rec.id})');

        await _dataStore.receptionStore.create(rec, modifier, enforceId: true);
      } else {
        skipped++;
        _log.info('Skipping ${rec.name} (rid:${rec.id})');
      }
    });

    _log.info('Imported ${converted.length} receptions '
        'in ${timer.elapsedMilliseconds}ms '
        '($skipped skipped, $failed failed)');
  }

  /**
   * Imports dialplans
   */
  Future importIvrs() async {
    final Stopwatch timer = new Stopwatch()..start();
    final Iterable ivrs = await ivrService.list();

    Iterable<or_model.IvrMenu> converted = ivrs.map(convertIvr);

    await Future.forEach(converted,
        (or_model.IvrMenu menu) => _dataStore.ivrStore.create(menu, modifier));

    _log.info('Imported ${converted.length} ivr menus'
        ' in ${timer.elapsedMilliseconds}ms');
  }

  /**
   * Import base contacts.
   */
  Future importBaseContacts() async {
    final Stopwatch timer = new Stopwatch()..start();
    final contacts = await contactService.list();

    Iterable<or_model.BaseContact> converted = contacts.map(convertContact);

    await Future.forEach(converted, (or_model.BaseContact contact) async {
      if (contact.enabled) {
        _log.finest('Importing ${contact.name} (cid:${contact.id})');
        await _dataStore.contactStore
            .create(contact, modifier, enforceId: true);
      } else {
        _log.info('Skipping ${contact.name} (cid:${contact.id})');
      }
    });

    _log.info('Imported ${converted.length} base contacts'
        ' in ${timer.elapsedMilliseconds}ms');
  }

  /**
   *
   */
  Future importCalendarEntries() async {
    final Stopwatch timer = new Stopwatch()..start();
    final  contacts = await contactService.list();

    int count = 0;
    await Future.forEach(contacts, (old_or_model.BaseContact contact) async {
      if (contact.enabled) {
        final entries = await calendarService
            .list(new old_or_model.OwningContact(contact.id));

        await Future.forEach(entries.map(convertCalendarEntry),
            (Future<or_model.CalendarEntry> ce) async {
          try {
            final or_model.User user = new or_model.User.empty()
              ..id = (await ce).lastAuthorId;
            await _dataStore.contactStore.calendarStore.create(
                await ce, new or_model.OwningContact(contact.id), user,
                enforceId: true);
            count++;
          } catch (e) {
            _log.warning(
                'Failed to import calendar entry for contact ${contact.id}');
          }
        });
      } else {
        _log.info(
            'Skipping calendar import ${contact.fullName} (cid:${contact.id})');
      }
    });

    final  recs = await receptionService.list();
    await Future.forEach(recs, (old_or_model.Reception rec) async {
      if (rec.enabled) {
        final entries = await calendarService
            .list(new old_or_model.OwningReception(rec.ID));

        await Future.forEach(entries.map(convertCalendarEntry),
            (Future<or_model.CalendarEntry> ce) async {
          try {
            final or_model.User user = new or_model.User.empty()
              ..id = (await ce).lastAuthorId;
            await _dataStore.receptionStore.calendarStore.create(
                await ce, new or_model.OwningReception(rec.ID), user,
                enforceId: true);
            count++;
          } catch (e) {
            _log.warning(
                'Failed to import calendar entry for reception ${rec.ID}');
          }
        });
      } else {
        _log.info('Skipping calendar import ${rec.fullName} (cid:${rec.ID})');
      }
    });

    _log.info('Imported ${count} calendar entries'
        ' in ${timer.elapsedMilliseconds}ms');
  }

  /// Import reception attributes.
  Future importReceptionAttributes() async {
    final Stopwatch timer = new Stopwatch()..start();
    final Iterable recs = await receptionService.list();

    int count = 0;
    await Future.forEach(recs, (rec) async {
      Iterable attrs = await contactService.listByReception(rec.ID);

      try {
        await Future.forEach(attrs, (attr) async {
          Iterable<old_or_model.MessageEndpoint> oldEps =
              await endpointService.list(attr.receptionID, attr.ID);

          List<or_model.MessageEndpoint> meps = [];
          for (old_or_model.MessageEndpoint oldEp in oldEps) {
            or_model.MessageEndpoint ep = new or_model.MessageEndpoint.empty();

            ep
              ..name = attr.fullName
              ..address = oldEp.address
              ..note = oldEp.description;
            meps.add(ep);
          }

          final converted = convertAttr(attr, meps);
          await _dataStore.contactStore.addData(converted, modifier);
          count++;
        });
      } catch (e, s) {
        _log.shout('${rec.fullName}', e, s);
      }
    });

    _log.info('Imported ${count} reception attributes'
        ' in ${timer.elapsedMilliseconds}ms');
  }

  /// Validates users
  Future validateUsers() async {
    final Stopwatch timer = new Stopwatch()..start();
    final Iterable localUsers = await _dataStore.userStore.list();

    Future.forEach(localUsers, (local) async {
      final remote = await userService.get(local.id);

      if (local.name != remote.name) {
        _log.shout('User (uid: ${local.id}): ${local.name} != ${remote.name}');
      }
    });

    _log.info('Validated ${localUsers.length} users'
        ' in ${timer.elapsedMilliseconds}ms');
  }

  /// Validates receptions
  Future validateReceptions() async {
    final Stopwatch timer = new Stopwatch()..start();
    final Iterable localUsers = await _dataStore.userStore.list();

    Future.forEach(localUsers, (local) async {
      final remote = await userService.get(local.id);

      if (local.name != remote.name) {
        _log.shout('User (uid: ${local.id}): ${local.name} != ${remote.name}');
      }
    });

    _log.info('Validated ${localUsers.length} users'
        ' in ${timer.elapsedMilliseconds}ms');
  }

  /**
   *
   */
  Future<or_model.Message> convertMessage(old_or_model.Message oldMsg) async {
    Set<or_model.MessageEndpoint> rcps = new Set.from(
        oldMsg.recipients.map((rcp) => new or_model.MessageEndpoint.empty()
          ..type = convertEndpointType(rcp)
          ..address = rcp.address
          ..name = rcp.contactName
          ..note = 'IMPORT: ${rcp.receptionName}'));

    or_model.MessageState state;

    if (oldMsg.sent) {
      state = or_model.MessageState.sent;
    } else {
      state = or_model.MessageState.draft;
    }

    return new or_model.Message.empty()
      ..id = oldMsg.ID
      ..recipients = rcps
      ..context = (new or_model.MessageContext.empty()
        ..cid = oldMsg.context.contactID
        ..contactName = oldMsg.context.contactName
        ..rid = oldMsg.context.receptionID
        ..receptionName = oldMsg.context.receptionName)
      ..flag = new or_model.MessageFlag(oldMsg.flag.toJson().map((s) => s))
      ..callerInfo = (new or_model.CallerInfo.empty()
        ..name = oldMsg.callerInfo.name
        ..company = oldMsg.callerInfo.company
        ..phone = oldMsg.callerInfo.phone
        ..cellPhone = oldMsg.callerInfo.cellPhone
        ..localExtension = oldMsg.callerInfo.localExtension)
      ..createdAt = oldMsg.createdAt
      ..body = oldMsg.body
      ..callId = oldMsg.callId
      ..sender = await _dataStore.userStore.get(oldMsg.senderId)
      ..state = state;
  }

  /**
   *
   */
  or_model.IvrMenu convertIvr(old_or_model.IvrMenu menu) =>
      or_model.IvrMenu.fromJson(menu.toJson());

  /**
   *
   */
  or_model.ReceptionDialplan convertDialplan(
          old_or_model.ReceptionDialplan oldDialplan) =>
      new or_model.ReceptionDialplan()
        ..extension = oldDialplan.extension
        ..open = new List<or_model.HourAction>.from(
            oldDialplan.open.map(convertHourAction))
        ..note = oldDialplan.note
        ..defaultActions = new List<or_model.Action>.from(
            oldDialplan.defaultActions.map(convertDialplanAction))
        ..extraExtensions = new List<or_model.NamedExtension>.from(
            oldDialplan.extraExtensions.map(convertNamedExtension));

  /**
   *
   */
  or_model.NamedExtension convertNamedExtension(
          old_or_model.NamedExtension oldNe) =>
      new or_model.NamedExtension(
          oldNe.name,
          new List<or_model.Action>.from(
              oldNe.actions.map(convertDialplanAction)));

  /**
   *
   */
  or_model.HourAction convertHourAction(old_or_model.HourAction oldHa) =>
      new or_model.HourAction()
        ..hours = new List<or_model.OpeningHour>.from(
            oldHa.hours.map(convertOpeningHour))
        ..actions = new List<or_model.Action>.from(
            oldHa.actions.map(convertDialplanAction));

  /**
   *
   */
  or_model.OpeningHour convertOpeningHour(old_or_model.OpeningHour oldOh) =>
      or_model.OpeningHour.parse(oldOh.toJson());

  /**
   *
   */
  or_model.Action convertDialplanAction(old_or_model.Action oldAction) =>
      or_model.Action.parse(oldAction.toJson());

  /**
   *
   */
  String convertEndpointType(oldEp) {
    if (oldEp.type == 'sms') {
      return or_model.MessageEndpointType.sms;
    } else if (oldEp.type == 'email') {
      if (oldEp.role == old_or_model.Role.TO) {
        return or_model.MessageEndpointType.emailTo;
      } else if (oldEp.role == old_or_model.Role.CC) {
        return or_model.MessageEndpointType.emailCc;
      } else if (oldEp.role == old_or_model.Role.BCC) {
        return or_model.MessageEndpointType.emailBcc;
      } else {
        throw new ArgumentError.value(
            oldEp, 'oldEp.role', 'Bad role: ${oldEp.role}');
      }
    } else {
      throw new ArgumentError.value(
          oldEp, 'oldEp.type', 'Bad type: ${oldEp.type}');
    }
  }

  /**
   *
   */
  or_model.ReceptionAttributes convertAttr(old_or_model.Contact oldCon,
          List<or_model.MessageEndpoint> endpoints) =>
      new or_model.ReceptionAttributes.empty()
        ..cid = oldCon.ID
        ..receptionId = oldCon.receptionID
        ..phoneNumbers = new List<or_model.PhoneNumber>.from(
            oldCon.phones.map(convertPhoneNumber))
        ..endpoints = endpoints
        ..backupContacts = oldCon.backupContacts
        ..messagePrerequisites = oldCon.messagePrerequisites
        ..tags = oldCon.tags
        ..emailaddresses = oldCon.emailaddresses
        ..handling = oldCon.handling
        ..workhours = oldCon.workhours
        ..titles = oldCon.titles
        ..responsibilities = oldCon.responsibilities
        ..relations = oldCon.relations
        ..departments = oldCon.departments
        ..infos = oldCon.infos;

  /**
   *
   */
  or_model.Organization convertOrg(old_or_model.Organization oldOrg) {
    List<String> notes = [];

    if (oldOrg.billingType.trim().isNotEmpty) {
      notes.add(oldOrg.billingType.trim());
    }

    if (oldOrg.flag.trim().isNotEmpty) {
      notes.add(oldOrg.flag.trim());
    }

    return new or_model.Organization.empty()
      ..id = oldOrg.id
      ..name = oldOrg.fullName
      ..notes = notes;
  }

  /**
   *
   */
  or_model.User convertUser(
          old_or_model.User oldUser, Iterable groups, Iterable identities) =>
      new or_model.User.empty()
        ..id = oldUser.id
        ..name = oldUser.name
        ..address = oldUser.address
        ..extension = oldUser.peer
        ..groups = groups.toSet()
        ..identities = identities.toSet();

  /**
   *
   */
  or_model.Reception convertReception(old_or_model.Reception oldRec) =>
      new or_model.Reception.empty()
        ..id = oldRec.ID
        ..name = oldRec.fullName
        ..oid = oldRec.organizationId
        ..addresses = oldRec.addresses
        ..alternateNames = oldRec.alternateNames
        ..bankingInformation = oldRec.bankingInformation
        ..salesMarketingHandling = oldRec.salesMarketingHandling
        ..emailAddresses = oldRec.emailAddresses
        ..handlingInstructions = oldRec.handlingInstructions
        ..openingHours = oldRec.openingHours
        ..vatNumbers = oldRec.vatNumbers
        ..websites = oldRec.websites
        ..customerTypes = oldRec.customerTypes
        ..phoneNumbers = oldRec.telephoneNumbers
            .map(convertPhoneNumber)
            .toList(growable: false)
        ..miniWiki = oldRec.miniWiki
        ..dialplan = oldRec.dialplan
        ..greeting = oldRec.greeting
        ..otherData = oldRec.otherData
        ..product = oldRec.product
        ..enabled = oldRec.enabled
        ..shortGreeting = oldRec.shortGreeting;

  /**
   *
   */
  or_model.BaseContact convertContact(old_or_model.BaseContact oldCon) =>
      new or_model.BaseContact.empty()
        ..id = oldCon.id
        ..name = oldCon.fullName
        ..type = oldCon.contactType
        ..enabled = oldCon.enabled;

  /**
   *
   */
  or_model.PhoneNumber convertPhoneNumber(old_or_model.PhoneNumber oldPn) {
    or_model.PhoneNumber pn = new or_model.PhoneNumber.empty()
      ..confidential = oldPn.confidential
      ..note = oldPn.description
      ..destination = oldPn.endpoint;

    return pn;
  }

  /**
   *
   */
  Future<or_model.CalendarEntry> convertCalendarEntry(
      old_or_model.CalendarEntry oldCe) async {
    Iterable<old_or_model.CalendarEntryChange> changes =
        await calendarService.changes(oldCe.ID);

    return new or_model.CalendarEntry.empty()
      ..id = oldCe.ID
      ..lastAuthorId = changes.first.userID
      ..touched = changes.first.changedAt
      ..content = oldCe.content
      ..start = oldCe.start
      ..stop = oldCe.stop;
  }
}
