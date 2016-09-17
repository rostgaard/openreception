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

part of orf.config;

/// Calendar server configuration values.
class CalendarServer {
  final int port;

  const CalendarServer({this.port: 4110});

  factory CalendarServer.fromJson(Map map) {
    final int port = map[key.port];

    validateNetworkport(port);

    return new CalendarServer(port: port);
  }

  Map toJson() => {key.port: port};
}

/// Handle argument parsing.
ArgParser calendarServerArgParser() {
  Configuration defaults = const Configuration.defaults();
  final ArgParser parser = new ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Output this help', negatable: false)
    ..addOption(key.configFile,
        abbr: 'f',
        help: 'Path to the config file',
        defaultsTo: defaults.filestorePath)
    ..addOption(key.datastorePath,
        abbr: 'd',
        help: 'Path to the filestore backend',
        defaultsTo: defaults.filestorePath)
    ..addOption(key.port,
        abbr: 'p',
        defaultsTo: defaults.calendarServer.port.toString(),
        help: 'The port the HTTP server listens on.')
    ..addOption(key.hostname,
        defaultsTo: defaults.externalHostname,
        help: 'The hostname or IP listen-address for the HTTP server')
    ..addOption(key.authUri,
        defaultsTo: notificationServerUri(defaults),
        help: 'The uri of the authentication server')
    ..addOption(key.notificationUri,
        defaultsTo: notificationServerUri(defaults),
        help: 'The uri of the notification server')
    ..addFlag(key.experimentalRevisioning,
        defaultsTo: false,
        help: 'Enable or disable experimental Git revisioning on this server');

  return parser;
}

/// Merges [configuration] map with parsed argument [results].
Map mergeConfigArgResults(ArgResults results, Map configuration) {
  final String hostname =
      _coalesce([results[key.hostname], configuration[key.hostname]]);
  final String datastorePath =
      _coalesce([results[key.datastorePath], configuration[key.datastorePath]]);

  return new Map.from(configuration)
    ..addAll({
      key.externalHostname: hostname,
      key.datastorePath: datastorePath,
      key.calendarServer: {
        key.port: _coalesce([
          int.parse(results[key.port]),
          configuration[key.calendarServer][key.port]
        ])
      }
    });
}
