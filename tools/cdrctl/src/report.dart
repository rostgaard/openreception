/*                 Copyright (C) 2016-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

library report;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:orf/model.dart';
import 'package:path/path.dart' as path;

import 'configuration.dart';
import 'logger.dart';

final JsonEncoder encoder = const JsonEncoder.withIndent('  ');

/**
 * Convenience method to check if [timestamp] is equal to or between [from] or
 * [to].
 */
bool betweenFromAndTo(DateTime timestamp, DateTime from, DateTime to) =>
    (timestamp.isAfter(from) || timestamp.isAtSameMomentAs(from)) &&
    (timestamp.isBefore(to) || timestamp.isAtSameMomentAs(to));

/**
 * Dispatch based on the given command line arguments.
 */
Future dispatch(
    String direction,
    String kind,
    DateTime from,
    DateTime to,
    List<String> rids,
    List<String> uids,
    bool includeCdrFiles,
    bool jsonOutput,
    bool prettyPrint,
    Configuration config,
    Logger log) {
  Future method;

  if (kind == 'list') {
    method =
        list(from, to, direction, rids, uids, jsonOutput, prettyPrint, config);
  } else if (kind == 'summary') {
    method = summary(
        from, to, rids, includeCdrFiles, jsonOutput, prettyPrint, config);
  }

  return method;
}

/**
 * Return all directories where the name of the directory parse to a timestamp
 * that is equal to or greater than [from] AND equal to or lesser than [to].
 */
Future<List<Directory>> dirs(Directory directory, DateTime from, DateTime to,
        Configuration config) async =>
    await directory
        .list()
        .where((FileSystemEntity e) =>
            e is Directory &&
            betweenFromAndTo(
                DateTime.parse(path.basename(e.path)),
                new DateTime(from.year, from.month, from.day),
                new DateTime(to.year, to.month, to.day)))
        .toList();

/**
 * Output a call list JSON, filtered on [from] - [to], [rids] and/or [uids] and
 * [direction].
 */
Future list(
    DateTime from,
    DateTime to,
    String direction,
    List<String> rids,
    List<String> uids,
    bool jsonOutput,
    bool prettyPrint,
    Configuration config) async {
  int hit = 0;
  int miss = 0;
  final Map<String, List<String>> directionMap = {
    'inbound': [
      CdrEntryState.inboundNotNotified.toString().split('.').last,
      CdrEntryState.notifiedAnsweredByAgent.toString().split('.').last,
      CdrEntryState.notifiedNotAnswered.toString().split('.').last
    ],
    'outbound': [
      CdrEntryState.outboundByAgent.toString().split('.').last,
      CdrEntryState.outboundByPbx.toString().split('.').last
    ]
  };
  final Map<String, dynamic> output = new Map<String, dynamic>();

  output['entries'] = new List<Map>();

  bool relevantFile(FileSystemEntity e) {
    final String filename = path.basename(e.path);
    final String kind = filename.split('_').first;
    final int startEpoch =
        int.parse(filename.split('_start_')[1].split('_').first);
    final DateTime start =
        new DateTime.fromMillisecondsSinceEpoch(startEpoch * 1000);
    final bool startOk =
        (start.isAfter(from) || start.isAtSameMomentAs(from)) &&
            (start.isBefore(to) || start.isAtSameMomentAs(to));

    if (!filename.startsWith('agentChannel') &&
        startOk &&
        path.extension(filename) == '.json') {
      final bool directionOk =
          direction == 'both' ? true : directionMap[direction].contains(kind);
      final bool ridsOk = rids.isEmpty
          ? true
          : rids.any((String rid) => filename.contains('_rid_${rid}_'));
      final bool uidsOk = uids.isEmpty
          ? true
          : uids.any((String uid) => filename.contains('_uid_${uid}_'));
      if (ridsOk && uidsOk && directionOk) {
        hit += 1;
        return true;
      }
    }

    miss += 1;
    return false;
  }

  for (Directory dir in await dirs(config.cdrEntryStore, from, to, config)) {
    for (FileSystemEntity e in dir.listSync().where(relevantFile)) {
      output['entries'].add(json.decode((e as File).readAsStringSync()));
    }
  }

  output['from'] = '${from.toString()}';
  output['to'] = '${to.toString()}';
  output['rid'] = rids;
  output['uid'] = uids;
  output['hit'] = hit;
  output['miss'] = miss;

  if (jsonOutput && prettyPrint) {
    final JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    stdout.write(encoder.convert(output));
  } else if (jsonOutput) {
    stdout.write(json.encode(output));
  } else {
    stdout.writeln('From: ${output['from']}');
    stdout.writeln('To: ${output['to']}');
    stdout.writeln('rids: ${rids.join(',')}');
    stdout.writeln('uids: ${uids.join(',')}');
    stdout.writeln('hit: $hit');
    stdout.writeln('miss: $miss');
    stdout.writeln();
    await Future.forEach(output['entries'], (Map m) {
      stdout.writeln(new CdrEntry.fromJson(m));
      stdout.writeln();
    });
  }
}

