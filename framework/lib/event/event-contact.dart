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

part of orf.event;

/// Model class representing a change in a persistent [model.BaseContact]
/// object. May be serialized and sent via a notification socket.
class ContactChange implements Event {


  /// Create a creation event.
  ContactChange.create(this.cid, [int uid])
      : timestamp = DateTime.now(),
        state = Change.created,
        modifierUid = uid != null ? uid : model.User.noId;

  /// Create a [ContactChange] object from serialized data stored in [map].
  ContactChange.fromJson(Map<String, dynamic> map)
      : cid = map[_Key._calendarChange][_Key._cid] as int,
        modifierUid = map[_Key._calendarChange][_Key._modifierUid] as int,
        state = map[_Key._calendarChange][_Key._state] as String,
        timestamp = util.unixTimestampToDateTime(map[_Key._timestamp] as int);

  /// Create a update event.
  ContactChange.update(this.cid, [int uid])
      : timestamp = DateTime.now(),
        state = Change.updated,
        modifierUid = uid != null ? uid : model.User.noId;

  /// Create a deletion event.
  ContactChange.delete(this.cid, [int uid])
      : timestamp = DateTime.now(),
        state = Change.deleted,
        modifierUid = uid != null ? uid : model.User.noId;

  @override
  final DateTime timestamp;

  @override
  final String eventName = _Key._contactChange;

  /// The contact ID of the contact that was modified.
  final int cid;

  /// The uid of the user modifying the calendar entry.
  final int modifierUid;

  /// The modification state. Must be one of the valid [Change] values.
  final String state;
  /// Determines if the object signifies a creation.
  bool get isCreate => state == Change.created;

  /// Determines if the object signifies an update.
  bool get isUpdate => state == Change.updated;

  /// Determines if the object signifies a deletion.
  bool get isDelete => state == Change.deleted;

  /// Returns an umodifiable map representation of the object, suitable for
  /// serialization.
  @override
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.unmodifiable(<String, dynamic>{
        _Key._event: eventName,
        _Key._timestamp: util.dateTimeToUnixTimestamp(timestamp),
        _Key._modifierUid: modifierUid,
        _Key._calendarChange: <String, dynamic>{
          _Key._cid: cid,
          _Key._state: state,
          _Key._modifierUid: modifierUid
        }
      });

  /// Returns a brief string-represented summary of the event, suitable for
  /// logging or debugging purposes.
  @override
  String toString() => '$timestamp-$eventName $state '
      'modifier:$modifierUid,cid:$cid,';
}
