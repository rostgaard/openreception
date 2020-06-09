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

library orf.model;


//import 'package:logging/logging.dart';
//import 'package:orf/bus.dart';
//import 'package:orf/src/constants/model.dart' as key;
//import 'package:orf/util.dart' as util;
import 'package:orf/event.dart' as _event;

//import 'package:path/path.dart' as path;
import 'package:orf/api.dart' as api_model;
import 'package:orf/bus.dart';

import 'package:orf/model/dialplan/model-dialplan.dart' as model;

export 'package:orf/model/dialplan/model-dialplan.dart';
export 'package:orf/monitoring.dart';

export 'api.dart';

part 'model/model-owner.dart';


const int noId = 0;


class Reference {
  const Reference(this.id, this.name);
  final int id;
  final String name;
}

String _normalize(String str) => str.replaceAll(' ', '').replaceAll('+', '');

/// Available types for [BaseContact] objects.
abstract class ContactType {
  /// Human/Person type.
  ///
  /// Refers to a real person.
  static const String human = 'human';

  /// Function type.
  ///
  /// Used to cover functional groups of persons. For example 'support' or
  /// 'sales'.
  static const String function = 'function';

  /// Invisible type.
  ///
  /// Used to hide persons or functions.
  static const String invisible = 'invisible';

  /// Iterable enumerating the different contact types.
  static const Iterable<String> types = const <String>[
    human,
    function,
    invisible
  ];

}
api_model.Call noCall = api_model.Call();

extension MessageFilterExtensions on api_model.MessageFilter {
/// Check if this filter is active (any field is set).
bool get active =>
    userId != noId ||
        receptionId != noId ||
        contactId != noId;

/// Check if the filter applies to [message].
bool appliesTo(api_model.Message message) =>
    <int>[message.context.cid, noId].contains(contactId) &&
        <int>[message.context.rid, noId].contains(receptionId) &&
        <int>[message.sender.id, noId].contains(userId);

/// Filters [messages] using this filter.
Iterable<api_model.Message> filter(Iterable<api_model.Message> messages) =>
    messages.where((api_model.Message message) => appliesTo(message));
}

extension PhoneNumberExtension on api_model.PhoneNumber {
  String get normalizedExtension => _normalize(this.destination);
}

extension UserExtensions on api_model.User {

  api_model.UserReference get reference => api_model.UserReference()
    ..id = this.id
    ..name = this.name;
}

extension ReceptionReferenceExtension on api_model.Reception {
  api_model.ReceptionReference get reference => api_model.ReceptionReference()
    ..id = this.id
    ..name = this.name;
}

extension OrganizationReferenceExtension on api_model.Organization {
  api_model.OrganizationReference get reference =>
      api_model.OrganizationReference()
        ..id = this.id
        ..name = this.name;
}

/// User groups "enum".
abstract class UserGroups {
  /// Receptionist group.
  static const String receptionist = 'Receptionist';

  /// Administrator group.
  static const String administrator = 'Administrator';

  /// Service agent group.
  static const String serviceAgent = 'Service agent';

  /// List of all valid groups.
  static const Iterable<String> validGroups = const <String>[
    receptionist,
    administrator,
    serviceAgent
  ];

  /// Determine if [group] is valid.
  static bool isValid(String group) => validGroups.toSet().contains(group);
}

List<String> stringList(final List<dynamic> list) {
  return list.map((dynamic element) {
    if (element is String) {
      return element;
    }
    throw ArgumentError.value(element, "Element in list is not String");
  }).toList();
}

String changeTypeToString(api_model.ChangeType changeType) =>
    api_model.ChangeTypeTypeTransformer().encode(changeType);

api_model.ChangeType changeTypeFromString(String str) =>
    api_model.ChangeTypeTypeTransformer().decode(str);

/// [ChangelogEntry] interface.
abstract class ChangelogEntry {
  /// The time of the change.
  DateTime get timestamp;

  /// The type of change.
  api_model.ChangeType get changeType;

  /// The reference to the user who performed the change.
  api_model.UserReference get modifier;

  /// Serialization function.
  dynamic toJson();
}