/// Output a JSON reception summary report.
Future summary(
    DateTime from,
    DateTime to,
    List<String> rids,
    bool includeCdrFiles,
    bool jsonOutput,
    bool prettyPrint,
    Configuration config) async {
  final Map<String, dynamic> output = new Map<String, dynamic>();
  final Map<String, CdrSummary> summaries = new Map<String, CdrSummary>();

  bool relevantFile(FileSystemEntity e) {
    final bool isJson = path.extension(e.path) == '.json';
    return rids.isEmpty && isJson
        ? true
        : isJson &&
            rids.any((String rid) => path.basename(e.path).startsWith(rid));
  }

  for (Directory dir
      in await dirs(config.cdrSummaryDirectory, from, to, config)) {
    for (FileSystemEntity e in dir.listSync().where(relevantFile)) {
      final CdrSummary s = new CdrSummary.fromJson(
          json.decode((e as File).readAsStringSync()),
          alsoCdrFiles: includeCdrFiles);
      if (summaries.containsKey(s.rid.toString())) {
        summaries[s.rid.toString()].add(s, alsoCdrFiles: includeCdrFiles);
      } else {
        summaries[s.rid.toString()] = s;
      }
    }
  }

  output['from'] = '${from.toString()}';
  output['to'] = '${to.toString()}';
  output['rid'] = rids;
  output['callChargeMultiplier'] = config.callChargeMultiplier;
  output['longCallBoundaryInSeconds'] = config.longCallBoundaryInSeconds;
  output['shortCallBoundaryInSeconds'] = config.shortCallBoundaryInSeconds;
  output['summaries'] = new List<CdrSummary>();

  (output['summaries'] as List<CdrSummary>).addAll(summaries.values);

  if (jsonOutput && prettyPrint) {
    final JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    stdout.write(encoder.convert(output));
  } else if (jsonOutput) {
    stdout.write(json.encode(output));
  } else {
    stdout.writeln('From: ${output['from']}');
    stdout.writeln('To: ${output['to']}');
    stdout.writeln('rids: ${rids.join(',')}');
    stdout.writeln('callChargeMultiplier: ${output['callChargeMultiplier']}');
    stdout.writeln(
        'longCallBoundaryInSeconds: ${output['longCallBoundaryInSeconds']}');
    stdout.writeln(
        'shortCallBoundaryInSeconds: ${output['shortCallBoundaryInSeconds']}');
    stdout.writeln();
    await Future.forEach(output['summaries'], (CdrSummary summary) {
      stdout.writeln(summary);
      if (includeCdrFiles) {
        stdout.writeln('cdrFiles:');
        stdout.writeln(summary.getAllCdrFiles().join('\n'));
      }
      stdout.writeln();
    });
  }
}
