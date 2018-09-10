import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:orf/service.dart' as service;
import 'package:ort/support.dart';
//import 'package:args/args.dart';

/// Logs [record] to STDOUT | STDERR depending on [record] level.
void logEntryDispatch(LogRecord record) {
  final String error = '${record.error != null ? ' - ${record.error}' : ''}'
      '${record.stackTrace != null ? ' - ${record.stackTrace}' : ''}';

  if (record.level.value > Level.INFO.value) {
    stderr.writeln('${record.time} - ${record}$error');
  } else {
    stdout.writeln('${record.time} - ${record}$error');
  }
}

Future main(args) async {
  Random rand = Random(DateTime.now().millisecondsSinceEpoch);
  /**
   * Returns a random element from [pool].
   */
  dynamic randomChoice(List pool) {
    if (pool.isEmpty) {
      throw ArgumentError('Cannot find a random value in an empty list');
    }

    int index = rand.nextInt(pool.length);

    return pool[index];
  }

  Stopwatch timer = Stopwatch()..start();
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(logEntryDispatch);

  final ArgParser parser = ArgParser()
    ..addFlag('help', abbr: 'h', help: 'Output this help', negatable: false)
    ..addOption('filestore',
        abbr: 'f', help: 'Path to the filestore', defaultsTo: '')
    ..addFlag('reuse-store', negatable: false);
  final ArgResults parsedArgs = parser.parse(args);

  final Directory fsDir = Directory(parsedArgs['filestore']);
  if (fsDir.existsSync() && !parsedArgs['reuse-store']) {
    print(
        'Filestore path already exist. Please supply a non-existing path or use the --reuse-store flag.');
    print(parser.usage);
    exit(1);
  }

  final TestEnvironmentConfig envConfig = TestEnvironment().envConfig;
  await envConfig.load();
  TestEnvironment env = TestEnvironment(path: parsedArgs['filestore']);

  if (parsedArgs['filestore'].isEmpty) {
    ServiceAgent sa = await env.createsServiceAgent();

    List orgs = List(10).map((_) async => sa.createsOrganization()).toList();

    List recs = List(20)
        .map((_) async => sa.createsReception(await randomChoice(orgs)))
        .toList();

    List(40)
        .map((_) async => sa.addsContactToReception(
            await sa.createsContact(), await randomChoice(recs)))
        .toList();

    List(10).map((_) async => await sa.createsDialplan(mustBeValid: true));

    List(10).map((_) async => await sa.createsIvrMenu());
  }

  final authserver = env.requestAuthserverProcess();
  final notificationserver = env.requestNotificationserverProcess();
  await env.requestFreeswitchProcess();
  final callflow = env.requestCallFlowProcess();
  final dialplanserver = env.requestDialplanProcess();
  final calendarserver = env.requestCalendarserverProcess();
  final contactserver = env.requestContactserverProcess();
  final messageserver = env.requestMessageserverProcess();
  final receptionserver = env.requestReceptionserverProcess();
  final userserver = env.requestUserserverProcess();
  final configserver = env.requestConfigServerProcess();
  final configClient = (await configserver).createClient(env.httpClient);
  final cdrServer = env.requestCdrServerProcess();

  configClient.register(
      service.ServerType.authentication, (await authserver).uri);
  configClient.register(
      service.ServerType.calendar, (await calendarserver).uri);
  configClient.register(service.ServerType.callflow, (await callflow).uri);
  //configClient.register(key.cdr, cdrserver.uri);
  configClient.register(service.ServerType.contact, (await contactserver).uri);
  configClient.register(
      service.ServerType.dialplan, (await dialplanserver).uri);
  configClient.register(service.ServerType.message, (await messageserver).uri);
  configClient.register(
      service.ServerType.notification, (await notificationserver).uri);
  configClient.register(service.ServerType.notificationSocket,
      (await notificationserver).notifyUri);
  configClient.register(service.ServerType.user, (await userserver).uri);
  configClient.register(
      service.ServerType.reception, (await receptionserver).uri);
  configClient.register(service.ServerType.cdr, (await cdrServer).uri);

  final clientConfig = await configClient.clientConfig();
  final JsonEncoder jsonpp = JsonEncoder.withIndent('  ');

  print("Client config:");
  print(jsonpp.convert(clientConfig));
  print("Config server is reachable on ${(await configserver).uri}");
  print("Stack is accessible by using tokens:");
  print('  ' + (await authserver).tokenDir.tokens.join('\n  '));

  timer.stop();
  print('Stack startup time: ${timer.elapsedMilliseconds}ms');

  ProcessSignal.sigint.watch().listen((_) async {
    final teardownTimer = Stopwatch()..start();
    if (!parsedArgs['reuse-store']) {
      await env.clear();
    }
    await env.finalize();
    teardownTimer.stop();
    print('Stack shutdown time: ${teardownTimer.elapsedMilliseconds}ms');
    exit(0);
  });
}
