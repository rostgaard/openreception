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

/// Event that is meant to be spawned every time a call is assigned to a user.
///
/// *Currently not in use*. Meant for a future  simplification of the
/// event system.
class CallAssign extends CallEvent {
  /// Default constructor. Subtypes the general [CallEvent] class.
  ///
  /// Takes the  [model.Call] being assigned and the [uid] of the user it being
  /// assigned to as arguments.
  CallAssign(model.Call call, this.uid) : super(call);

  /// Create a [CallAssign] object from serialized data stored in [map].
  CallAssign.fromJson(Map<String, dynamic> map)
      : uid = map[_Key._modifierUid] as int,
        super.fromJson(map);

  /// Returns an unmodifiable map representation of the object, suitable for
  /// serialization.
  @override
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.unmodifiable(<String, dynamic>{
        _Key._event: eventName,
        _Key._timestamp: util.dateTimeToUnixTimestamp(timestamp),
        _Key._modifierUid: uid,
        _Key._call: call.toJson()
      });
  @override
  final String eventName = _Key._callAssign;

  /// The id of user object of the agent that the call was assigned to.
  final int uid;

  /// Returns a brief string-represented summary of the event, suitable for
  /// logging or debugging purposes.
  @override
  String toString() => '$timestamp-$eventName $uid';
}
