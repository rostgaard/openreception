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

/// Contact server configuration values.
class ContactServer {
  final int port;

  const ContactServer({this.port: 4010});

  factory ContactServer.fromJson(Map map) {
    final int port = map[key.port];

    validateNetworkport(port);

    return new ContactServer(port: port);
  }

  Map toJson() => {key.port: port};
}
