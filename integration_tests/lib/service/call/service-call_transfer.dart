part of ort.service.call;

abstract class Transfer {
  static Logger log = Logger('$_namespace.CallFlowControl.Transfer');

  static Future transferParkedInboundCall(
      Receptionist receptionist,
      Customer caller,
      Customer callee,
      model.OriginationContext context) async {
    log.info('Disable autoanswer for ${callee.name}');
    await callee.autoAnswer(false);
    log.info('Customer ${caller} dials ${context.dialplan}');
    await caller.dial(context.dialplan);
    log.info('Receptionist $receptionist waits for call.');
    final model.Call inboundCall = await receptionist.huntNextCall();
    log.info('$receptionist got call $inboundCall');
    await receptionist.waitForInboundCall();
    receptionist.eventStack.clear();
    log.info('$receptionist parks call $inboundCall.');
    await receptionist.park(inboundCall, waitForEvent: true);

    log.info('$receptionist awaits phone disconnect.');
    await receptionist.waitForPhoneHangup();

    receptionist.eventStack.clear();
    final model.Call outboundCall =
        await receptionist.originate(callee.extension, context);
    log.info('Outbound call: $outboundCall');

    await callee.waitForInboundCall();
    await callee.pickupCall();
    log.info('$receptionist picked up outbound call: $outboundCall');
    expect(outboundCall.orRid, equals(context.receptionId));
    expect(outboundCall.assignedTo, equals(receptionist.user.id));

    log.info('$receptionist transfers call $outboundCall to $inboundCall.');
    await receptionist.transferCall(inboundCall, outboundCall);
    log.info('$receptionist transferred call $outboundCall to $inboundCall.');

    await receptionist.waitForTransfer(inboundCall.id);

    log.info('Waiting for ${receptionist} phone to hang up');
    await receptionist.waitForPhoneHangup();

    log.info('Expecting both caller and callee to have an active call');
    expect(caller.currentCall, isNotNull);
    expect(callee.currentCall, isNotNull);
    log.info('Caller ${caller} hangs up');
    await caller.hangupAll();
    log.info('Waiting around for 100ms to avoid race conditions');
    await Future.delayed(Duration(milliseconds: 100));
    log.info('Caller ${caller} waits for hang up');
    await caller.waitForHangup();
    log.info('Callee ${callee} waits for hang up');
    await callee.waitForHangup();
    log.info('Test complete.');
  }

  static Future transferParkedOutboundCall(
      Receptionist receptionist,
      Customer caller,
      Customer callee,
      model.OriginationContext context) async {
    log.info('Disable autoanswer for ${callee.name}');
    await callee.autoAnswer(false);

    log.info('Customer ${caller.name} dials ${context.dialplan}');
    await caller.dial(context.dialplan);
    log.info('${receptionist} waits for call.');

    final model.Call inboundCall = await receptionist.huntNextCall();
    await receptionist.waitForInboundCall();
    await receptionist.waitForPickup(inboundCall.id);
    receptionist.eventStack.clear();
    log.info('${receptionist} parks call $inboundCall.');
    await receptionist.park(inboundCall, waitForEvent: true);
    await receptionist.waitForPhoneHangup();
    receptionist.eventStack.clear();
    final model.Call outboundCall =
        await receptionist.originate(callee.extension, context);
    log.info('Outbound call: $outboundCall');
    expect(outboundCall.orRid, equals(context.receptionId));
    expect(outboundCall.assignedTo, equals(receptionist.user.id));
    await callee.waitForInboundCall();
    await callee.pickupCall();
    await receptionist.waitForPickup(outboundCall.id);
    log.info('${receptionist} picked up outbound call: $outboundCall');

    log.info('$receptionist parks call $outboundCall.');
    await receptionist.park(outboundCall, waitForEvent: true);
    await receptionist.waitForPhoneHangup();
    receptionist.eventStack.clear();
    log.info('$receptionist pickup the inbound call $inboundCall again');
    await receptionist.pickup(inboundCall).then((model.Call receivedCall) {
      expect(inboundCall.id, equals(receivedCall.id));
      log.info('Receptionist ${receptionist} got call $receivedCall');
      return;
    });
    await receptionist.waitForInboundCall();
    await receptionist.waitForPickup(inboundCall.id);
    receptionist.eventStack.clear();
    log.info('$receptionist transfers call $inboundCall to $outboundCall.');
    await receptionist.transferCall(outboundCall, inboundCall);

    log.info('$receptionist transferred call $inboundCall to $outboundCall.');

    await receptionist.waitForTransfer(inboundCall.id);

    log.info('Waiting for $receptionist phone to hang up');
    await receptionist.waitForPhoneHangup();

    log.info('Caller ${caller} hangs up');
    caller.hangupAll();

    log.info('Waiting around for 100ms to avoid race conditions');
    await Future.delayed(Duration(milliseconds: 100));

    log.info('Caller ${caller} waits for hang up');
    await caller.waitForHangup();

    log.info('Callee ${callee} waits for hang up');
    await callee.waitForHangup();
    log.info('Test complete.');
  }

