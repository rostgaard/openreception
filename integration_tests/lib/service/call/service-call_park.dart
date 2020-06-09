part of ort.service.call;

abstract class CallPark {
  static Logger log = Logger('$_namespace.CallFlowControl.Park');

  /// Tests if call unpark events occur when a call is being hung up while
  /// in a parking lot.
  static Future unparkEventFromHangup(model.ReceptionDialplan rdp,
      Receptionist receptionist, Customer caller) async {
    log.info('$caller dials the reception at ${rdp.extension}');
    await caller.dial(rdp.extension);

    final model.Call targetedCall = await receptionist.huntNextCall();

    log.info('Receptionist parks call $targetedCall');
    model.Call parkedCall =
        await receptionist.park(targetedCall, waitForEvent: true);
    receptionist.waitForPhoneHangup();
    expect(parkedCall.assignedTo, equals(receptionist.user.id));
    expect(parkedCall.state, equals(model.CallState.parked_));

    log.info('Caller hangs up all calls');
    await caller.hangupAll();
    log.info('Receptionist waits for the phone to hang up');
    await receptionist.waitForPhoneHangup();
    log.info('Receptionist expects call to unpark');
    await receptionist.waitForUnpark(parkedCall.id);
    log.info('Receptionist expects call to hang up');
    await receptionist.waitForHangup(parkedCall.id);
  }

  /// Validates that the /call/park interface indeed returns 404 when the
  /// call is no longer present.
  static Future parkNonexistingCall(
      model.ReceptionDialplan rdp, Receptionist receptionist) async {
    await expect(receptionist.callFlowControl.park('null'),
        throwsA(const TypeMatcher<NotFound>()));
  }

  /// Tests a park pickup loop on a known call.
  static Future explicitParkPickup(model.ReceptionDialplan rdp,
      Receptionist receptionist, Customer caller) async {
    log.info('Caller dials the reception at ${rdp.extension}');
    await caller.dial(rdp.extension);
    log.info('Receptionist tries to hunt down the next call');
    model.Call targetedCall = await receptionist.huntNextCall();
    receptionist.eventStack.clear();
    log.info('Receptionist parks call $targetedCall');
    model.Call parkedCall =
        await receptionist.park(targetedCall, waitForEvent: true);
    receptionist.waitForPhoneHangup();

    expect(parkedCall.assignedTo, equals(receptionist.user.id));
    expect(parkedCall.state, equals(model.CallState.parked_));

    receptionist.eventStack.clear();
    log.info('Receptionist pickup call $targetedCall again');
    parkedCall = await receptionist.pickup(targetedCall, waitForEvent: true);

    expect(parkedCall.assignedTo, equals(receptionist.user.id));
    expect(parkedCall.state, equals(model.CallState.speaking_));

    receptionist.eventStack.clear();

    log.info('Receptionist parks call $targetedCall once again');
    parkedCall = await receptionist.park(targetedCall, waitForEvent: true);
    receptionist.waitForPhoneHangup();

    expect(parkedCall.assignedTo, equals(receptionist.user.id));
    expect(parkedCall.state, equals(model.CallState.parked_));

    receptionist.eventStack.clear();

    log.info('Receptionist pickup call $targetedCall last time');
    parkedCall = await receptionist.pickup(targetedCall, waitForEvent: true);

    expect(parkedCall.assignedTo, equals(receptionist.user.id));
    expect(parkedCall.state, equals(model.CallState.speaking_));

    log.info('Caller hangs up all calls');
    await caller.hangupAll();
    log.info('Receptionist waits for the phone to hang up');
    await receptionist.waitForPhoneHangup();
    log.info('Receptionist expects call to hang up');
    await receptionist.waitForHangup(parkedCall.id);
  }

  /// Tests the call list length.
  static Future parkCallListLength(model.ReceptionDialplan rdp,
      Receptionist receptionist, Customer caller) async {
    log.info('Caller dials the reception at ${rdp.extension}');
    await caller.dial(rdp.extension);
    log.info('Receptionist tries to hunt down the next call');
    model.Call targetedCall = await receptionist.huntNextCall();

    log.info('Receptionist parks call $targetedCall');
    model.Call parkedCall =
        await receptionist.park(targetedCall, waitForEvent: true);
    receptionist.waitForPhoneHangup();
    expect(parkedCall.assignedTo, equals(receptionist.user.id));
    expect(parkedCall.state, equals(model.CallState.parked_));

    log.info('Checking call list length');

    final Iterable calls = await receptionist.callFlowControl.callList();
    expect(calls.length, equals(1));
    log.info('Test succeeded');
  }
}
