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

library ors.controller.client_call_notifier;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/service.dart' as service;

/**
 * Controller class that is responsible for broadcasting an event to all
 * connected clients.
 */
class ClientNotifier {
  final StreamSubscription subscription;

  factory ClientNotifier(service.NotificationService notificationServer,
      Stream<event.Event> eventStream) {
    Logger _log = new Logger('controller.ClientNotifier');

    void logError(dynamic error, StackTrace stackTrace) =>
        _log.shout('Failed to dispatch event', error, stackTrace);
    StreamSubscription subscription;
    subscription = eventStream.listen((e) async {
      await notificationServer.broadcastEvent(e);
    }, onError: logError, onDone: () => subscription.cancel());

    return new ClientNotifier._internal(subscription);
  }

  ClientNotifier._internal(this.subscription);

  Future close() async {
    await subscription.cancel();
  }
}
