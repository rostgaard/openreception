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

import 'dart:async';
import 'dart:convert';

import 'package:orf/event.dart' as event;
import 'package:orf/model.dart' as model;
import 'package:ors/model.dart' as model;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart';

class UserState {
  UserState(this._userStateList, this._userUIState, this._userFocusState);

  final model.UserStatusList _userStateList;
  final Map<int, event.WidgetSelect> _userUIState;
  final Map<int, event.FocusChange> _userFocusState;

  /// Response handler for UI states of all users.
  Future<Response> uiStates(Request request) async =>
      okJson(_userUIState.values.toList(growable: false));

  Future<Response> uiState(Request request, String uidParam) async {
    final int uid = int.parse(uidParam);

    if (!_userUIState.containsKey(uid)) {
      return notFound('No UIState for uid:$uid');
    }

    return okJson(_userUIState[uid]);
  }

  Future<Response> list(Request request) async =>
      okJson(json.encode(_userStateList));

  Future<Response> get(Request request, String uidParam) async {
    final int uid = int.parse(uidParam);

    if (!_userStateList.has(uid)) {
      return notFoundJson(const {});
    }

    return Response.ok(json.encode(_userStateList.get(uid)));
  }

  Future<Response> set(Request request, String uidParam) async {
    final int uid = int.parse(uidParam);

    try {
      final map = json.decode(await request.readAsString());
      final user = model.UserStatus.fromJson(map);

      if (user.paused) {
        return Response.ok(json.encode(_userStateList.pause(uid)));
      } else {
        return Response.ok(json.encode(_userStateList.ready(uid)));
      }
    } on FormatException catch (error) {
      Map response = <String, String>{
        'status': 'bad request',
        'description': 'passed object argument '
            'is too long, missing or invalid',
        'error': error.toString()
      };
      return clientErrorJson(response);
    }
  }
}
