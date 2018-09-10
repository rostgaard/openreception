part of ort.benchmark;

Future _sleep(int milliseconds) =>
    Future.delayed(Duration(milliseconds: milliseconds));

abstract class Call {
  static final Logger log = Logger('$_namespace.Call');
  static int handled = 0;

  /// Convenience function covering the scenario of a receptionist requesting a
  /// call, also covering the possible alternate scenarios that may occur.
  static Future _receptionistRequestsCall(Receptionist r) async {
    bool callAvailable(model.Call call) =>
        call.assignedTo == model.User.noId && !call.locked;

    await Future.doWhile(() async {
      final Iterable<model.Call> calls = await r.callFlowControl.callList();
      if (calls.isEmpty) {
        log.info('$r detected no more calls. Aborting.');
        return false;
      }

      final model.Call nextCall =
          calls.firstWhere(callAvailable, orElse: () => model.Call.noCall);

      if (nextCall == model.Call.noCall) {
        return true;
      }

      try {
        final model.Call activeCall =
            await r.pickup(nextCall, waitForEvent: true);
        log.info('$r got $activeCall, hangin it up after 100ms');
        await Future.delayed(Duration(milliseconds: 100));
        await r.hangUp(activeCall);
        await r.waitForPhoneHangup();
        handled++;
      } on Conflict {
        log.fine('$nextCall is locked, trying again later.');
      } on NotFound {
        log.fine('$nextCall is hung up, trying the next one.');
      } on Forbidden {
        log.fine('$nextCall is already assigned, trying the next one.');
      } on ServerError {
        await r.waitForPhoneHangup();
      }

      await _sleep(100);
      return true;
    });
  }

  /// Scenario of a call rush. Every available customer will originate an inbound
  /// call, and every available receptionist will race the others in trying to
  /// acquire it.
  static Future callRush(
      Iterable<model.ReceptionDialplan> rdps,
      Iterable<Receptionist> receptionists,
      Iterable<Customer> customers) async {
    Receptionist callWaiter = receptionists.first;

    Future waitForListToEmpty() => Future.doWhile((() => Future.delayed(
        Duration(milliseconds: 1000),
        () => callWaiter.callFlowControl
            .callList()
            .then((Iterable<model.Call> calls) => calls.length != 0))));

    // Each customer spawns a call
    // The delays are need to avoid FreeSWITCH standard call-per-second
    // restriction. The standard is 20/s.
    int spawned = 0;
    log.info('Waiting for call list to spawn');
    await Future.wait(customers.map((Customer customer) async {
      await Future.forEach(rdps, (rdp) async {
        await customer.dial(rdp.extension);
        spawned++;
        await Duration(milliseconds: 200);
      });
      await Duration(milliseconds: 200);
    }));

    await Future.doWhile(() async {
      final Iterable<model.Call> calls =
          await callWaiter.callFlowControl.callList();
      log.info('${calls.length} <= $spawned');

      if (calls.length < spawned) {
        await Duration(seconds: 1);
        return true;
      }
      return false;
    }).timeout(Duration(seconds: 10));

    handled = 0;
    log.info('$spawned calls spawned filled, starting to handle the calls');
    await Future.wait(
        receptionists.map((Receptionist r) => _receptionistRequestsCall(r)));
    log.info('Wait for call list to empty');
    await waitForListToEmpty().timeout(Duration(seconds: 10));
    log.info('Receptionists processed $handled calls of $spawned spawned');
    expect(handled, equals(spawned));

    log.info('Test done');
  }
}