/// Object change specialization for [User] object changes
class UserChange extends api_model.ObjectChange {
  UserChange(api_model.ChangeType changeType, this.uid) : super() {
    changeType = changeType;
  }

  UserChange.fromJson(Map<String, dynamic> map)
      : uid = map['uid'],
        super.fromJson(map);

  @override
  final api_model.ObjectType objectType = api_model.ObjectType.user_;
  final int uid;

  @deprecated
  static UserChange decode(Map<String, dynamic> map) =>
      UserChange(changeTypeFromString(map['change']), map['uid']);

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({'uid': uid});
}

/// Object change specialization for [api_model.CalendarEntry] object changes
class CalendarChange extends api_model.ObjectChange {
  CalendarChange(api_model.ChangeType changeType, this.eid) : super() {
    changeType = changeType;
  }

  CalendarChange.fromJson(Map<String, dynamic> map)
      : eid = map['eid'],
        super.fromJson(map);

  @override
  final api_model.ObjectType objectType = api_model.ObjectType.calendar_;
  final int eid;

  @deprecated
  static CalendarChange decode(Map<String, dynamic> map) =>
      CalendarChange(changeTypeFromString(map['change']), map['ied']);

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({'eid': eid});
}

/// Object change specialization for [model.IvrMenu] object changes
class IvrChange extends api_model.ObjectChange {
  IvrChange(api_model.ChangeType changeType, this.ivrName) : super() {
    changeType = changeType;
  }

  IvrChange.fromJson(Map<String, dynamic> map)
      : ivrName = map['ivrName'],
        super.fromJson(map);

  @override
  final api_model.ObjectType objectType = api_model.ObjectType.ivrMenu_;
  final String ivrName;

  @deprecated
  static IvrChange decode(Map<String, dynamic> map) =>
      IvrChange(changeTypeFromString(map['change']), map['ivrName']);

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({'ivrName': ivrName});
}

/// Object change specialization for [model.ReceptionDialplan] object changes
class ReceptionDialplanChange extends api_model.ObjectChange {
  ReceptionDialplanChange(api_model.ChangeType changeType, this.extension) : super() {
    changeType = changeType;
  }

  ReceptionDialplanChange.fromJson(Map<String, dynamic> map)
      : extension = map['extension'],
        super.fromJson(map);

  @override
  final api_model.ObjectType objectType = api_model.ObjectType.dialplan_;
  final String extension;

  @deprecated
  static ReceptionDialplanChange decode(Map<String, dynamic> map) =>
      ReceptionDialplanChange(changeTypeFromString(map['change']), map['extension']);

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({'extension': extension});
}

class CalendarChangelogEntry implements ChangelogEntry {
  CalendarChangelogEntry.create(this.modifier, this.entry)
      : changeType = api_model.ChangeType.add_,
        timestamp = DateTime.now();

  CalendarChangelogEntry.update(this.modifier, this.entry)
      : changeType = api_model.ChangeType.modify_,
        timestamp = DateTime.now();

  CalendarChangelogEntry.delete(this.modifier, int eid)
      : changeType = api_model.ChangeType.delete_,
        entry = api_model.CalendarEntry()..id = eid,
        timestamp = DateTime.now();

  CalendarChangelogEntry.fromJson(Map<String, dynamic> map)
      : modifier = api_model.UserReference.fromJson(
            map['modifier'] as Map<String, dynamic>),
        entry = api_model.CalendarEntry.fromJson(
            map['entry'] as Map<String, dynamic>),
        changeType = changeTypeFromString(map['change']),
        timestamp = DateTime.parse(map['timestamp']);
  @override
  final DateTime timestamp;

  @override
  final api_model.ChangeType changeType;

  @override
  final api_model.UserReference modifier;

  final api_model.CalendarEntry entry;

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'change': changeTypeToString(changeType),
        'timestamp': timestamp.toIso8601String(),
        'modifier': modifier.toJson(),
        'entry': entry.toJson()
      };
}

class ContactChangelogEntry implements ChangelogEntry {
  ContactChangelogEntry.create(this.modifier, this.contact)
      : changeType = api_model.ChangeType.add_,
        timestamp = DateTime.now();

