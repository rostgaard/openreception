/*                  This file is part of OpenReception
                   Copyright (C) 2014-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.model;

/// A summary of agent stats, such as amount of outbound calls and amount of
/// calls answered within specific time limits.
class CdrAgentSummary {
  int answered10 = 0; // Calls answered <=10 seconds
  int answered10To20 = 0; // Calls answered >10 && <=20 seconds
  int answered20To60 = 0; // Calls answered >20 && <= 60 seconds
  int answeredAfter60 = 0; // Calls answered >=60 seconds
  List<String> cdrFiles =
      new List<String>(); // List of CDR files for this agent
  int inboundBillSeconds = 0; // Accumulated amount of inbound seconds
  int longCalls = 0; // Calls that lasted >= config.longCallBoundaryInSeconds
  int outbound = 0; // Amount of outbound calls made by this agent
  int shortCalls = 0; // Calls that lasted <= config.shortCallBoundaryInSeconds
  int uid = 0; // The agent id

  /// Default constructor.
  CdrAgentSummary();

  /// JSON constructor
  CdrAgentSummary.fromJson(Map<dynamic, dynamic> json,
      {bool alsoCdrFiles: true}) {
    answered10 = json[key.CdrKey.answered10];
    answered10To20 = json[key.CdrKey.answered10to20];
    answered20To60 = json[key.CdrKey.answered20to60];
    answeredAfter60 = json[key.CdrKey.answeredAfter60];
    if (alsoCdrFiles) {
      cdrFiles = json[key.CdrKey.cdrFiles] as List<String>;
    }
    inboundBillSeconds = json[key.CdrKey.inboundBillSeconds];
    longCalls = json[key.CdrKey.longCalls];
    outbound = json[key.CdrKey.outbound];
    shortCalls = json[key.CdrKey.shortCalls];
    uid = json[key.CdrKey.uid];
  }

  /// Add [other] to this. Retains the [uid] of this.
  void add(CdrAgentSummary other, {bool alsoCdrFiles: true}) {
    answered10 += other.answered10;
    answered10To20 += other.answered10To20;
    answered20To60 += other.answered20To60;
    answeredAfter60 += other.answeredAfter60;
    if (alsoCdrFiles) {
      cdrFiles.addAll(other.cdrFiles);
    }
    inboundBillSeconds += other.inboundBillSeconds;
    longCalls += other.longCalls;
    outbound += other.outbound;
    shortCalls += other.shortCalls;
  }

  int get answered =>
      answered10 + answered10To20 + answered20To60 + answeredAfter60;

  Map<String, dynamic> toJson() => <String, dynamic>{
        key.CdrKey.answered10: answered10,
        key.CdrKey.answered10to20: answered10To20,
        key.CdrKey.answered20to60: answered20To60,
        key.CdrKey.answeredAfter60: answeredAfter60,
        key.CdrKey.cdrFiles: cdrFiles,
        key.CdrKey.inboundBillSeconds: inboundBillSeconds,
        key.CdrKey.longCalls: longCalls,
        key.CdrKey.outbound: outbound,
        key.CdrKey.shortCalls: shortCalls,
        key.CdrKey.uid: uid
      };
}

/// A summary of how calls have been handled for a specific reception.
///
/// Contains info about cost, amount, fails and agents.
class CdrSummary {
  List<CdrAgentSummary> agentSummaries = new List<CdrAgentSummary>();
  List<String> cdrFiles = new List<String>();
  int inboundNotNotified = 0; // Amount of inbound calls not notified to agents
  int notifiedNotAnswered = 0; // Calls notified but not answered by an agent
  int outBoundBillSeconds = 0; // Accumulated amount of outbound seconds
  double outboundCost = 0.0; // Accumulated cost of outbound calls
  int outboundByPbx = 0; // Amount of outbound calls made by voicemail
  int rid = 0; // The reception id

  /// Default constructor.
  CdrSummary();

  /// JSON constructor.
  CdrSummary.fromJson(Map<dynamic, dynamic> json, {bool alsoCdrFiles: true}) {
    (json[key.CdrKey.agentSummaries] as List<Map<String,String>>)
        .forEach((Map<dynamic, dynamic> value) {
      agentSummaries
          .add(new CdrAgentSummary.fromJson(value, alsoCdrFiles: alsoCdrFiles));
    });
    if (alsoCdrFiles) {
      cdrFiles = json[key.CdrKey.cdrFiles] as List<String>;
    }
    inboundNotNotified = json[key.CdrKey.inboundNotNotified];
    notifiedNotAnswered = json[key.CdrKey.notifiedNotAnswered];
    outBoundBillSeconds = json[key.CdrKey.outboundBillSeconds];
    outboundCost = json[key.CdrKey.outboundCost];
    outboundByPbx = json[key.CdrKey.outboundByPbx];
    rid = json[key.CdrKey.rid];
  }

  /// Add [other] to this. Retains the [rid] of this.
  void add(CdrSummary other, {bool alsoCdrFiles: true}) {
    for (CdrAgentSummary agentSummary in other.agentSummaries) {
      final CdrAgentSummary found = getAgentSummary(agentSummary.uid);
      found.add(agentSummary, alsoCdrFiles: alsoCdrFiles);
      setAgentSummary(found);
    }
    if (alsoCdrFiles) {
      cdrFiles.addAll(other.cdrFiles);
    }
    inboundNotNotified += other.inboundNotNotified;
    notifiedNotAnswered += other.notifiedNotAnswered;
    outBoundBillSeconds += other.outBoundBillSeconds;
    outboundByPbx += other.outboundByPbx;
    outboundCost += other.outboundCost;
  }

  /// Return the [uid] [CdrAgentSummary].
  ///
  /// If none exists, return a new [CdrAgentSummary] object.
  CdrAgentSummary getAgentSummary(int uid) =>
      agentSummaries.firstWhere((CdrAgentSummary as) => as.uid == uid,
          orElse: () => new CdrAgentSummary()..uid = uid);

  /// Return a list comprised of all the CDR files for this summary.
  List<String> getAllCdrFiles() {
    final List<String> cdr = new List<String>()..addAll(cdrFiles);
    for (CdrAgentSummary a in agentSummaries) {
      cdr.addAll(a.cdrFiles);
    }
    return cdr;
  }

  /// Add the [agentSummary] object to the [CdrSummary].
  void setAgentSummary(CdrAgentSummary agentSummary) {
    agentSummaries
        .removeWhere((CdrAgentSummary old) => old.uid == agentSummary.uid);
    agentSummaries.add(agentSummary);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        key.CdrKey.agentSummaries: agentSummaries,
        key.CdrKey.cdrFiles: cdrFiles,
        key.CdrKey.inboundNotNotified: inboundNotNotified,
        key.CdrKey.notifiedNotAnswered: notifiedNotAnswered,
        key.CdrKey.outboundBillSeconds: outBoundBillSeconds,
        key.CdrKey.outboundByPbx: outboundByPbx,
        key.CdrKey.outboundCost: outboundCost,
        key.CdrKey.rid: rid
      };

  @override
  String toString() => '''rid: $rid
Answered total: ${agentSummaries.fold(0, (int acc, CdrAgentSummary a) => acc + a.answered)}
Answered 0-10: ${agentSummaries.fold(0, (int acc, CdrAgentSummary a) => acc + a.answered10)}
Answered 10-20: ${agentSummaries.fold(0, (int acc, CdrAgentSummary a) => acc + a.answered10To20)}
Answered 20-60: ${agentSummaries.fold(0, (int acc, CdrAgentSummary a) => acc + a.answered20To60)}
Answered +60: ${agentSummaries.fold(0, (int acc, CdrAgentSummary a) => acc + a.answeredAfter60)}
inboundBillSeconds: ${agentSummaries.fold(0, (int acc, CdrAgentSummary a) => acc + a.inboundBillSeconds)}
longCalls: ${agentSummaries.fold(0, (int acc, CdrAgentSummary a) => acc + a.longCalls)}
outbound: ${agentSummaries.fold(0, (int acc, CdrAgentSummary a) => acc + a.outbound)}
shortCalls: ${agentSummaries.fold(0, (int acc, CdrAgentSummary a) => acc + a.shortCalls)}
inboundNotNofified: $inboundNotNotified
notifiedNotAnswered: $notifiedNotAnswered
outboundBillSeconds: $outBoundBillSeconds
outboundByPbx: $outboundByPbx
outboundCost: $outboundCost''';
}
