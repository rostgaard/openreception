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

class ReceptionAttributeChange implements ObjectChange {
  ReceptionAttributeChange(this.changeType, this.cid, this.rid);

  ReceptionAttributeChange.fromJson(Map<String, dynamic> map)
      : changeType = changeTypeFromString(map[key.change]),
        cid = map[key.cid],
        rid = map[key.rid];

  @override
  final ChangeType changeType;

  @override
  final ObjectType objectType = ObjectType.receptionAttribute;
  final int cid;
  final int rid;

  @deprecated
  static ReceptionAttributeChange decode(Map<String, dynamic> map) =>
      new ReceptionAttributeChange(
          changeTypeFromString(map[key.change]), map[key.cid], map[key.rid]);

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.unmodifiable(<String, dynamic>{
        key.change: changeTypeToString(changeType),
        key.type: objectTypeToString(objectType),
        key.cid: cid,
        key.rid: rid
      });
}

class ReceptionAttributes {
  static const String noId = '';

  int cid = BaseContact.noId;
  int receptionId = Reception.noId;

  List<PhoneNumber> phoneNumbers = <PhoneNumber>[];
  List<MessageEndpoint> endpoints = <MessageEndpoint>[];

  List<String> backupContacts = <String>[];
  List<String> messagePrerequisites = <String>[];

  List<String> tags = <String>[];
  List<String> emailaddresses = <String>[];
  List<String> handling = <String>[];
  List<String> workhours = <String>[];
  List<String> titles = <String>[];
  List<String> responsibilities = <String>[];
  List<String> relations = <String>[];
  List<String> departments = <String>[];
  List<String> infos = <String>[];
  List<WhenWhat> whenWhats = <WhenWhat>[];

  ReceptionAttributes.fromJson(Map<String, dynamic> map)
      : phoneNumbers = new List<PhoneNumber>.from(
            map[key.phones].map((map) => new PhoneNumber.fromJson(map))),
        endpoints = new List<MessageEndpoint>.from(
            map[key.endpoints].map((map) => new MessageEndpoint.fromJson(map))),
        whenWhats = new List<WhenWhat>.from(
            (map.containsKey(key.whenWhat) ? map[key.whenWhat] : <dynamic>[])
                .map((map) => new WhenWhat.fromJson(map))),
        receptionId = map[key.rid],
        cid = map[key.cid],
        departments = stringList(map[key.departments]),
        messagePrerequisites = stringList(map[key.messagePrerequisites]),
        backupContacts = stringList(map[key.backup]),
        emailaddresses = stringList(map[key.emailaddresses]),
        handling = stringList(map[key.handling]),
        workhours = stringList(map[key.workhours]),
        tags = stringList(map[key.tags]),
        infos = stringList(map[key.infos]),
        titles = stringList(map[key.titles]),
        relations = stringList(map[key.relations]),
        responsibilities = stringList(map[key.responsibilities]);

  /// [ReceptionAttributes] empty constructor.
  ReceptionAttributes.empty();

  @deprecated
  static ReceptionAttributes decode(Map<String, dynamic> map) =>
      new ReceptionAttributes.fromJson(map);

  Map<String, dynamic> toJson() => <String, dynamic>{
        key.cid: cid,
        key.rid: receptionId,
        key.departments: departments,
        key.phones: new List<Map<String, dynamic>>.from(
            phoneNumbers.map((PhoneNumber p) => p.toJson())),
        key.endpoints: new List<Map<String, dynamic>>.from(
            endpoints.map((MessageEndpoint e) => e.toJson())),
        key.whenWhat: new List<Map<String, dynamic>>.from(
            whenWhats.map((WhenWhat w) => w.toJson())),
        key.backup: backupContacts,
        key.emailaddresses: emailaddresses,
        key.handling: handling,
        key.workhours: workhours,
        key.tags: tags,
        key.infos: infos,
        key.titles: titles,
        key.relations: relations,
        key.responsibilities: responsibilities,
        key.messagePrerequisites: messagePrerequisites
      };

  bool get isEmpty => cid == BaseContact.noId;
  bool get isNotEmpty => !isEmpty;
}
