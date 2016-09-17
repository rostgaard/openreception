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

library orf.test;

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:orf/bus.dart';
import 'package:orf/dialplan_tools.dart' as dpTools;
import 'package:orf/event.dart' as event;
import 'package:orf/model.dart' as model;
import 'package:orf/resource.dart' as resource;
import 'package:test/test.dart';
import 'package:xml/xml.dart' as xml;
import 'src/log_setup.dart';

part 'src/bus.dart';
part 'src/dialplan_tools.dart';
part 'src/event-calendar_change.dart';
part 'src/event-message_change.dart';
part 'src/event.dart';
part 'src/model/dialplan/model-action.dart';
part 'src/model/dialplan/model-enqueue.dart';
part 'src/model/dialplan/model-hour_action.dart';
part 'src/model/dialplan/model-ivr_entry.dart';
part 'src/model/dialplan/model-ivr_menu.dart';
part 'src/model/dialplan/model-named_extension.dart';
part 'src/model/dialplan/model-notify.dart';
part 'src/model/dialplan/model-opening_hour.dart';
part 'src/model/dialplan/model-playback.dart';
part 'src/model/dialplan/model-reception_dialplan.dart';
part 'src/model/dialplan/model-reception_transfer.dart';
part 'src/model/dialplan/model-ring_tone.dart';
part 'src/model/dialplan/model-transfer.dart';
part 'src/model/dialplan/model-voicemail.dart';
part 'src/model/model-agent_history.dart';
part 'src/model/model-base_contact.dart';
part 'src/model/model-calendar_entry.dart';
part 'src/model/model-calendar_entry_change.dart';
part 'src/model/model-call.dart';
part 'src/model/model-caller_info.dart';
part 'src/model/model-client_configuration.dart';
part 'src/model/model-client_connection.dart';
part 'src/model/model-message.dart';
part 'src/model/model-message_context.dart';
part 'src/model/model-message_endpoint.dart';
part 'src/model/model-message_filter.dart';
part 'src/model/model-message_queue_entry.dart';
part 'src/model/model-organization.dart';
part 'src/model/model-peer_account.dart';
part 'src/model/model-phone_number.dart';
part 'src/model/model-reception.dart';
part 'src/model/model-reception_attributes.dart';
part 'src/model/model-user.dart';
part 'src/model/model-user_status.dart';
part 'src/resource/resource-authentication.dart';
part 'src/resource/resource-calendar.dart';
part 'src/resource/resource-call_flow_control.dart';
part 'src/resource/resource-cdr.dart';
part 'src/resource/resource-config.dart';
part 'src/resource/resource-contact.dart';
part 'src/resource/resource-endpoint.dart';
part 'src/resource/resource-message.dart';
part 'src/resource/resource-notification.dart';
part 'src/resource/resource-organization.dart';
part 'src/resource/resource-reception.dart';
//import '../lib/service.dart'  as Service;
//part 'src/model-channel.dart';
//part 'src/model-contact_filter.dart';
//part 'src/model-message_header.dart';
//part 'src/model-peer.dart';
//part 'src/model-template.dart';
//part 'src/model-template_email.dart';

void main() {
  setupLogging();

  _testModelAction();
  _testModelEnqueue();
  _testModelHourAction();
  _testModelIvrEntry();
  _testModelIvrMenu();
  _testModelNamedExtension();
  _testModelNotify();
  _testModelOpeningHour();
  _testModelPlayback();
  _testModelReceptionDialplan();
  _testModelReceptionTransfer();
  _testModelRingtone();
  _testModelTransfer();
  _testModelVoicemail();

  _testBus();
  _testDialplanTools();

  _testEvent();
  _testEventMessageChange();
  _testEventCalendarChange();

  _testModelAgentStatistics();
  _testModelBaseContact();
  _testModelCalendarEntry();
  _testModelCalendarCommit();
  _testModelCall();
  _testModelClientConfiguration();
  _testModelClientConnection();
  _testModelReceptionAttributes();

  _testModelOrganization();
  _testModelReception();
  _testModelMessage();
  _testModelCallerInfo();
  _testModelMessageContext();
  _testModelMessageFilter();
  _testModelMessageQueueEntry();
  _testModelMessageEndpoint();

  _testModelPeerAccount();
  _testModelPhoneNumber();
  _testModelUserStatus();
  _testModelUser();

  _testResourceAuthentication();
  _testResourceCalendar();
  _testResourceCallFlowControl();
  _testResourceCDR();
  _testResourceConfig();
  _testResourceContact();
  _testResourceEndpoint();
  _testResourceMessage();
  _testResourceNotification();
  _testResourceReception();
}