  ContactChangelogEntry.update(this.modifier, this.contact)
      : changeType = api_model.ChangeType.modify_,
        timestamp = DateTime.now();

  ContactChangelogEntry.delete(this.modifier, int cid)
      : changeType = api_model.ChangeType.delete_,
        contact = api_model.BaseContact()..id = cid,
        timestamp = DateTime.now();

  ContactChangelogEntry.fromJson(Map<String, dynamic> map)
      : modifier = api_model.UserReference.fromJson(
            map['modifier'] as Map<String, dynamic>),
        contact = api_model.BaseContact.fromJson(
            map['contact'] as Map<String, dynamic>),
        changeType = changeTypeFromString(map['change']),
        timestamp = DateTime.parse(map['timestamp']);
  @override
  final DateTime timestamp;

  @override
  final api_model.ChangeType changeType;

  @override
  final api_model.UserReference modifier;

  final api_model.BaseContact contact;

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'change': changeTypeToString(changeType),
        'modifier': timestamp.toIso8601String(),
        'user': modifier.toJson(),
        'contact': contact.toJson()
      };
}

class ReceptionDataChangelogEntry implements ChangelogEntry {
  ReceptionDataChangelogEntry.create(this.modifier, this.attributes)
      : changeType = api_model.ChangeType.add_,
        timestamp = DateTime.now();

  ReceptionDataChangelogEntry.update(this.modifier, this.attributes)
      : changeType = api_model.ChangeType.modify_,
        timestamp = DateTime.now();

  ReceptionDataChangelogEntry.delete(this.modifier, int cid, int rid)
      : changeType = api_model.ChangeType.delete_,
        attributes = api_model.ReceptionAttributes()
          ..cid = cid
          ..receptionId = rid,
        timestamp = DateTime.now();

  ReceptionDataChangelogEntry.fromJson(Map<String, dynamic> map)
      : modifier = api_model.UserReference.fromJson(
            map['modifier'] as Map<String, dynamic>),
        attributes = api_model.ReceptionAttributes.fromJson(
            map['attributes'] as Map<String, dynamic>),
        changeType = changeTypeFromString(map['change']),
        timestamp = DateTime.parse(map['timestamp']);
  @override
  final DateTime timestamp;

  @override
  final api_model.ChangeType changeType;

  @override
  final api_model.UserReference modifier;

  final api_model.ReceptionAttributes attributes;

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'change': changeTypeToString(changeType),
        'timestamp': timestamp.toIso8601String(),
        'modifier': modifier.toJson(),
        'attributes': attributes.toJson()
      };
}

class IvrChangelogEntry implements ChangelogEntry {
  IvrChangelogEntry.create(this.modifier, this.menu)
      : changeType = api_model.ChangeType.add_,
        timestamp = DateTime.now();

  IvrChangelogEntry.update(this.modifier, this.menu)
      : changeType = api_model.ChangeType.modify_,
        timestamp = DateTime.now();

  IvrChangelogEntry.delete(this.modifier, String menuName)
      : changeType = api_model.ChangeType.delete_,
        menu = model.IvrMenu('', model.Playback(''))..name = menuName,
        timestamp = DateTime.now();

  IvrChangelogEntry.fromJson(Map<String, dynamic> map)
      : modifier = api_model.UserReference.fromJson(
            map['modifier'] as Map<String, dynamic>),
        menu = model.IvrMenu.fromJson(map['menu'] as Map<String, dynamic>),
        changeType = changeTypeFromString(map['change']),
        timestamp = DateTime.parse(map['timestamp']);

  @override
  final DateTime timestamp;

  @override
  final api_model.ChangeType changeType;

  @override
  final api_model.UserReference modifier;

  final model.IvrMenu menu;

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'change': changeTypeToString(changeType),
        'timestamp': timestamp.toIso8601String(),
        'modifier': modifier.toJson(),
        'menu': menu.toJson()
      };
}

