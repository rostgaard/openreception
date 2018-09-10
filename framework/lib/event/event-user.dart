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

/// Model class representing a change in a persistent [model.User]
/// object. May be serialized and sent via a notification socket.
class UserChange implements Event {

  /// Create a creation event.
  factory UserChange.create(int userID, int changedBy) =>
      UserChange._internal(userID, Change.created, changedBy);

  /// Create a update event.
  factory UserChange.update(int userID, int changedBy) =>
      UserChange._internal(userID, Change.updated, changedBy);

  /// Create a deletion event.
  factory UserChange.delete(int userID, int changedBy) =>
      UserChange._internal(userID, Change.deleted, changedBy);

  /// Create a [UserChange] object from serialized data stored in [map].
  UserChange.fromJson(Map<String, dynamic> map)
      : uid = map[_Key._userChange][_Key._modifierUid],
        state = map[_Key._userChange][_Key._state],
        modifierUid = map[_Key._userChange][_Key._changedBy],
        timestamp = util.unixTimestampToDateTime(map[_Key._timestamp]);

  UserChange._internal(this.uid, this.state, this.modifierUid)
      : timestamp = DateTime.now();

  @override
  final DateTime timestamp;

  @override
  final String eventName = _Key._userChange;

  /// The user ID of the user that was modified.
  final int uid;

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
        _Key._userChange: <String, dynamic>{
          _Key._modifierUid: uid,
          _Key._state: state,
          _Key._changedBy: modifierUid
        }
      });

  /// Returns a brief string-represented summary of the event, suitable for
  /// logging or debugging purposes.
  @override
  String toString() => '$timestamp-$eventName $state '
      'modifier:$modifierUid, '
      'uid:$uid';
}
