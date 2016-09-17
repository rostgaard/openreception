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

/// SMTP configuration values
class SmtpConfig {
  /// SMTP server hostname
  final String hostname;

  /// Ignore warnings about invalid or expired certificates
  final bool ignoreBadCertificate;

  /// SMTP sender name used in HELO greeting.
  final String name;

  /// STMP username
  final String username;

  /// SMTP password
  final String password;

  /// SMTP port
  final int port;

  /// Use SMTP over encrypted channel.
  final bool secure;

  const SmtpConfig(
      {this.hostname: 'some.smtp.host',
      this.ignoreBadCertificate: false,
      this.name: 'my.host',
      this.username: 'some user',
      this.password: 'secret',
      this.port: 465,
      this.secure: true});

  factory SmtpConfig.fromJson(Map map) {
    final String hostname = map[key.hostname];
    final bool ignoreBadCertificate = map[key.ignoreBadCertificate];
    final String name = map[key.name];
    final String username = map[key.username];
    final String password = map[key.password];
    final int port = map[key.port];
    final bool secure = map[key.secure];

    return new SmtpConfig(
        hostname: hostname,
        ignoreBadCertificate: ignoreBadCertificate,
        name: name,
        username: username,
        password: password,
        port: port,
        secure: secure);
  }

  Map toJson() => {
        key.hostname: hostname,
        key.ignoreBadCertificate: ignoreBadCertificate,
        key.name: name,
        key.username: username,
        key.password: password,
        key.port: port,
        key.secure: secure
      };
}
