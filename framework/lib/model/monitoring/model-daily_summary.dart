/*                  This file is part of OpenReception
                   Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.model.monitoring;

class DailySummary {
  final int inboundCount;
  final int outBoundCount;
  final Duration outboundHandleTime;
  final Duration inboundHandleTime;
  final int callsUnAnswered;
  final int callsAnsweredWithin20s;

  final int callWaitingMoreThanOneMinute;
  final Map<int, AgentStatSummary> agentStats;

  factory DailySummary(DailyReport report) {
    int inboundCount = 0;
    int outboundCount = 0;
    int callsUnAnswered = 0;
    int callsAnsweredWithin20s = 0;
    int callWaitingMoreThanOneMinute = 0;
    Duration inboundHandleTime = new Duration();
    Duration outboundHandleTime = new Duration();

    Map<int, int> callsByAgent = <int, int>{};
    Map<int, int> obCallsByAgent = <int, int>{};
    Map<int, int> below20sByAgent = <int, int>{};

    Map<int, Duration> callDurationByAgent = <int, Duration>{};
    Map<int, Duration> obCallDurationByAgent = <int, Duration>{};
    Set<int> seenUids = new Set<int>();

    Map<int, Duration> pauseDurations = <int, Duration>{};
    {
      Map<int, UserStateHistory> lastStates = <int, UserStateHistory>{};
      for (UserStateHistory ush in report.userStateHistory) {
        if (ush.uid != noId && !seenUids.contains(ush.uid)) {
          seenUids.add(ush.uid);
        }

        if (!pauseDurations.containsKey(ush.uid)) {
          pauseDurations[ush.uid] = new Duration();
        }

        if (lastStates.containsKey(ush.uid)) {
          final UserStateHistory lastState = lastStates[ush.uid];
          final Duration delta = ush.timestamp.difference(lastState.timestamp);

          if (lastState.pause && !ush.pause) {
            pauseDurations[ush.uid] += delta;
            lastStates.remove(ush.uid);
          } else if (ush.pause) {
            lastStates[ush.uid] = ush;
          }
        } else {
          lastStates[ush.uid] = ush;
        }
      }
    }

    Map<int, int> messageCounts = <int, int>{};

    for (MessageHistory mh in report.messageHistory) {
      if (mh.uid != noId && !seenUids.contains(mh.uid)) {
        seenUids.add(mh.uid);
      }

      if (!messageCounts.containsKey(mh.uid)) {
        messageCounts[mh.uid] = 0;
      }

      messageCounts[mh.uid]++;
    }

    for (HistoricCall history in report.callHistory) {
      if (history.uid != noId && !seenUids.contains(history.uid)) {
        seenUids.add(history.uid);
      }

      if (history.inbound) {
        inboundCount++;
        inboundHandleTime += history.handleTime;

        /// Individual agent stats.
        if (history.unAssigned) {
          callsUnAnswered++;
        } else if (!history.unAssigned) {
          if (!callsByAgent.containsKey(history.uid)) {
            callsByAgent[history.uid] = 0;
          }
          if (!callDurationByAgent.containsKey(history.uid)) {
            callDurationByAgent[history.uid] = new Duration();
          }

          callDurationByAgent[history.uid] += history.handleTime;
          callsByAgent[history.uid] += 1;

          if (history.isAnswered) {
            if (history.answerLatency < new Duration(seconds: 20)) {
              callsAnsweredWithin20s++;

              if (!below20sByAgent.containsKey(history.uid)) {
                below20sByAgent[history.uid] = 0;
              }
              below20sByAgent[history.uid]++;
            } else if (history.answerLatency > new Duration(seconds: 60)) {
              callWaitingMoreThanOneMinute++;
            }
          }
        }
      } else {
        outboundCount++;
        outboundHandleTime += history.handleTime;
        if (!obCallsByAgent.containsKey(history.uid)) {
          obCallsByAgent[history.uid] = 0;
        }

        if (!obCallDurationByAgent.containsKey(history.uid)) {
          obCallDurationByAgent[history.uid] = new Duration();
        }

        obCallDurationByAgent[history.uid] += history.handleTime;

        if (history.unAssigned) {
          new Logger('orf.model.monitoring.CallSummary')
              .warning('Bad history entry: $history');
        }
        obCallsByAgent[history.uid] = obCallsByAgent[history.uid] + 1;
      }
    }

    final Map<int, AgentStatSummary> stats = <int, AgentStatSummary>{};

    for (int uid in seenUids) {
      final int iCallCount =
          callsByAgent.containsKey(uid) ? callsByAgent[uid] : 0;
      final int outBoundCount =
          obCallsByAgent.containsKey(uid) ? obCallsByAgent[uid] : 0;

      final Duration iDurCallCount = callDurationByAgent.containsKey(uid)
          ? callDurationByAgent[uid]
          : new Duration();

      final Duration oDurCallCount = obCallDurationByAgent.containsKey(uid)
          ? obCallDurationByAgent[uid]
          : new Duration();

      final Duration pauseDuration = pauseDurations.containsKey(uid)
          ? pauseDurations[uid]
          : new Duration();

      final int messageCount =
          messageCounts.containsKey(uid) ? messageCounts[uid] : 0;

      final int below20s =
          below20sByAgent.containsKey(uid) ? below20sByAgent[uid] : 0;

      stats[uid] = new AgentStatSummary(uid, iCallCount, outBoundCount,
          iDurCallCount, oDurCallCount, below20s, messageCount, pauseDuration);
    }

    return new DailySummary._internal(
        inboundCount,
        outboundCount,
        callsUnAnswered,
        callsAnsweredWithin20s,
        callWaitingMoreThanOneMinute,
        inboundHandleTime,
        outboundHandleTime,
        stats);
  }

  DailySummary._internal(
      this.inboundCount,
      this.outBoundCount,
      this.callsUnAnswered,
      this.callsAnsweredWithin20s,
      this.callWaitingMoreThanOneMinute,
      this.inboundHandleTime,
      this.outboundHandleTime,
      this.agentStats);

  DailySummary.fromJson(Map<String, dynamic> map)
      : this.inboundCount = map[_Key.inbound],
        this.outBoundCount = map[_Key.outbound],
        this.callsUnAnswered = map[_Key.unanswered],
        this.callsAnsweredWithin20s = map[_Key.below20s],
        this.callWaitingMoreThanOneMinute = map[_Key.oneminuteplus],
        this.inboundHandleTime =
            new Duration(milliseconds: map[_Key.inboundHandleTime]),
        this.outboundHandleTime =
            new Duration(milliseconds: map[_Key.outboundHandleTime]),
        this.agentStats = <int, AgentStatSummary>{} {
    List<Map<String, dynamic>> agentstats =
        map[_Key.agent] as List<Map<String, dynamic>>;
    for (Map<String, dynamic> stat in agentstats) {
      AgentStatSummary summary = new AgentStatSummary.fromJson(stat);

      agentStats[summary.uid] = summary;
    }
  }

  Map<String, dynamic> toJson() =>
      new Map<String, dynamic>.unmodifiable(<String, dynamic>{
        _Key.inbound: inboundCount,
        _Key.outbound: outBoundCount,
        _Key.inboundHandleTime: inboundHandleTime.inMilliseconds,
        _Key.outboundHandleTime: outboundHandleTime.inMilliseconds,
        _Key.unanswered: callsUnAnswered,
        _Key.below20s: callsAnsweredWithin20s,
        _Key.oneminuteplus: callWaitingMoreThanOneMinute,
        _Key.agent: agentStats.values
            .map((AgentStatSummary summary) => summary.toJson())
            .toList(growable: false)
      });
}
