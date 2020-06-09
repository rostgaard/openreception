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

/// Event that spawns whenever an agent explicitly changes its own state.
///
/// This state-change is to be interpreted as a call-handling-availability
/// state. For example, an agent may chage his/her state to `paused`.
class UserState implements Event {
  @override
  final DateTime timestamp;

  @override
  final String eventName = _Key._userState;

  /// The [model.UserStatus] that was changed. The [status] object contains
  /// information about the state and uid of agent.
  final model.UserStatus status;

  /// Create a [UserState] event object. The payload of the object is
  /// passed in the [status] parameter.
  UserState(this.status) : this.timestamp = DateTime.now();

  /// Create a [UserState] object from serialized data stored in [map].
  UserState.fromJson(Map<String, dynamic> map)
      : status = model.UserStatus()
          ..paused = map[_Key._paused]
          ..userId =
              map.containsKey(_Key._uid) ? map[_Key._uid] : map[_Key._id],
        timestamp = util.unixTimestampToDateTime(map[_Key._timestamp]);

  /// Returns an umodifiable map representation of the object, suitable for
  /// serialization.
  @override
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.unmodifiable(<String, dynamic>{
        _Key._event: eventName,
        _Key._timestamp: util.dateTimeToUnixTimestamp(timestamp),
        _Key._uid: status.userId,
        _Key._paused: status.paused
      });

  /// Returns a brief string-represented summary of the event, suitable for
  /// logging or debugging purposes.
  @override
  String toString() => '$timestamp-$eventName $status';
}
