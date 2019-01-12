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

library orf.service.io;

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:orf/exceptions.dart';
import 'package:orf/service.dart' as service;

part 'service/io/service-io-client.dart';
part 'service/io/service-io-websocket_client.dart';

Future<String> _handleResponse(
    io.HttpClientResponse response, String method, Uri resource) async {
  final String body = await extractContent(response);
  service.WebService.checkResponse(response.statusCode, method, resource, body);
  return body;
}

//const JsonCodec _json = const JsonCodec();
const Utf8Codec _utf8 = const Utf8Codec();
Future<String> extractContent(Stream<List<int>> request) {
  Completer<String> completer = new Completer<String>();
  List<int> completeRawContent = new List<int>();

  request.listen(completeRawContent.addAll,
      onError: (dynamic error) => completer.completeError(error),
      onDone: () {
        try {
          String content = _utf8.decode(completeRawContent);
          completer.complete(content);
        } catch (error) {
          completer.completeError(error);
        }
      },
      cancelOnError: true);

  return completer.future;
}