class DialplanChangelogEntry implements ChangelogEntry {
  DialplanChangelogEntry.create(this.modifier, this.dialplan)
      : changeType = api_model.ChangeType.add_,
        timestamp = DateTime.now();

  DialplanChangelogEntry.update(this.modifier, this.dialplan)
      : changeType = api_model.ChangeType.modify_,
        timestamp = DateTime.now();

  DialplanChangelogEntry.delete(this.modifier, String extension)
      : changeType = api_model.ChangeType.delete_,
        dialplan = model.ReceptionDialplan()..extension = extension,
        timestamp = DateTime.now();

  DialplanChangelogEntry.fromJson(Map<String, dynamic> map)
      : modifier = api_model.UserReference.fromJson(
            map['modifier'] as Map<String, dynamic>),
        dialplan = model.ReceptionDialplan.fromJson(
            map['dialplan'] as Map<String, dynamic>),
        changeType = changeTypeFromString(map['change']),
        timestamp = DateTime.parse(map['timestamp']);
  @override
  final DateTime timestamp;

  @override
  final api_model.ChangeType changeType;

  @override
  final api_model.UserReference modifier;

  final model.ReceptionDialplan dialplan;

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'change': changeTypeToString(changeType),
        'timestamp': timestamp.toIso8601String(),
        'modifier': modifier.toJson(),
        'dialplan': dialplan.toJson()
      };
}

class ReceptionChangelogEntry implements ChangelogEntry {
  ReceptionChangelogEntry.create(this.modifier, this.reception)
      : changeType = api_model.ChangeType.add_,
        timestamp = DateTime.now();

  ReceptionChangelogEntry.update(this.modifier, this.reception)
      : changeType = api_model.ChangeType.modify_,
        timestamp = DateTime.now();

  ReceptionChangelogEntry.delete(this.modifier, int rid)
      : changeType = api_model.ChangeType.delete_,
        reception = api_model.Reception()..id = rid,
        timestamp = DateTime.now();

  ReceptionChangelogEntry.fromJson(Map<String, dynamic> map)
      : modifier = api_model.UserReference.fromJson(
            map['modifier'] as Map<String, dynamic>),
        reception = api_model.Reception.fromJson(
            map['reception'] as Map<String, dynamic>),
        changeType = changeTypeFromString(map['change']),
        timestamp = DateTime.parse(map['timestamp']);
  @override
  final DateTime timestamp;

  @override
  final api_model.ChangeType changeType;

  @override
  final api_model.UserReference modifier;

  final api_model.Reception reception;

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'change': changeTypeToString(changeType),
        'timestamp': timestamp.toIso8601String(),
        'modifier': modifier.toJson(),
        'reception': reception.toJson()
      };
}

class OrganizationChangelogEntry implements ChangelogEntry {
  OrganizationChangelogEntry.create(this.modifier, this.organization)
      : changeType = api_model.ChangeType.add_,
        timestamp = DateTime.now();

  OrganizationChangelogEntry.update(this.modifier, this.organization)
      : changeType = api_model.ChangeType.modify_,
        timestamp = DateTime.now();

  OrganizationChangelogEntry.delete(this.modifier, int oid)
      : changeType = api_model.ChangeType.delete_,
        organization = api_model.Organization()..id = oid,
        timestamp = DateTime.now();

  OrganizationChangelogEntry.fromJson(Map<String, dynamic> map)
      : modifier = api_model.UserReference.fromJson(
            map['modifier'] as Map<String, dynamic>),
        organization = api_model.Organization.fromJson(
            map['organization'] as Map<String, dynamic>),
        changeType = changeTypeFromString(map['change']),
        timestamp = DateTime.parse(map['timestamp']);

  @override
  final DateTime timestamp;

  @override
  final api_model.ChangeType changeType;

  @override
  final api_model.UserReference modifier;

  final api_model.Organization organization;

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'change': changeTypeToString(changeType),
        'timestamp': timestamp.toIso8601String(),
        'modifier': modifier.toJson(),
        'organization': organization.toJson()
      };
}

class UserChangelogEntry implements ChangelogEntry {
  UserChangelogEntry.create(this.modifier, this.user)
      : changeType = api_model.ChangeType.add_,
        timestamp = DateTime.now();

