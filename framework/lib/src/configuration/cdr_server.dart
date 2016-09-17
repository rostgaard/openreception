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

/// CDR server configuration values.
class CdrServer {
  final int port;
  final String pathToCdrCtl;

  const CdrServer({this.port: 4090, this.pathToCdrCtl: '/path/cdrctl.dart'});

  factory CdrServer.fromJson(Map map) {
    final int port = map[key.port];
    final String pathToCdrCtl = map[key.cdrCtlPath];
    validateNetworkport(port);

    return new CdrServer(port: port, pathToCdrCtl: pathToCdrCtl);
  }

  Map toJson() => {key.port: port, key.cdrCtlPath: pathToCdrCtl};
}

class CdrServerArgparser {
  final CdrServer conf;

  final String hostname;
  final String datastorePath;
  final bool help;
  final String configFilePath;
}

/// Merges [confMap] map with parsed argument [results].
Map mergeCdrArgResults(ArgResults results, Map confMap) {
  final _ModifiableConfiguration config =
      new _ModifiableConfiguration.fromJson(confMap);

  final String hostname =
      _coalesce([results[key.hostname], config.externalHostname]);
  final String datastorePath =
      _coalesce([results[key.datastorePath], config.filestorePath]);

  return new Map.from(confMap)
    ..addAll({
      key.externalHostname: hostname,
      key.datastorePath: datastorePath,
      key.cdr: {
        key.port: _coalesce(
            [int.parse(results[key.port]), confMap[key.cdr][key.port]])
      }
    });
}
