/*                  This file is part of OpenReception
                   Copyright (C) 2016-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

library ors.controller.user_state;

import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart' as shelf_route;

import 'package:ors/response_utils.dart';

import 'package:orf/model.dart' as model;
import 'package:ors/model.dart' as model;
import 'package:orf/event.dart' as event;

const _json = const JsonCodec();

class UserState {
  final model.UserStatusList _userStateList;
  final Map<int, event.WidgetSelect> _userUIState;
  final Map<int, event.FocusChange> _userFocusState;

  UserState(this._userStateList, this._userUIState, this._userFocusState);

  /**
   *
   */
  shelf.Response uiStates(shelf.Request request) {
    return new shelf.Response.ok(
        _json.encode(_userUIState.values.toList(growable: false)));
  }

  /**
   *
   */
  shelf.Response uiState(shelf.Request request) {
    final int uid = int.parse(shelf_route.getPathParameter(request, 'uid'));

    if (!_userUIState.containsKey(uid)) {
      return notFound('No UIState for uid:$uid');
    }

    return new shelf.Response.ok(_json.encode(_userUIState[uid]));
  }

  shelf.Response list(shelf.Request request) {
    return new shelf.Response.ok(_json.encode(_userStateList));
  }

  shelf.Response get(shelf.Request request) {
    final int userID = int.parse(shelf_route.getPathParameter(request, 'uid'));

    if (!_userStateList.has(userID)) {
      return new shelf.Response.notFound('{}');
    }

    return new shelf.Response.ok(_json.encode(_userStateList.get(userID)));
  }

  shelf.Response set(shelf.Request request) {
    final int userID = int.parse(shelf_route.getPathParameter(request, 'uid'));
    final String newState = shelf_route.getPathParameter(request, 'state');

    if (newState == model.UserState.paused) {
      return new shelf.Response.ok(_json.encode(_userStateList.pause(userID)));
    } else if (newState == model.UserState.ready) {
      return new shelf.Response.ok(_json.encode(_userStateList.ready(userID)));
    } else {
      return serverError('Unknown state $newState');
    }
  }
}
