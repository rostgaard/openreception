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

library ors.authentication.token_vault;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:orf/exceptions.dart';
import 'package:orf/model.dart' as model;
import 'package:path/path.dart' as path;

final TokenVault vault = new TokenVault();
const _json = const JsonCodec();

const String libraryName = 'AuthServer.TokenVault';

class TokenVault {
  static final Logger log = new Logger('$libraryName.TokenVault');

  Map<String, Map> _tokens = new Map<String, Map>();
  Map<String, Map> _serverTokens = new Map<String, Map>();

  Map<int, model.User> get usermap {
    Map<int, model.User> users = new Map<int, model.User>();

    _tokens.values.forEach((Map map) {
      if (map.containsKey('identity')) {
        model.User user =
            new model.User.fromJson(map['identity'] as Map<String, dynamic>);
        users[user.id] = user;
      }
    });

    return users;
  }

  Map getToken(String token) {
    if (_tokens.containsKey(token)) {
      return _tokens[token];
    } else if (_serverTokens.containsKey(token)) {
      return _serverTokens[token];
    } else {
      throw new NotFound('getToken. Unknown token: $token');
    }
  }

  void insertToken(String token, Map data) {
    log.finest('Inserting new token: $data');
    if (_tokens.containsKey(token)) {
      log.severe('Duplicate token: $token');
      throw new Exception('insertToken. Token allready exists: $token');
    } else {
      _tokens[token] = data;
    }
  }

  void updateToken(String token, Map data) {
    if (_tokens.containsKey(token)) {
      _tokens[token] = data;
    } else if (_serverTokens.containsKey(token)) {
      return;
    } else {
      throw new Exception('updateToken. Unknown token: $token');
    }
  }

  bool containsToken(String token) =>
      _tokens.containsKey(token) || _serverTokens.containsKey(token);

  void removeToken(String token) {
    if (_tokens.containsKey(token)) {
      _tokens.remove(token);
    } else {
      throw new Exception('containsToken. Unknown token: $token');
    }
  }

  Iterable<String> listUserTokens() {
    return _tokens.keys;
  }

  Future loadFromDirectory(String dirPath) async {
    final Directory dir = new Directory(dirPath);
    if (dir.existsSync()) {
      List<FileSystemEntity> files =
          dir.listSync().where((fse) => fse is File).toList(growable: false);
      files.forEach((FileSystemEntity item) {
        try {
          String text = load(item.path);
          String token = path.basenameWithoutExtension(item.path);
          Map data = _json.decode(text);
          _serverTokens[token] = data;
          log.finest('Loaded ${_serverTokens[token]}');
        } catch (e, s) {
          log.warning('Failed to load token $item', e, s);
        }
      });
    }
  }

  String load(String path) => new File(path).readAsStringSync();
}
