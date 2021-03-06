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

/// 'Enum' type representing the different states of a user, in the
/// context of being able to pickup calls.
///
/// As an example; a user in the the 'idle' state may pick up a call, while
/// a user that is 'paused' may not.
///
/// UserState does not imply connectivity, so other states such
/// as [PeerState] or [ClientConnection] should always also be checked
/// before detemining wheter a user is connectable or not.
abstract class UserState {
  static const String ready = 'ready';
  static const String paused = 'paused';
}

class UserStatus {
  final bool paused;
  final int userId;

  const UserStatus(this.paused, this.userId);

  UserStatus.fromJson(Map<String, dynamic> map)
      : userId = map[key.uid],
        paused = map[key.paused];

  @deprecated
  static UserStatus decode(Map<String, dynamic> map) =>
      new UserStatus.fromJson(map);

  Map<String, dynamic> toJson() =>
      <String, dynamic>{key.uid: userId, key.paused: paused};
}
