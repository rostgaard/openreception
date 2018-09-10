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

/// Model class representing a change in a persistent [model.Reception]
/// object. May be serialized and sent via a notification socket.
class ReceptionChange implements Event {
  @override
  final DateTime timestamp;

  @override
  final String eventName = _Key._receptionChange;

  /// The reception ID of the reception that was modified.
  final int rid;

  /// The uid of the user modifying the calendar entry.
  int modifierUid;

  /// The modification state. Must be one of the valid [Change] values.
  final String state;

  /// Create a creation event.
  ReceptionChange.create(this.rid, this.modifierUid)
      : this.state = Change.created,
        this.timestamp = DateTime.now();

  /// Create a update event.
  ReceptionChange.update(this.rid, this.modifierUid)
      : this.state = Change.updated,
        this.timestamp = DateTime.now();

  /// Create a deletion event.
  ReceptionChange.delete(this.rid, this.modifierUid)
      : this.state = Change.deleted,
        this.timestamp = DateTime.now();

  /// Create a [ReceptionChange] object from serialized data stored in [map].
  ReceptionChange.fromJson(Map<String, dynamic> map)
      : rid = map[_Key._receptionChange][_Key._rid],
        state = map[_Key._receptionChange][_Key._state],
        modifierUid = map[_Key._receptionChange][_Key._modifierUid],
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
        _Key._receptionChange: <String, dynamic>{
          _Key._rid: rid,
          _Key._state: state,
          _Key._modifierUid: modifierUid
        }
      });

  /// Returns a brief string-represented summary of the event, suitable for
  /// logging or debugging purposes.
  @override
  String toString() => '$timestamp-$eventName $state '
      'modifier:$modifierUid, '
      'rid:$rid';
}
