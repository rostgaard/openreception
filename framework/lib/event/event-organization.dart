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

part of openreception.event;

class OrganizationChange implements Event {
  final DateTime timestamp;

  String get eventName => Key.organizationChange;

  final int oid;
  final int modifierUid;
  final String state;

  bool get created => state == Change.created;
  bool get updated => state == Change.updated;
  bool get deleted => state == Change.deleted;
  /**
   *
   */
  OrganizationChange.create(this.oid, this.modifierUid)
      : this.state = Change.created,
        this.timestamp = new DateTime.now();

  /**
   *
   */
  OrganizationChange.update(this.oid, this.modifierUid)
      : this.state = Change.updated,
        this.timestamp = new DateTime.now();

  /**
   *
   */
  OrganizationChange.delete(this.oid, this.modifierUid)
      : this.state = Change.deleted,
        this.timestamp = new DateTime.now();

  Map toJson() => this.asMap;
  String toString() => this.asMap.toString();

  Map get asMap {
    Map template = EventTemplate._rootElement(this);

    Map body = {
      Key.organizationID: this.oid,
      Key.state: this.state,
      Key.modifierUid: modifierUid
    };

    template[this.eventName] = body;

    return template;
  }

  OrganizationChange.fromMap(Map map)
      : this.oid = map[Key.organizationChange][Key.organizationID],
        this.state = map[Key.organizationChange][Key.state],
        this.modifierUid = map[Key.organizationChange][Key.modifierUid],
        this.timestamp = Util.unixTimestampToDateTime(map[Key.timestamp]);
}