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

part of ors.model;

class UserStatusList {
  Stream<event.UserState> get onChange => _change.stream;
  final Bus<event.UserState> _change = Bus<event.UserState>();

  List toJson() => _userStatus.values.toList(growable: false);

  Logger _log = Logger('$_libraryName.UserStatusList');

  /// Internal lookup map.
  Map<int, model.UserStatus> _userStatus = {};

  bool has(int userID) => this._userStatus.containsKey(userID);

  model.UserStatus pause(int uid) {
    model.UserStatus status = model.UserStatus()
      ..paused = true
      ..userId = uid;
    _userStatus[uid] = status;

    _change.fire(event.UserState(_userStatus[uid]));
    return status;
  }

  model.UserStatus ready(int uid) {
    model.UserStatus status = model.UserStatus()
      ..paused = false
      ..userId = uid;
    _userStatus[uid] = status;

    _change.fire(event.UserState(_userStatus[uid]));
    return status;
  }

  model.UserStatus get(int uid) {
    if (_userStatus.containsKey(uid)) {
      return _userStatus[uid];
    } else {
      throw NotFound();
    }
  }
}
