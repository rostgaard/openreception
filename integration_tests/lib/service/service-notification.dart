part of ort.service;

abstract class NotificationService {
  static final Logger _log = Logger('$_namespace.Notification');

  /**
   *
   */
  static Future eventBroadcast(Iterable<service.NotificationSocket> sockets,
      service.NotificationService service) async {
    final int uid = 99;
    final int modUid = 88;
    final event.UserChange testEvent = event.UserChange.update(uid, modUid);

    bool isExpectedEvent(event.Event e) =>
        e is event.UserChange &&
        e.isUpdate &&
        e.uid == uid &&
        e.modifierUid == modUid;

    Future<Iterable> eventSubScriptions = Future.wait(
        sockets.map((ns) => ns.onEvent.firstWhere(isExpectedEvent)));

    await service.broadcastEvent(testEvent);

    await eventSubScriptions.timeout(threeSeconds);
  }

  /**
   *
   */
  static Future connectionStateList(
      Iterable<ServiceAgent> sas, service.NotificationService service) async {
    bool userHasConnection(
            ServiceAgent sa, Iterable<model.ClientConnection> connections) =>
        connections
            .where((model.ClientConnection connection) =>
                connection.userID == sa.user.id &&
                connection.connectionCount > 0)
            .length >
        0;

    final Iterable<model.ClientConnection> connections =
        await service.clientConnections();
    expect(sas.every((s) => userHasConnection(s, connections)), isTrue);
    expect(connections.every((model.ClientConnection conn) => conn.userID > 0),
        isTrue);
  }

  /**
   *
   */
  static Future connectionState(Iterable<ServiceAgent> sas,
      service.NotificationService notificationService) async {
    await Future.forEach(sas, (ServiceAgent s) async {
      final model.ClientConnection conn =
          await notificationService.clientConnection(s.user.id);

      expect(conn.connectionCount, greaterThan(0));
      expect(conn.userID, equals(s.user.id));
    });
  }

  /**
   *
   */
  static Future eventSend(Iterable<ServiceAgent> sas,
      service.NotificationService notificationService) async {
    // This test make no sense with only two participants
    expect(sas.length, greaterThan(2));

    Iterable recipients = sas.take(2);

    Iterable<int> recipientUids = recipients.map((s) => s.user.id);

    final event.Event sentEvent =
        event.UserChange.update(sas.first.user.id, sas.last.user.id);

    int completed = 0;

    Completer comp = Completer();
    List<Error> errors = [];
    sas.forEach((sa) async {
      Completer c = Completer();

      Future.delayed(Duration(milliseconds: 500), () {
        if (!c.isCompleted) {
          if (recipientUids.contains(sa.user.id)) {
            errors.add(StateError('user: ${sa.user.toJson()} expected to'
                ' receive message, but did not'));
          }
          c.complete();
        }
      });

      (await sa.notifications).listen((e) {
        if (e is event.UserChange && e.isUpdate) {
          if (!recipientUids.contains(sa.user.id)) {
            errors.add(StateError('user: ${sa.user.toJson()} not expected to'
                ' receive message, but did'));
          }
          c.complete();
        }
      });

      await c.future;
      completed++;
      if (completed == sas.length) {
        comp.complete();
      }
    });

    await notificationService.send(recipientUids, sentEvent);

    _log.info('Waiting for events');

    await comp.future;
    expect(errors, isEmpty);
  }
}
