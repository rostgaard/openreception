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

part of orf.model;

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

abstract class ObjectReference {
  int get id;
  String get name;

  Map<String, dynamic> toJson();
}

@deprecated
class ContactReference implements ObjectReference {
  const ContactReference(this.id, this.name);

  @override
  final int id;
  @override
  final String name;


  @deprecated
  static ContactReference decode(Map<String, dynamic> map) =>
      ContactReference(map[key.id] as int, map[key.name] as String);

  bool get isEmpty => id == BaseContact.noId;

  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{key.id: id, key.name: name};

  @override
  bool operator ==(Object other) => other is ContactReference && id == other.id;

  @override
  int get hashCode => toString().hashCode;
}

class ContactChange implements ObjectChange {
  ContactChange(this.changeType, this.cid);

  ContactChange.fromJson(Map<String, dynamic> map)
      : changeType = changeTypeFromString(map[key.change] as String),
        cid = map[key.cid] as int;
  @override
  final ChangeType changeType;

  @override
  final ObjectType objectType = ObjectType.contact;
  final int cid;



  @deprecated
  static ContactChange decode(Map<String, dynamic> map) =>
      ContactChange(changeTypeFromString(map[key.change]), map[key.cid]);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        key.change: changeTypeToString(changeType),
        key.type: objectTypeToString(objectType),
        key.cid: cid
      };
}

class OrganizationReference implements ObjectReference {


  const OrganizationReference(this.id, this.name);

  factory OrganizationReference.fromJson(Map<String, dynamic> map) =>
      OrganizationReference(map[key.id], map[key.name]);

  @override
  final int id;
  @override
  final String name;

  @deprecated
  static OrganizationReference decode(Map<String, dynamic> map) =>
      OrganizationReference.fromJson(map);

  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{key.id: id, key.name: name};

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      other is OrganizationReference && other.id == id;
}

class ReceptionContact {
  final BaseContact contact;
  final ReceptionAttributes attr;

  ReceptionContact(this.contact, this.attr);

  ReceptionContact.empty()
      : contact = BaseContact.empty(),
        attr = ReceptionAttributes.empty();

  factory ReceptionContact.fromJson(Map<String, dynamic> map) =>
      ReceptionContact(
          BaseContact.fromJson(map[key.contact] as Map<String, dynamic>),
          ReceptionAttributes.fromJson(
              map[key.reception] as Map<String, dynamic>));

  @deprecated
  static ReceptionContact decode(Map<String, dynamic> map) =>
      ReceptionContact.fromJson(map);

  Map<String, dynamic> toJson() => <String, dynamic>{
        key.contact: contact.toJson(),
        key.reception: attr.toJson()
      };

  @deprecated
  ContactReference get contactReference =>
      ContactReference(contact.id, contact.name);
}

class ReceptionReference implements ObjectReference {


  const ReceptionReference(this.id, this.name);

  const ReceptionReference.none()
      : id = Reception.noId,
        name = '';

  factory ReceptionReference.fromJson(Map<String, dynamic> map) =>
      ReceptionReference(map[key.id], map[key.name]);

  @override
  final int id;
  @override
  final String name;

  bool get isEmpty => id == Reception.noId;
  bool get isNotEmpty => !isEmpty;

  @deprecated
  static ReceptionReference decode(Map<String, dynamic> map) =>
      ReceptionReference.fromJson(map);

  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{key.id: id, key.name: name};

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      other is ReceptionReference && other.id == id;
}

/// A base contact represents a contact outside the context of a reception.
class BaseContact {
  static const int noId = 0;

  int id = noId;
  String name = '';

  String type = '';
  bool enabled = true;

  /// Default empty constructor.
  BaseContact.empty();

  /// Deserializing constructor.
  BaseContact.fromJson(Map<String, Object> map)
      : id = map[key.id] as int,
        name = map[key.name] as String,
        type = map[key.contactType] as String,
        enabled = map[key.enabled] as bool;

  /// Decoding factory.
  @deprecated
  static BaseContact decode(Map<String, dynamic> map) =>
      BaseContact.fromJson(map);

  /// Serilization function.
  Map<String, dynamic> toJson() => <String, dynamic>{
        key.id: id,
        key.name: name,
        key.contactType: type,
        key.enabled: enabled
      };

  /// Determine if the [BaseContact] has no ID.
  bool get isEmpty => id == BaseContact.noId;

  /// Determine if the [BaseContact] has a valid ID.
  bool get isNotEmpty => !isEmpty;
}