  UserChangelogEntry.update(this.modifier, this.user)
      : changeType = api_model.ChangeType.modify_,
        timestamp = DateTime.now();

  UserChangelogEntry.delete(this.modifier, int uid)
      : changeType = api_model.ChangeType.delete_,
        user = api_model.User()..id = uid,
        timestamp = DateTime.now();

  UserChangelogEntry.fromJson(Map<String, dynamic> map)
      : modifier = api_model.UserReference.fromJson(
            map['modifier'] as Map<String, dynamic>),
        user = api_model.User.fromJson(map['user'] as Map<String, dynamic>),
        changeType = changeTypeFromString(map['change']),
        timestamp = DateTime.parse(map['timestamp']);

  @override
  final DateTime timestamp;

  @override
  final api_model.ChangeType changeType;

  @override
  final api_model.UserReference modifier;

  final api_model.User user;

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'change': changeTypeToString(changeType),
        'timestamp': timestamp.toIso8601String(),
        'modifier': modifier.toJson(),
        'user': user.toJson()
      };
}


class MessageChange extends api_model.ObjectChange {
  MessageChange(api_model.ChangeType changeType, this.mid) {
    changeType = changeType;
  }


  MessageChange.fromJson(Map<String, dynamic> map)
      : mid = map['mid'],
        super.fromJson(map);

  final int mid;

  @deprecated
  static MessageChange decode(Map<String, dynamic> map) =>
       MessageChange.fromJson(map);
}

class OrganizationChange extends api_model.ObjectChange {
  OrganizationChange(api_model.ChangeType changeType, this.oid) {
    changeType = changeType;
  }

  OrganizationChange.fromJson(Map<String, dynamic> map)
      : oid = map['oid'],
        super.fromJson(map);

  final api_model.ObjectType objectType = api_model.ObjectType.organization_;
  final int oid;
  @deprecated
  static OrganizationChange decode(Map<String, dynamic> map) =>
      OrganizationChange.fromJson(map);

  /// Returns a map representation of the object.
  ///
  /// Suitable for serialization.
  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({'oid': oid});
}

class ReceptionChange extends api_model.ObjectChange {
  ReceptionChange(api_model.ChangeType changeType, this.rid) {
    changeType = changeType;
  }

  ReceptionChange.fromJson(Map<String, dynamic> map)
      : rid = map['rid'],
        super.fromJson(map);

  final api_model.ObjectType objectType = api_model.ObjectType.reception_;
  final int rid;
  @deprecated
  static ReceptionChange decode(Map<String, dynamic> map) =>
      ReceptionChange.fromJson(map);

  /// Returns a map representation of the object.
  ///
  /// Suitable for serialization.
  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({'rid': rid});
}

class ContactChange extends api_model.ObjectChange {
  ContactChange(api_model.ChangeType changeType, this.cid) {
    changeType = changeType;
  }

  ContactChange.fromJson(Map<String, dynamic> map)
      : cid = map['cid'],
        super.fromJson(map);

  final api_model.ObjectType objectType = api_model.ObjectType.contact_;
  final int cid;
  @deprecated
  static ContactChange decode(Map<String, dynamic> map) =>
      ContactChange.fromJson(map);

  /// Returns a map representation of the object.
  ///
  /// Suitable for serialization.
  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({'cid': cid});
}

class ReceptionAttributeChange extends api_model.ObjectChange {
  ReceptionAttributeChange(
      api_model.ChangeType changeType, this.cid, this.rid) {
    changeType = changeType;
  }

  ReceptionAttributeChange.fromJson(Map<String, dynamic> map)
      : cid = map['cid'],
        rid = map['rid'],
        super.fromJson(map);

  @override
  final api_model.ObjectType objectType =
      api_model.ObjectType.receptionAttribute_;
  final int cid;
  final int rid;

  @deprecated
  static ReceptionAttributeChange decode(Map<String, dynamic> map) =>
      ReceptionAttributeChange.fromJson(map);

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..addAll({'cid': cid, 'rid': rid});
}
