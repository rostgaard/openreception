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

/// Dialplan server configuration values.
class DialplanServer {
  final int port;
  final String freeswitchConfPath;

  /// Dialplan compiler parameters
  final bool goLive;
  final String playbackPrefix;
  final String testNumber;
  final String testEmail;

  const DialplanServer(
      {this.port: 4060,
      this.freeswitchConfPath: '/usr/local/freeswitch/conf',
      this.goLive: true,
      this.playbackPrefix: 'greetings-dir',
      this.testNumber: 'xxxxxxxx',
      this.testEmail: 'someguy@example.com'});

  factory DialplanServer.fromJson(Map map, {defaults: const DialplanServer()}) {
    final int port = map[key.port];
    final String freeswitchConfPath = map[key.freeswitchConfPath];
    final bool goLive = map[key.goLive];
    final String playbackPrefix = map[key.playbackPrefix];
    final String testNumber = map[key.testNumber];
    final String testEmail = map[key.testEmail];

    return new DialplanServer(
        port: port,
        freeswitchConfPath: freeswitchConfPath,
        goLive: goLive,
        playbackPrefix: playbackPrefix,
        testNumber: testNumber,
        testEmail: testEmail);
  }

  Map toJson() => new Map.unmodifiable({
        key.port: port,
        key.freeswitchConfPath: freeswitchConfPath,
        key.goLive: goLive,
        key.playbackPrefix: playbackPrefix,
        key.testNumber: testNumber,
        key.testEmail: testEmail
      });
}
