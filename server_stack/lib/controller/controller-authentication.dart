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

library ors.controller.authentication;

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:orf/model.dart' as model;
import 'package:orf/service-io.dart' as service;
import 'package:orf/storage.dart' as storage;
import 'package:orf/configuration.dart' as conf;
import 'package:orf/exceptions.dart';
import 'package:ors/googleauth.dart';
import 'package:ors/response_utils.dart';
import 'package:ors/token_vault.dart';
import 'package:ors/token_watcher.dart' as watcher;
import 'package:shelf/shelf.dart' as shelf show Request, Response;
import 'package:shelf_route/shelf_route.dart' as shelf_route;

class Authentication {
  final Logger _log = new Logger('server.controller.authentication');

  final TokenVault _vault;
  final conf.Configuration _config;
  final storage.User _userStore;

  final service.Client _httpClient = new service.Client();

  Authentication(this._config, this._userStore, this._vault);

  String get redirectUri =>
      'http://${_config.externalHostname}:${_config.authServer.port}'
      '/token/oauth2callback';

  /**
   *
   */
  shelf.Response invalidateToken(shelf.Request request) {
    final String token = shelf_route.getPathParameter(request, 'token');

    if (token != null && token.isNotEmpty) {
      try {
        _vault.removeToken(token);
        return okJson(const {});
      } catch (error, stacktrace) {
        _log.severe(error, stacktrace);
        return serverError('invalidateToken: '
            'Failed to remove token "$token" $error');
      }
    } else {
      return serverError('invalidateToken: '
          'No token parameter was specified');
    }
  }

  /**
   *
   */
  shelf.Response login(shelf.Request request) {
    final String returnUrlString =
        request.url.queryParameters.containsKey('returnurl')
            ? request.url.queryParameters['returnurl']
            : '';

    _log.finest('returnUrlString:$returnUrlString');

    try {
      //Because the library does not allow to set custom query parameters
      Map<String, String> googleParameters = {
        'access_type': 'online',
        'approval_prompt': 'auto',
        'state': _config.redirectUri.toString()
      };

      if (returnUrlString.isNotEmpty) {
        //validating the url by parsing it.
        Uri returnUrl = Uri.parse(returnUrlString);
        googleParameters['state'] = returnUrl.toString();
      }

      Uri authUrl = googleAuthUrl(
          _config.clientId, _config.clientSecret, _config.redirectUri);

      googleParameters.addAll(authUrl.queryParameters);
      Uri googleOauthRequestUrl = new Uri(
          scheme: authUrl.scheme,
          host: authUrl.host,
          port: authUrl.port,
          path: authUrl.path,
          queryParameters: googleParameters,
          fragment: authUrl.fragment);

      _log.finest('Redirecting to $googleOauthRequestUrl');

      return new shelf.Response.found(googleOauthRequestUrl);
    } catch (error, stacktrace) {
      _log.severe(error, stacktrace);
      return new shelf.Response.internalServerError(
          body: 'Failed log in error:$error');
    }
  }

  Future<shelf.Response> oauthCallback(shelf.Request request) async {
    final String stateString = request.url.queryParameters.containsKey('state')
        ? request.url.queryParameters['state']
        : '';

    if (stateString.isEmpty) {
      return new shelf.Response.internalServerError(
          body: 'State parameter is missing "${request.url}"');
    }

    _log.finest('stateString:$stateString');

    final Uri returnUrl = Uri.parse(stateString);
    final Map postBody = {
      "grant_type": "authorization_code",
      "code": request.url.queryParameters['code'],
      "redirect_uri": _config.redirectUri.toString(),
      "client_id": _config.clientId,
      "client_secret": _config.clientSecret
    };

    _log.finest('Sending request to google. "$tokenEndpoint" body "$postBody"');

    //Now we have the "code" which will be exchanged to a token.
    Map json;
    try {
      final String response = await _httpClient.postForm(
          tokenEndpoint, postBody as Map<String, dynamic>);
      json = JSON.decode(response);
    } catch (error) {
      return new shelf.Response.internalServerError(
          body: 'authenticationserver.router.oauthCallback uri ${request.url} '
              'error: "$error"');
    }

    if (json.containsKey('error')) {
      return new shelf.Response.internalServerError(
          body: 'authenticationserver.router.oauthCallback() '
              'Authentication failed. "$json"');
    } else {
      ///FIXME: Change to use format from framework AND update the dummy tokens.
      json['expiresAt'] =
          new DateTime.now().add(_config.tokenLifetime).toString();

      Map userData;

      try {
        userData = await getUserInfo(json['access_token']);
      } catch (error) {
        _log.severe('Could not retrieve user info', error);
        return new shelf.Response.forbidden(
            JSON.encode(const {'status': 'Forbidden'}));
      }

      if (userData == null || userData.isEmpty) {
        _log.finest('authenticationserver.router.oauthCallback() '
            'token:"${json['access_token']}" userdata:"$userData"');

        return new shelf.Response.forbidden(
            JSON.encode(const {'status': 'Forbidden'}));
      } else {
        json['identity'] = userData;

        String cacheObject = JSON.encode(json);
        String hash = sha256Token(cacheObject);

        try {
          _vault.insertToken(hash, json);
          Map<String, String> queryParameters = {'settoken': hash};

          return new shelf.Response.found(new Uri(
              scheme: returnUrl.scheme,
              userInfo: returnUrl.userInfo,
              host: returnUrl.host,
              port: returnUrl.port,
              path: returnUrl.path,
              queryParameters: queryParameters));
        } catch (error, stackTrace) {
          _log.severe(error, stackTrace);

          return new shelf.Response.internalServerError(
              body: 'authenticationserver.router.oauthCallback '
                  'uri ${request.url} error: "$error" data: "$json"');
        }
      }
    }
  }

