/*                  This file is part of OpenReception
                   Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.model.monitoring;

/// Model class representing a historic user state change.
class UserStateHistory {
  /// Default constructor
  const UserStateHistory(this.uid, this.timestamp, this.pause);

  /// Deserializing constructor.
  UserStateHistory.fromJson(Map<String, dynamic> map)
      : uid = map['uid'],
        timestamp = DateTime.parse(map['t']),
        pause = map['p'];

  /// The uid of the user that changed state.
  final int uid;

  /// The point in time where the change occured.
  final DateTime timestamp;

  /// The pause flag value after the state change.
  final bool pause;

  /// Serialization function
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'uid': uid, 't': timestamp.toString(), 'p': pause};

  @override
  int get hashCode => toJson().toString().hashCode;

  @override
  bool operator ==(Object other) =>
      other is UserStateHistory && other.hashCode == hashCode;
}
