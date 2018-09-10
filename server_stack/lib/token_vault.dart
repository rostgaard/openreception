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

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:orf/exceptions.dart';
import 'package:orf/model.dart' as model;
import 'package:ors/configuration.dart';
import 'package:path/path.dart' as path;

const String libraryName = 'AuthServer.TokenVault';
String _dateTimeToJson(DateTime time) => time.toString();

class TokenVault {
  static final Logger _log = Logger('$libraryName.TokenVault');

  Map<String, Map> _tokens = <String, Map>{};
  final Map<String, Map> _serverTokens = <String, Map>{};

  void seen(String token) {
    Map data = getToken(token);
    data['expiresAt'] =
        _dateTimeToJson(DateTime.now().add(config.authServer.tokenLifetime));
    updateToken(token, data);
  }

  Map<int, model.User> get usermap {
    Map<int, model.User> users = Map<int, model.User>();

    _tokens.values.forEach((Map map) {
      if (map.containsKey('identity')) {
        model.User user =
            model.User.fromJson(map['identity'] as Map<String, dynamic>);
        users[user.id] = user;
      }
    });

    return users;
  }

  Map getToken(String token) {
    print(_tokens);
    if (_tokens.containsKey(token)) {
      return _tokens[token];
    } else if (_serverTokens.containsKey(token)) {
      return _serverTokens[token];
    } else {
      throw NotFound('getToken. Unknown token: $token');
    }
  }

  void insertToken(String token, Map data) {
    _log.finest('Inserting  token: $data');
    if (_tokens.containsKey(token)) {
      _log.severe('Duplicate token: $token');
      throw Exception('insertToken. Token allready exists: $token');
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
      throw Exception('updateToken. Unknown token: $token');
    }
  }

  bool containsToken(String token) =>
      _tokens.containsKey(token) || _serverTokens.containsKey(token);

  void removeToken(String token) {
    if (_tokens.containsKey(token)) {
      _tokens.remove(token);
    } else {
      throw Exception('containsToken. Unknown token: $token');
    }
  }

  Iterable<String> listUserTokens() {
    return _tokens.keys;
  }

  Iterable<String> listServerTokens() {
    return _serverTokens.keys;
  }

  void loadFromDirectory(String dirPath) {
    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      List<FileSystemEntity> files =
          dir.listSync().where((fse) => fse is File).toList(growable: false);
      for (FileSystemEntity item in files) {
        try {
          String text = load(item.path);
          String token = path.basenameWithoutExtension(item.path);
          Map data = json.decode(text);
          _serverTokens[token] = data;
          _log.finest('Loaded ${_serverTokens[token]}');
        } catch (e, s) {
          _log.warning('Failed to load token $item', e, s);
        }
      }
    }
  }

  String load(String path) => File(path).readAsStringSync();
}
