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
import 'package:orf/exceptions.dart';
import 'package:orf/model.dart' as model;
import 'package:orf/service-io.dart' as service;
import 'package:orf/storage.dart' as storage;
import 'package:ors/configuration.dart' as conf;
import 'package:ors/googleauth.dart';
import 'package:ors/response_utils.dart';
import 'package:ors/token_vault.dart';
import 'package:shelf/shelf.dart';

class Authentication {
  Authentication(this._config, this._userStore, this._vault) {
    _log.info('Preloaded tokes:' + _vault.listUserTokens().join(', '));
  }

  final Logger _log =  Logger('server.controller.authentication');

  final TokenVault _vault;
  final conf.AuthServer _config;
  final storage.User _userStore;
  final service.Client _httpClient =  service.Client();

  Future<Response> invalidateToken(Request request, final String token) async {
    if (token != null && token.isNotEmpty) {
      try {
        _vault.removeToken(token);
        return okJson(const <String, String>{});
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

  Future<Response> login(final Request request) async {
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
      Uri googleOauthRequestUrl =  Uri(
          scheme: authUrl.scheme,
          host: authUrl.host,
          port: authUrl.port,
          path: authUrl.path,
          queryParameters: googleParameters,
          fragment: authUrl.fragment);

      _log.finest('Redirecting to $googleOauthRequestUrl');

      return Response(302,
          headers: {'location:': googleOauthRequestUrl.toString()});
    } catch (error, stacktrace) {
      _log.severe(error, stacktrace);
      return  Response.internalServerError(
          body: 'Failed log in error:$error');
    }
  }

  Future<Response> oauthCallback(Request request) async {
    final String stateString = request.url.queryParameters.containsKey('state')
        ? request.url.queryParameters['state']
        : '';

    if (stateString.isEmpty) {
      return  Response.internalServerError(
          body: 'State parameter is missing "${request.url}"');
    }

    _log.finest('stateString:$stateString');

    final Uri returnUrl = Uri.parse(stateString);
    final Map postBody = <String, dynamic>{
      "grant_type": "authorization_code",
      "code": request.url.queryParameters['code'],
      "redirect_uri": _config.redirectUri.toString(),
      "client_id": _config.clientId,
      "client_secret": _config.clientSecret
    };

    _log.finest('Sending request to google. "$tokenEndpoint" body "$postBody"');

    //Now we have the "code" which will be exchanged to a token.
    Map jsonBody;
    try {
      final String response = await _httpClient.postForm(
          tokenEndpoint, postBody as Map<String, dynamic>);
      jsonBody = json.decode(response);
    } catch (error) {
      return  Response.internalServerError(
          body: 'authenticationserver.router.oauthCallback uri ${request.url} '
              'error: "$error"');
    }

    if (jsonBody.containsKey('error')) {
      return  Response.internalServerError(
          body: 'authenticationserver.router.oauthCallback() '
              'Authentication failed. "$json"');
    } else {
      ///FIXME: Change to use format from framework AND update the dummy tokens.
      jsonBody['expiresAt'] =
           DateTime.now().add(_config.tokenLifetime).toString();

      Map userData;

      try {
        userData = await getUserInfo(jsonBody['access_token']);
      } catch (error) {
        _log.severe('Could not retrieve user info', error);
        return  Response.forbidden(json.encode({'status': 'Forbidden'}));
      }

      if (userData == null || userData.isEmpty) {
        _log.finest('authenticationserver.router.oauthCallback() '
            'token:"${jsonBody['access_token']}" userdata:"$userData"');

        return  Response.forbidden(json.encode({'status': 'Forbidden'}));
      } else {
        jsonBody['identity'] = userData;

        String cacheObject = json.encode(json);
        String hash = sha256Token(cacheObject);

        try {
          _vault.insertToken(hash, jsonBody);
          Map<String, String> queryParameters = {'settoken': hash};

          return  Response(302, headers: {
            'location':  Uri(
                    scheme: returnUrl.scheme,
                    userInfo: returnUrl.userInfo,
                    host: returnUrl.host,
                    port: returnUrl.port,
                    path: returnUrl.path,
                    queryParameters: queryParameters)
                .toString()
          });
        } catch (error, stackTrace) {
          _log.severe(error, stackTrace);

          return  Response.internalServerError(
              body: 'authenticationserver.router.oauthCallback '
                  'uri ${request.url} error: "$error" data: "$json"');
        }
      }
    }
  }

  /// Asks google for the user data, for the user bound to the [accessToken].
  Future<Map> getUserInfo(String accessToken) async {
    Uri url = Uri.parse('https://www.googleapis.com/oauth2/'
        'v1/userinfo?alt=json&access_token=$accessToken');

    final Map googleProfile = json.decode(await  service.Client().get(url));

    final model.User user =
        await _userStore.getByIdentity(googleProfile['email']);
    Map agent = user.toJson();
    agent['remote_attributes'] = googleProfile;

    return agent;
  }

  Future<Response> refresher(Request request, final String token) async {
    try {
      Map content = _vault.getToken(token);

      String refreshToken = content['refresh_token'];

      Uri url = Uri.parse('https://www.googleapis.com/oauth2/v3/token');
      Map body = <String, String>{
        'refresh_token': refreshToken,
        'client_id': _config.clientId,
        'client_secret': _config.clientSecret,
        'grant_type': 'refresh_token'
      };

      final String response = await _httpClient.post(url, json.encode(body));

      return  ok(
          'BODY \n ==== \n${json.encode(body)} \n\n RESPONSE '
          '\n ======== \n $response');
    } catch (error, stackTrace) {
      _log.severe(error, stackTrace);

      return  serverError( '$error');
    }
  }

  Future<Response> userportraits(Request request) async {
    final Map<String, String> picturemap = {};

    _vault.usermap.values.forEach((model.User user) {
      picturemap[user.address] = user.portrait;
    });
    return  okJson(picturemap);
  }

  Future<Response> userinfo(final Request request, final String token) async {
    try {
      if (token == _config.serverToken) {
        return okJson(model.User.empty()..id = model.User.noId);
      }

      Map content = _vault.getToken(token);
      try {
        _vault.seen(token);
      } catch (error, stacktrace) {
        _log.severe(error, stacktrace);
      }

      if (!content.containsKey('identity')) {
        return serverError( 'Parse error in stored map');
      }

      return okJson(content['identity']);
    } on NotFound {
      return  notFoundJson({'Status': 'Token $token not found'});
    } catch (error, stacktrace) {
      _log.severe(error, stacktrace);

      return  serverError(json.encode({'Status': 'Not found'}));
    }
  }

  Future<Response> validateToken(Request request, final String token) async {
    if (token.isNotEmpty) {
      if (token == _config.serverToken) {
        return okJson(const <String, String>{});
      }

      if (_vault.containsToken(token)) {
        try {
          _vault.seen(token);
        } catch (error, stacktrace) {
          _log.severe(error, stacktrace);
        }

        return  okJson(const <String, String>{});
      } else {
        return  okJson(const <String, String>{});
      }
    }

    return clientError('Invalid or missing token passed.');
  }
}
