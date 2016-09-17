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

library orf.test.log_setup;

import 'dart:io';

import 'package:logging/logging.dart';
//import '../lib/service.dart'  as Service;

typedef void LogHandler(LogRecord r);

void setupLogging([LogHandler logFunction]) {
  if (logFunction == null) {
    logFunction = (LogRecord record) {
      final String error = '${record.error != null
          ? ' - ${record.error}'
          : ''}'
          '${record.stackTrace != null
            ? ' - ${record.stackTrace}'
            : ''}';

      if (record.level.value > Level.INFO.value) {
        stderr.writeln('${record.time} - $record$error');
      } else {
        stdout.writeln('${record.time} - $record$error');
      }
    };
  }

  final Map<String, String> env = Platform.environment;

  if (env.containsKey('LOGLEVEL')) {
    switch (env['LOGLEVEL']) {
      case 'ALL':
        Logger.root.level = Level.ALL;
        break;

      case 'FINEST':
        Logger.root.level = Level.FINEST;
        break;

      case 'FINER':
        Logger.root.level = Level.FINER;
        break;

      case 'FINE':
        Logger.root.level = Level.FINE;
        break;

      case 'CONFIG':
        Logger.root.level = Level.CONFIG;
        break;

      case 'INFO':
        Logger.root.level = Level.INFO;
        break;

      case 'WARNING':
        Logger.root.level = Level.WARNING;
        break;

      case 'SEVERE':
        Logger.root.level = Level.SEVERE;
        break;

      case 'SHOUT':
        Logger.root.level = Level.SHOUT;
        break;

      case 'OFF':
        Logger.root.level = Level.OFF;
        break;
      default:
        Logger.root.level = Level.OFF;
        print('Warning: Bad loglevel value: ${env['LOGLEVEL']}');
    }
  } else {
    Logger.root.level = Level.OFF;
  }
  Logger.root.onRecord.listen(logFunction);
}
