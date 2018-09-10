library ort.process;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:orf/service-io.dart' as service;
import 'package:orf/service.dart' as service;
import 'package:ort/support/support-auth.dart';
import 'package:ort/config.dart';

import 'package:path/path.dart';

part 'process/process-authserver.dart';
part 'process/process-calendarserver.dart';
part 'process/process-callflowcontrol.dart';
part 'process/process-cdrserver.dart';
part 'process/process-configserver.dart';
part 'process/process-contactserver.dart';
part 'process/process-datastoreserver.dart';
part 'process/process-dialplanserver.dart';
part 'process/process-freeswitch.dart';
part 'process/process-messagedispatcher.dart';
part 'process/process-messageserver.dart';
part 'process/process-notificationserver.dart';
part 'process/process-receptionserver.dart';
part 'process/process-userserver.dart';

const _namespace = 'test.support.process';

/// List for keeping track of launched processed. Used in environment
/// finalization in order to kill rogue processes.
Iterable<Process> get launchedProcesses => _launchedProcesses;
final List<Process> _launchedProcesses = [];

abstract class ServiceProcess {
  Future terminate();
}
