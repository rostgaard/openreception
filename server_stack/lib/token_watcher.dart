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

library ors.authentication.token_watcher;

import 'dart:async';

import 'package:logging/logging.dart';

import 'token_vault.dart';

DateTime _jsonToDateTime(String timeString) => DateTime.parse(timeString);

class TokenWatcher {
  TokenWatcher(this._vault) {
    _setup();
  }

  final Logger _log = Logger('AuthServer.tokenWatch');

  final TokenVault _vault;

  void _setup() {
    final Duration tickDuration = Duration(seconds: 10);
    Timer.periodic(tickDuration, _timerTick);
    _log.info('Periodic timer started');
  }

  void _timerTick(Timer timer) {
    Iterable<String> tokens = _vault.listUserTokens().toList(); // Copy list
    for (String token in tokens) {
      Map data = _vault.getToken(token);
      DateTime expiresAt = _jsonToDateTime(data['expiresAt']);

      int now = DateTime.now().millisecondsSinceEpoch;
      if (now > expiresAt.millisecondsSinceEpoch) {
        _log.info('This token $token expired $expiresAt - removing it');
        _vault.removeToken(token);
      }
    }
  }
}
