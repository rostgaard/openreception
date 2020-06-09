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

library orf.model.monitoring;

import 'package:logging/logging.dart';
import 'package:orf/event.dart' as _event;
import 'package:orf/model.dart';
import 'package:orf/util.dart' as util;

part 'model/monitoring/model-active_call.dart';
part 'model/monitoring/model-agent_stat_summary.dart';
part 'model/monitoring/model-daily_report.dart';
part 'model/monitoring/model-daily_summary.dart';
part 'model/monitoring/model-historic_call.dart';
part 'model/monitoring/model-message_history.dart';
part 'model/monitoring/model-user_state_history.dart';

final String _callOfferKey = new _event.CallOffer(null).eventName;
final String _callStateKey = new _event.CallStateChanged(null).eventName;
final String _callPickupKey = new _event.CallPickup(null).eventName;
final String _callHangupKey = new _event.CallHangup(null).eventName;
final String _callTransferKey = new _event.CallTransfer(null).eventName;

abstract class _Key {
  static const String uid = 'uid';

  static const String inbound = 'inbound';
  static const String outbound = 'outbound';
  static const String inboundHandleTime = 'inboundDuration';
  static const String outboundHandleTime = 'outboundDuration';

  static const String below20s = 'below20s';
  static const String oneminuteplus = 'oneminuteplus';
  static const String unanswered = 'unanswered';
  static const String agent = 'agents';

  static const String messageCount = 'messageCount';
  static const String pauseDuration = 'pauseDuration';
}
