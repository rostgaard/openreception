library ort.service;

import 'dart:async';

import 'package:esl/esl.dart' as esl;
import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/exceptions.dart' as storage;
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;
import 'package:orf/storage.dart' as storage;
import 'package:ort/config.dart';
import 'package:ort/support.dart';
import 'package:phonio/phonio.dart' as phonio;
import 'package:test/test.dart';

export 'package:ort/service/service-call.dart';

part 'rest/src/dialplan_deployment.dart';
part 'rest/src/reception_dialplan_store.dart';
part 'rest/src/service-active_recording.dart';
part 'service/service-auth.dart';
part 'service/service-calendar.dart';
part 'service/service-config.dart';
part 'service/service-contact.dart';
part 'service/service-dialplan.dart';
part 'service/service-dialplan_deployment.dart';
part 'service/service-message.dart';
part 'service/service-message_queue.dart';
part 'service/service-notification.dart';
part 'service/service-organization.dart';
part 'service/service-peer.dart';
part 'service/service-peeraccount.dart';
part 'service/service-reception.dart';
part 'service/service-state_reload.dart';
part 'service/service-user.dart';
part 'service/service-user_state.dart';

const String _namespace = 'test.service';

final Duration threeSeconds = new Duration(seconds: 3);
