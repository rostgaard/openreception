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

/// Authentication server configuration values.
class AuthServer {
  final Duration tokenLifetime;
  final String clientId;
  final String clientSecret;
  final String tokenDir;
  final int port;

  const AuthServer(
      {this.port: 4050,
      this.clientId: 'undefined-google-client-id',
      this.clientSecret: 'undefined-google-client-secret',
      this.tokenLifetime: const Duration(hours: 12),
      this.tokenDir: ''});

  factory AuthServer.fromJson(Map map) {
    final Duration tokenLifetime =
        new Duration(seconds: map[key.tokenLifetime]);
    final String tokenDir = map[key.tokenDir];

    final String clientId = map[key.googleclientId];
    final String clientSecret = map[key.googleclientSecret];

    final int port = map[key.port];

    return new AuthServer(
        port: port,
        clientId: clientId,
        clientSecret: clientSecret,
        tokenDir: tokenDir,
        tokenLifetime: tokenLifetime);
  }

  Map<String, dynamic> toJson() =>
      new Map<String, dynamic>.unmodifiable(<String, dynamic>{
        key.port: port,
        key.googleclientId: clientId,
        key.googleclientSecret: clientSecret,
        key.tokenDir: tokenDir,
        key.tokenLifetime: tokenLifetime.inSeconds
      });

  //Uri get clientUri => Uri.parse('http://localhost:8080');

  //Uri get redirectUri => Uri.parse('$externalUri/token/oauth2callback');
}

/// An [ArgParser] suitable for parsing command line arguments.
///
/// The [ArgParser] may be used to convert arguments into [ArgResults]
/// that can then be turned into [AuthServer] objects, using the
/// [AuthServer.fromArgs] constructor.
ArgParser authServerArgParser() {
  Configuration defaults = const Configuration.defaults();
  return new ArgParser()
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
        defaultsTo: defaults.authServer.port.toString(),
        help: 'The port the HTTP server listens on.')
    ..addOption(key.hostname,
        defaultsTo: defaults.externalHostname,
        help: 'The hostname or IP listen-address for the HTTP server')
    ..addOption(key.googleclientId,
        defaultsTo: defaults.authServer.clientId, help: 'The Google client ID')
    ..addOption(key.googleclientSecret,
        defaultsTo: defaults.authServer.clientSecret,
        help: 'The Google client secret')
    ..addOption(key.tokenLifetime,
        defaultsTo: defaults.authServer.tokenLifetime.inSeconds.toString(),
        help: 'The maximum lifetime of tokens (in seconds)')
    ..addOption(key.tokenDir,
        defaultsTo: defaults.authServer.tokenDir,
        help: 'The directory to load pre-made tokens from');
}

/// Merges [configuration] map with parsed argument [results].
Map mergeAuthArgResults(ArgResults results, Map configuration) {
  final String hostname =
      _coalesce([results[key.hostname], configuration[key.hostname]]);
  final String datastorePath =
      _coalesce([results[key.datastorePath], configuration[key.datastorePath]]);

  return new Map.from(configuration)
    ..addAll({
      key.externalHostname: hostname,
      key.datastorePath: datastorePath,
      key.authServer: {
        key.port: _coalesce([
          int.parse(results[key.port]),
          configuration[key.authServer][key.port]
        ]),
        key.tokenDir: _coalesce([
          results[key.tokenDir],
          configuration[key.authServer][key.tokenDir]
        ]),
        key.tokenLifetime: _coalesce([
          int.parse(results[key.tokenLifetime]),
          configuration[key.authServer][key.tokenLifetime]
        ]),
        key.googleclientId: _coalesce([
          results[key.googleclientId],
          configuration[key.authServer][key.googleclientId]
        ]),
        key.googleclientSecret: _coalesce([
          results[key.googleclientSecret],
          configuration[key.authServer][key.googleclientSecret]
        ])
      }
    });
}
