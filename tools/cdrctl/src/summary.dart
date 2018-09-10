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

library summary;

import 'dart:convert';
import 'dart:io';

import 'package:orf/model.dart';

import 'callpricing.dart';
import 'configuration.dart';
import 'logger.dart';

/**
 * Return the cost of [cdrEntry]. Logs failures.
 */
double getOutboundCost(CdrEntry cdrEntry, Configuration config, Logger log) {
  try {
    return cdrEntry.cost(callPrices, config.callChargeMultiplier);
  } on PriceNotFound catch (error) {
    log.disaster(error.message);
    return ((callPrices['fallback']['setup'] +
                (cdrEntry.billSec * callPrices['fallback']['persecond'])) *
            config.callChargeMultiplier)
        .ceilToDouble();
  } on UnknownDestination catch (error) {
    log.info(error.message);
    return 0.0;
  }
}

/**
 * Save the summary data for [cdrEntry] to the [config.cdrSummaryDirectory].
 *
 * Does not throw. Logs all errors as severe.
 */
void saveSummary(CdrEntry cdrEntry, Configuration config, Logger log) {
  try {
    final StringBuffer sb = new StringBuffer();
    final CdrEntryState state = cdrEntry.state;
    final String logText =
        'saveSummary() summary data for CDR file ${cdrEntry.filename}\n'
        '  agentBeginEpoch ${cdrEntry.agentBeginEpoch}\n'
        '  agentChannel ${cdrEntry.agentChannel}\n'
        '  callNotify ${cdrEntry.callNotify}\n'
        '  destination ${cdrEntry.destination}\n'
        '  direction ${cdrEntry.direction}\n'
        '  ivr: ${cdrEntry.ivr}\n'
        '  receptionOpen ${cdrEntry.receptionOpen}\n'
        '  rid ${cdrEntry.rid}\n'
        '  uid ${cdrEntry.uid}\n'
        '  voicemail ${cdrEntry.voicemail}\n';
    CdrSummary summary;
    File summaryFile;

    void loadSummaryObject() {
      summaryFile = new File(summaryFilePath(cdrEntry, config, cdrEntry.rid));

      if (summaryFile.existsSync()) {
        summary = new CdrSummary.fromJson(
            json.decode(summaryFile.readAsStringSync()));
      } else {
        summaryFile.createSync(recursive: true);
        summary = new CdrSummary()..rid = cdrEntry.rid;
      }
    }

    switch (state) {
      case CdrEntryState.agentChannel:
        sb.write(
            'summary.saveSummary() ${cdrEntry.filename} state is ${CdrEntryState.agentChannel} - ignoring');
        break;
      case CdrEntryState.inboundNotNotified:
        sb.write('${logText}  state: ${CdrEntryState.inboundNotNotified}');
        loadSummaryObject();

        summary.inboundNotNotified += 1;
        summary.cdrFiles.add(cdrEntry.filename);

        summaryFile.writeAsStringSync(json.encode(summary));
        break;
      case CdrEntryState.notifiedAnsweredByAgent:
        sb.write('${logText}  state: ${CdrEntryState.notifiedAnsweredByAgent}');
        loadSummaryObject();

        final CdrAgentSummary agentSummary =
            summary.getAgentSummary(cdrEntry.uid);

        if (cdrEntry.agentBeginEpoch - cdrEntry.startEpoch <= 10) {
          agentSummary.answered10 += 1;
        } else if (cdrEntry.agentBeginEpoch - cdrEntry.startEpoch > 10 &&
            cdrEntry.agentBeginEpoch - cdrEntry.startEpoch <= 20) {
          agentSummary.answered10To20 += 1;
        } else if (cdrEntry.agentBeginEpoch - cdrEntry.startEpoch > 20 &&
            cdrEntry.agentBeginEpoch - cdrEntry.startEpoch <= 60) {
          agentSummary.answered20To60 += 1;
        } else {
          agentSummary.answeredAfter60 += 1;
        }

        final int callLength =
            cdrEntry.agentEndEpoch - cdrEntry.agentBeginEpoch;
        if (callLength <= config.shortCallBoundaryInSeconds) {
          agentSummary.shortCalls += 1;
        } else if (callLength >= config.longCallBoundaryInSeconds) {
          agentSummary.longCalls += 1;
        }

        agentSummary.inboundBillSeconds += cdrEntry.billSec;
        agentSummary.cdrFiles.add(cdrEntry.filename);

        summary.setAgentSummary(agentSummary);

        summaryFile.writeAsStringSync(json.encode(summary));
        break;
      case CdrEntryState.notifiedNotAnswered:
        sb.write('${logText}  state: ${CdrEntryState.notifiedNotAnswered}');
        loadSummaryObject();

        summary.notifiedNotAnswered += 1;
        summary.cdrFiles.add(cdrEntry.filename);

        summaryFile.writeAsStringSync(json.encode(summary));
        break;
      case CdrEntryState.outboundByAgent:
        sb.write('${logText}  state: ${CdrEntryState.outboundByAgent}');
        loadSummaryObject();

        final CdrAgentSummary agentSummary =
            summary.getAgentSummary(cdrEntry.uid);

        agentSummary.outbound += 1;
        agentSummary.cdrFiles.add(cdrEntry.filename);

        summary.outBoundBillSeconds += cdrEntry.billSec;
        summary.outboundCost += getOutboundCost(cdrEntry, config, log);
        summary.setAgentSummary(agentSummary);

        summaryFile.writeAsStringSync(json.encode(summary));
        break;
      case CdrEntryState.outboundByPbx:
        sb.write('${logText}  state: ${CdrEntryState.outboundByPbx}');
        loadSummaryObject();

        summary.outboundByPbx += 1;
        summary.outBoundBillSeconds += cdrEntry.billSec;
        summary.outboundCost += getOutboundCost(cdrEntry, config, log);
        summary.cdrFiles.add(cdrEntry.filename);

        summaryFile.writeAsStringSync(json.encode(summary));
        break;
      case CdrEntryState.unknown:
        sb.write(
            'summary.saveSummary() ${cdrEntry.filename} state is ${CdrEntryState.unknown}');
        break;
    }

    log.info(sb.toString());
  } catch (error, stackTrace) {
    log.error(
        'summary.saveSummary() failed with ${error} - ${stackTrace} on CDR ${cdrEntry.filename}');
  }
}

/**
 * Either return a valid path to the [rid] summary file for the
 * [cdrEntry.startEpoch], or throw an exception if [rid] is 0.
 */
String summaryFilePath(CdrEntry cdrEntry, Configuration config, int rid) {
  final DateTime stamp =
      new DateTime.fromMillisecondsSinceEpoch(cdrEntry.startEpoch * 1000);
  final String date = stamp.toIso8601String().split('T').first;

  if (rid == 0) {
    throw 'summaryFilePath() failed with receptionId == 0';
  }

  return '${config.cdrSummaryDirectory.path}/${date}/${rid.toString()}-cdr-summary.json';
}
