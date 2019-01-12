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

library usermon;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
// import 'package:logging/logging.dart';
// import 'package:orf/service.dart' as service;
import 'package:orf/service-html.dart' as transport;

import 'package:usermon/view.dart' as view;

const _json = const JsonCodec();

class AgentStat {
  int uid;
  String username;
  int callsAnswered;

  static AgentStat decode(Map map) => new AgentStat()
    ..uid = map['uid']
    ..username = map['name']
    ..callsAnswered = map['answered'];

  String toString() => 'uid:$uid, userName:$username, calls:$callsAnswered';
}

class CallSummary {
  int totalCalls = 0;
  int callsAnsweredWithin20s = 0;
  int callsUnAnswered = 0;
  int callWaitingMoreThanOneMinute = 0;
  int talkTime = 0;
  List<AgentStat> agentSummary = [];

  String toString() => 'totalCalls:$totalCalls, '
      'below20s:$callsAnsweredWithin20s, '
      'oneminute:$callWaitingMoreThanOneMinute, '
      'talktime:$talkTime, '
      'unanswered:$callsUnAnswered,'
      'agentSummary: ${agentSummary.join(', ')}';

  static CallSummary fromJson(Map map) => new CallSummary()
    ..totalCalls = map['totalCalls']
    ..callsAnsweredWithin20s = map['below20s']
    ..callWaitingMoreThanOneMinute = map['oneminuteplus']
    ..callsUnAnswered = map['unanswered']
    ..agentSummary =
        new List<AgentStat>.from(map['agentSummary'].map(AgentStat.decode));
}

TableRowElement _userRow(AgentStat summary, int callCount) {
  double percent = (summary.callsAnswered / callCount) * 100;

  final SpanElement _messageElement = new SpanElement()
    ..classes.add('message')
    ..text = '[${summary.callsAnswered}] (${percent.toStringAsFixed(1)})%'
    ..style.fontWeight = 'bold';

  ///Setup visual model.
  return new TableRowElement()
    ..style.width = '100%'
    ..children = [
      new TableCellElement()
        ..style.width = '100%'
        ..children = [
          new DivElement()..classes.add('status'),
          new TableCellElement()
            ..classes.add('name')
            ..text = summary.username,
          new TableCellElement()
            ..children = [
              new DivElement()
                ..classes.add('stick')
                ..children = [
                  _messageElement,
                  new ImageElement()
                    ..src = 'img/stick_left.png'
                    ..classes.add('stick_left'),
                  new ImageElement()
                    ..src = 'img/stick_right.png'
                    ..classes.add('stick_right')
                ]
            ]
        ]
    ];
}

Map<int, view.AgentInfo> _userDataView = {};

Future main() async {
  new Timer.periodic(new Duration(seconds: 1), (_) async {
    final client = new transport.Client();
    CallSummary cs = CallSummary.fromJson(_json.decode(await client
        .get(Uri.parse('http://orm.responsum.dk:8080/agentstats'))));

    final int totalcalls =
        cs.agentSummary.fold(0, (sum, AgentStat as) => sum + as.callsAnswered);
    double percentage = (cs.callsAnsweredWithin20s / totalcalls) * 100;

    querySelector('#user-list')
      ..style.width = '100%'
      ..children = ([]
        ..addAll(cs.agentSummary.map((astat) => _userRow(astat, totalcalls))));

    querySelector('#calls-more-than-60s').text =
        cs.callWaitingMoreThanOneMinute.toString();

    querySelector('#unanswered-calls').text = cs.callsUnAnswered.toString();
    querySelector('#total-calls').text = totalcalls.toString();

    querySelector('#calls-less-than-20s').text = '${percentage.toInt()}%';
  });
}