  /**
   * Asserts that the call list is of correct length both before and after a
   * transfer.
   */
  static Future inboundCallListLength(
      Receptionist receptionist,
      Customer caller,
      Customer callee,
      model.OriginationContext context) async {
    log.info('Disable autoanswer for ${callee}');
    await callee.autoAnswer(false);

    log.info('${caller} (caller) dials ${context.dialplan}');
    await caller.dial(context.dialplan);

    log.info('${receptionist} tries to pick up next call');
    final model.Call inboundCall = await receptionist.huntNextCall();
    log.info('${receptionist} got call $inboundCall');

    receptionist.eventStack.clear();
    log.info('${receptionist} parks call $inboundCall.');
    await receptionist.park(inboundCall, waitForEvent: true);
    await receptionist.waitForPhoneHangup();
    receptionist.eventStack.clear();
    log.info('Checking call list length');

    expect((await receptionist.callFlowControl.callList()).length, equals(1));

    final model.Call outboundCall =
        await receptionist.originate(callee.extension, context);
    await callee.waitForInboundCall();
    log.info('Checking call list length');
    expect((await receptionist.callFlowControl.callList()).length, equals(2));

    await callee.pickupCall();
    log.info('Checking call list length');
    expect((await receptionist.callFlowControl.callList()).length, equals(2));

    await receptionist
        .waitForPickup(outboundCall.id)
        .then((event.CallPickup event) {
      log.info('${receptionist} picked up outbound call: $outboundCall');
      expect(outboundCall.assignedTo, equals(receptionist.user.id));
    });
    log.info('${receptionist} parks call $outboundCall.');
    await receptionist.park(outboundCall, waitForEvent: true);
    await receptionist.waitForPhoneHangup();

    log.info('Checking call list length');
    expect((await receptionist.callFlowControl.callList()).length, equals(2));
    receptionist.eventStack.clear();

    log.info('${receptionist} pickup the inbound call $inboundCall again');
    await receptionist.pickup(inboundCall).then((model.Call receivedCall) {
      expect(inboundCall.id, equals(receivedCall.id));
      log.info('${receptionist} got call $receivedCall');
    });
    await receptionist.waitForInboundCall();
    await receptionist.waitForPickup(inboundCall.id);
    receptionist.eventStack.clear();
    log.info('${receptionist} transfers call $inboundCall to $outboundCall.');
    await receptionist.transferCall(outboundCall, inboundCall);
    log.info('$receptionist transferred call $inboundCall to $outboundCall.');
    await receptionist.waitForTransfer(outboundCall.id);
    await receptionist.waitForTransfer(inboundCall.id);
    log.info('Waiting for ${receptionist} phone to hang up');
    await receptionist.waitForPhoneHangup();
    log.info('Checking call list length');
    expect((await receptionist.callFlowControl.callList()).length, equals(2));
    log.info('Caller ${caller} hangs up');
    await caller.hangupAll();
    log.info('Waiting around for 100ms to avoid race conditions');
    await Future.delayed(Duration(milliseconds: 100));
    log.info('Caller ${caller} waits for hang up');
    await caller.waitForHangup();
    log.info('Callee ${callee} waits for hang up');
    await callee.waitForHangup();
    log.info('Checking call list length');
    expect((await receptionist.callFlowControl.callList()).length, equals(0));
    log.info('Test complete.');
  }
}
