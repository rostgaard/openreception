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

library ors.controller.state_reload;

import 'dart:async';

import 'package:ors/controller/controller-pbx.dart' as controller;
import 'package:ors/model.dart' as _model;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart';

class PhoneState {
  PhoneState(this._callList, this._peerlist, this._pbxController);

  final _model.CallList _callList;

  final _model.PeerList _peerlist;
  final controller.PBX _pbxController;

  /// Performs a total reload of state.
  Future<Response> reloadAll(Request request) async {
    _peerlist.clear();

    await Future.wait(
        [_pbxController.loadPeers(_peerlist), _pbxController.loadChannels()]);
    _callList.reloadFromChannels();
    return okJson(const {});
  }
}
