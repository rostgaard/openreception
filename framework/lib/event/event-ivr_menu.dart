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

/// Model class representing a change in a persistent [model.IvrMenu]
/// object. May be serialized and sent via a notification socket.
class IvrMenuChange implements Event {
  @override
  final DateTime timestamp;

  @override
  final String eventName = _Key._ivrMenuChange;

  /// Name of the menu that was modified.
  final String menuName;

  /// The uid of the user modifying the calendar entry.
  final int modifierUid;

  /// The modification state. Must be one of the valid [Change] values.
  final String state;

  IvrMenuChange._internal(this.menuName, this.modifierUid, this.state)
      : timestamp = DateTime.now();

  /// Create a creation event.
  factory IvrMenuChange.create(String menuName, int modifierUid) =>
      IvrMenuChange._internal(menuName, modifierUid, Change.created);

  /// Create a update event.
  factory IvrMenuChange.update(String menuName, int modifierUid) =>
      IvrMenuChange._internal(menuName, modifierUid, Change.updated);

  /// Create a deletion event.
  factory IvrMenuChange.delete(String menuName, int modifierUid) =>
      IvrMenuChange._internal(menuName, modifierUid, Change.deleted);

  /// Create a [IvrMenuChange] object from serialized data stored in [map].
  IvrMenuChange.fromJson(Map<String, dynamic> map)
      : modifierUid = map[_Key._modifierUid],
        menuName = map[_Key._menuName],
        state = map[_Key._state],
        timestamp = util.unixTimestampToDateTime(map[_Key._timestamp]);

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
        _Key._menuName: menuName,
        _Key._state: this.state
      });

  /// Returns a brief string-represented summary of the event, suitable for
  /// logging or debugging purposes.
  @override
  String toString() => '$timestamp-$eventName $state '
      'modifier:$modifierUid,menu:$menuName,';
}
