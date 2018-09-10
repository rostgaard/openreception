library ort;

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:ort/rest.dart' as rest;
import 'package:ort/filestore.dart' as filestore;

import 'package:ort/support.dart';
import 'package:test/test.dart';

void runBenchmarkTests() {
//  benchmark.allTests();
}

void runFilestoreTests() {
 // filestore.allTests();
}

void runRestStoreTests() {
  rest.allTests();
}

void main() {
  void logMessage(LogRecord record) {
    final String error = '${record.error != null
        ? ' - ${record.error}'
        : ''}'
        '${record.stackTrace != null
          ? ' - ${record.stackTrace}'
          : ''}';

    if (record.level.value > Level.INFO.value) {
      print('${record.time} - ${record}$error');
    } else {
      print('${record.time} - ${record}$error');
    }
  }

  Map<String, String> env = Platform.environment;

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
    Logger.root.level = Level.ALL;
  }
  Logger.root.onRecord.listen(logMessage);

  /*
   * We treat the test framework as a test itself. This gives us the
   * possibility to output the test state, and to wait for setup and teardown.
   */
  group('pre-test setup', () {
    Logger _log = Logger('test environment detection');
    TestEnvironmentConfig envConfig;

    setUp(() async {
      envConfig = TestEnvironment().envConfig;
      await envConfig.load();
    });

    test('Setup', () {
      expect(envConfig, isNotNull);
      expect(envConfig.externalIp, isNotEmpty);
      _log.info(envConfig.toString());
    });
  });

  runFilestoreTests();
  runRestStoreTests();
  runBenchmarkTests();

  /* We treat the test framework as a test itself. This gives us the
   * possibility to output the test state, and to wait for setup and teardown.
   */
  group('post-test cleanup', () {
    test('finalize test environment', () => TestEnvironment().finalize());
  });

  ProcessSignal.sigint.watch().listen((_) async {
    await TestEnvironment().finalize();

    exit(0);
  });
}
