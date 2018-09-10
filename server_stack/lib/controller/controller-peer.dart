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

library ors.controller.peer;

import 'dart:async';

import 'package:orf/exceptions.dart';
import 'package:orf/model.dart' as model;
import 'package:ors/model.dart' as _model;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart';

class Peer {
  Peer(this._peerlist);

  final _model.PeerList _peerlist;

  Future<Response> list(Request request) => okJson(_peerlist);

  Future<Response> get(Request request, final String peerName) async {
    model.Peer peer;

    try {
      peer = _peerlist.get(peerName);
    } on NotFound {
      return new Response.notFound('No peer with name $peerName');
    }

    return okJson(peer);
  }
}
