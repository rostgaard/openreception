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

/// Message dispatcher configuration values.
class MessageDispatcher {
  final int maxTries = 10;

  /// How log the mailer between send tries.
  ///
  /// The mailer period is configured in seconds in a config file.
  final Duration mailerPeriod;
  final String smsKey;

  /// Overrides user.address if not empty.
  final String staticSenderAddress;

  /// Overrides user.name if not empty.
  final String staticSenderName;

  final int port;

  const MessageDispatcher(
      {this.port: 4070,
      this.mailerPeriod: const Duration(seconds: 30),
      this.smsKey: 'some-key@some-host.tld',
      this.staticSenderAddress: '',
      this.staticSenderName});

  factory MessageDispatcher.fromJson(Map map) {
    final MessageDispatcher defaults = const MessageDispatcher();

    final int port = map[key.port];
    validateNetworkport(port);

    final Duration mailerPeriod = map.containsKey(key.mailerPeriod)
        ? new Duration(seconds: map[key.mailerPeriod])
        : defaults.mailerPeriod;

    final String smsKey = map[key.smsKey];
    final String staticSenderAddress = map[key.staticSenderAddress];
    final String staticSenderName = map[key.staticSenderName];

    return new MessageDispatcher(
        port: port,
        mailerPeriod: mailerPeriod,
        smsKey: smsKey,
        staticSenderAddress: staticSenderAddress,
        staticSenderName: staticSenderName);
  }
  Map<String, dynamic> toJson() =>
      new Map<String, dynamic>.unmodifiable(<String, dynamic>{
        key.port: port,
        key.mailerPeriod: mailerPeriod.inSeconds,
        key.smsKey: smsKey,
        key.staticSenderAddress: staticSenderAddress,
        key.staticSenderName: staticSenderName
      });
}
