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

/// Common configuration models and parsing functions.
///
/// Currently unused in the stack, but is meant to be implemented as a
/// common method for configuring and launching processes for use with,
/// among others, tests.

library orf.config;

import 'package:args/args.dart';

/// Configuration class for Datastore service.
class Datastore {
  /// Creates a [Datastore] configuration object.
  ///
  /// Optionally takes in [eslconfig], which defaults to a standard config
  /// if omitted.
  const Datastore({EslConfig this.eslconfig: const EslConfig()});

  /// Creates a [Datastore] configuration object from parsed
  /// agument [results].
  factory Datastore.fromArgs(ArgResults results) {
    final EslConfig eslconfig = EslConfig.fromArgs(results);

    return Datastore(eslconfig: eslconfig);
  }

  /// Creates a [Datastore] object with default values.
  factory Datastore.defaults() => const Datastore();

  /// ESL configuration values
  final EslConfig eslconfig;
}

/// Configuration class for ESL configuration values.
class EslConfig {
  /// Creates a [EslConfig] object.
  ///
  /// Optionally takes in [hostname], [password] and [port] that falls back
  /// to default values if omitted.
  const EslConfig(
      {String this.hostname: 'localhost',
      String this.password: 'ClueCon',
      int this.port: 8021});

  /// Creates a [EslConfig] object from a [dsn] string.
  ///
  /// A dsn string for [EslConfig] has the form <password>@<host>:<port>,
  /// where the port may be omitted.
  ///
  /// An example of a dsn is `ClueCon@pbx.example:8021`. This example will
  /// create a config that connects to the host `pbx.example` on port `8021`
  /// using password `ClueCon`.
  factory EslConfig.fromDsn(String dsn) {
    String hostname = '';
    String password = '';
    int port = 0;

    {
      final List<String> split = dsn.split('@');

      if (split.length > 2) {
        throw FormatException('Dsn $dsn contains too many "@" characters');
      } else if (split.length == 2) {
        password = split.first;
        dsn = split.last;
      }
    }

    {
      final List<String> split = dsn.split(':');
      if (split.length > 2) {
        throw FormatException('Dsn $dsn contains too many ":" characters');
      } else if (split.length == 2) {
        port = int.parse(split.last);
      }
      hostname = split.first;
    }

    return EslConfig(hostname: hostname, password: password, port: port);
  }

  /// Creates a [EslConfig]  configuration object from parsed
  /// agument [results].
  factory EslConfig.fromArgs(ArgResults results) {
    final String hostname = results['esl-hostname'] as String;
    final String password = results['esl-password'] as String;
    final int port = results['esl-port'] as int;

    return EslConfig(hostname: hostname, port: port, password: password);
  }

  /// The hostname of the ESL server.
  final String hostname;

  /// The password for authenticating against the ESL server.
  final String password;

  /// The port of the ESL server.
  final int port;

  /// A dsn represenation of the [EslConfig].
  ///
  /// The representation is suitable for creating a [EslConfig] object
  /// using the [EslConfig.fromDsn] constructor.
  String toDsn() => password + '@' + hostname + ':' + port.toString();

  /// An [ArgParser] suitable for parsing command line arguments.
  ///
  /// The [ArgParser] may be used to convert arguments into [ArgResults]
  /// that can then be turned into [EslConfig] objects, using the
  /// [EslConfig.fromArgs] constructor.
  static ArgParser get argParser {
    EslConfig defaults = const EslConfig();

    return ArgParser()
      ..addOption('esl-hostname',
          defaultsTo: defaults.hostname, help: 'The hostname of the ESL server')
      ..addOption('esl-password',
          defaultsTo: defaults.password,
          help: 'The password for the ESL server')
      ..addOption('esl-port',
          defaultsTo: defaults.port.toString(),
          help: 'The port of the ESL server');
  }
}

/// Standard configuration values, common among all server configurations.
abstract class StandardConfig {
  /// Default constructor.
  const StandardConfig();
  String get externalHostName => 'localhost';

  String get serverToken => 'veeerysecret';

  int get httpPort;

  Uri get externalUri => Uri.parse('http://$externalHostName:$httpPort');
}

/// Authentication server configuration values.
class AuthServer extends StandardConfig {
  const AuthServer(
      {this.clientId: 'google-client-id',
      this.tokenLifetime: const Duration(hours: 12),
      this.clientSecret: 'google-client-secret',
      this.tokenDir: ''});

  /// Creates a [AuthServer] configuration object from parsed
  /// agument [results].
  factory AuthServer.fromArgs(ArgResults results) {
    final String clientId = results['google-client-id'] as String;
    final String clientSecret = results['google-client-secret'] as String;
    final Duration lifetime =
        Duration(seconds: int.parse(results['token-lifetime'] as String));
    final String tokenDir = results['token-dir'] as String;

    return AuthServer(
        clientId: clientId,
        tokenLifetime: lifetime,
        clientSecret: clientSecret,
        tokenDir: tokenDir);
  }

  final Duration tokenLifetime;
  final String clientId;
  final String clientSecret;
  final String tokenDir;

  @override
  final int httpPort = 4050;

  Uri get clientUri => Uri.parse('http://localhost:8080');

  Uri get redirectUri => Uri.parse('$externalUri/token/oauth2callback');

  /// An [ArgParser] suitable for parsing command line arguments.
  ///
  /// The [ArgParser] may be used to convert arguments into [ArgResults]
  /// that can then be turned into [AuthServer] objects, using the
  /// [AuthServer.fromArgs] constructor.
  static ArgParser get argParser {
    AuthServer defaults = const AuthServer();

    return ArgParser()
      ..addOption('google-client-id',
          defaultsTo: defaults.clientId, help: 'The Google client ID')
      ..addOption('google-client-secret',
          defaultsTo: defaults.clientSecret, help: 'The Google client secret')
      ..addOption('token-lifetime',
          defaultsTo: defaults.tokenLifetime.toString(),
          help: 'The maximum lifetime of tokens (in seconds)')
      ..addOption('token-dir',
          defaultsTo: defaults.tokenDir,
          help: 'The directory to load pre-made tokens from');
  }
}