  /**
   * Asks google for the user data, for the user bound to the [accessToken].
   */
  Future<Map> getUserInfo(String accessToken) async {
    Uri url = Uri.parse('https://www.googleapis.com/oauth2/'
        'v1/userinfo?alt=json&access_token=$accessToken');

    final Map googleProfile =
        await new service.Client().get(url).then(JSON.decode);

    final model.User user =
        await _userStore.getByIdentity(googleProfile['email']);
    Map agent = user.toJson();
    agent['remote_attributes'] = googleProfile;

    return agent;
  }

  Future<shelf.Response> refresher(shelf.Request request) async {
    final String token =
        shelf_route.getPathParameters(request).containsKey('token')
            ? shelf_route.getPathParameter(request, 'token')
            : '';

    try {
      Map content = _vault.getToken(token);

      String refreshToken = content['refresh_token'];

      Uri url = Uri.parse('https://www.googleapis.com/oauth2/v3/token');
      Map body = {
        'refresh_token': refreshToken,
        'client_id': _config.clientId,
        'client_secret': _config.clientSecret,
        'grant_type': 'refresh_token'
      };

      final String response = await _httpClient.post(url, JSON.encode(body));

      return new shelf.Response.ok(
          'BODY \n ==== \n${JSON.encode(body)} \n\n RESPONSE '
          '\n ======== \n $response');
    } catch (error, stackTrace) {
      _log.severe(error, stackTrace);

      return new shelf.Response.internalServerError(body: '$error');
    }
  }

  shelf.Response userportraits(shelf.Request request) {
    final Map<String, String> picturemap = {};

    _vault.usermap.values.forEach((model.User user) {
      picturemap[user.address] = user.portrait;
    });
    return new shelf.Response.ok(JSON.encode(picturemap));
  }

  shelf.Response userinfo(shelf.Request request) {
    final String token =
        shelf_route.getPathParameters(request).containsKey('token')
            ? shelf_route.getPathParameter(request, 'token')
            : '';

    try {
      if (token == _config.serverToken) {
        return new shelf.Response.ok(
            JSON.encode(new model.User.empty()..id = model.User.noId));
      }

      Map content = _vault.getToken(token);
      try {
        watcher.seen(token);
      } catch (error, stacktrace) {
        _log.severe(error, stacktrace);
      }

      if (!content.containsKey('identity')) {
        return new shelf.Response.internalServerError(
            body: 'Parse error in stored map');
      }

      return new shelf.Response.ok(JSON.encode(content['identity']));
    } on NotFound {
      return new shelf.Response.notFound(
          JSON.encode({'Status': 'Token $token not found'}));
    } catch (error, stacktrace) {
      _log.severe(error, stacktrace);

      return new shelf.Response.internalServerError(
          body: JSON.encode({'Status': 'Not found'}));
    }
  }

  shelf.Response validateToken(shelf.Request request) {
    final String token =
        shelf_route.getPathParameters(request).containsKey('token')
            ? shelf_route.getPathParameter(request, 'token')
            : '';

    if (token.isNotEmpty) {
      if (token == _config.serverToken) {
        return new shelf.Response.ok(JSON.encode(const {}));
      }

      if (_vault.containsToken(token)) {
        try {
          watcher.seen(token);
        } catch (error, stacktrace) {
          _log.severe(error, stacktrace);
        }

        return new shelf.Response.ok(JSON.encode(const {}));
      } else {
        return new shelf.Response.notFound(JSON.encode(const {}));
      }
    }

    return new shelf.Response(400, body: 'Invalid or missing token passed.');
  }
}
