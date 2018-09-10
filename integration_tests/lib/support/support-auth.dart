library ort.support.auth;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:orf/model.dart' as model;

const String _namespace = 'test.support.auth';

class AuthTokenDir {
  final Directory dir;
  Set<AuthToken> tokens = Set<AuthToken>();
  final Logger _log = Logger('$_namespace.AuthTokenDir');

  AuthTokenDir(this.dir, {Iterable<AuthToken> intialTokens: const []}) {
    tokens.addAll(intialTokens);
  }

  Future writeTokens() async {
    await Future.wait((tokens.map((token) async {
      final String tokenPath = '${dir.path}/${token.tokenName}.json';
      final File file = File(tokenPath);
      if (!file.existsSync()) {
        _log.finest('Writing token to file ${tokenPath}');
        await file.writeAsString(json.encode(token.toJson()));
      }
      return file;
    })));
    _log.finest('Writing ${tokens.length} to directory ${dir.path}');
  }
}

class AuthToken {
  final model.User user;

  AuthToken(this.user);

  String get tokenName => user.id.toString();

  int get hashCode => tokenName.hashCode;

  Map toJson() => {
        "access_token": "none",
        "token_type": "Bearer",
        "expires_in": 3600,
        "id_token": "none",
        "expiresAt": "2100-12-31 00:00:00.000",
        "identity": user.toJson()
      };

  String toString() => tokenName;
}
