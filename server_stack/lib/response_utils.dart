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

library ors.router.response_utils_shelf;

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

const Map<String, String> corsHeaders = const {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, PUT, POST, DELETE'
};

/**
 *
 */
Future<shelf.Response> okJson(dynamic body) async =>
    shelf.Response.ok(json.encode(body),
        headers: {'Content-Type': 'application/json'});

/**
 *
 */
shelf.Response ok(dynamic body) => shelf.Response.ok(body);

/**
 *
 */
shelf.Response notFoundJson(dynamic body) =>
    shelf.Response.notFound(json.encode(body));

/**
     *
     */
shelf.Response notFound(dynamic body) => shelf.Response.notFound(body);

/**
 *
 */
shelf.Response clientError(String reason) => shelf.Response(400, body: reason);

/**
 *
 */
shelf.Response clientErrorJson(dynamic reason) =>
    shelf.Response(400, body: json.encode(reason));

/**
 *
 */
shelf.Response serverError(String reason) =>
    shelf.Response.internalServerError(body: reason);

shelf.Response authServerDown() =>
    shelf.Response(502, body: 'Authentication server is not reachable');

String tokenFrom(shelf.Request request) => request.url.queryParameters['token'];
