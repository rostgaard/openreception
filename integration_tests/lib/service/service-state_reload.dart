part of ort.service;

abstract class StateReload {
  static Logger log = Logger('$_namespace.CallFlowControl.UserState');

  /// Validates that the content of [list1] and [list2] is the same.
  static void _validateCallLists(
      Iterable<model.Call> list1, Iterable<model.Call> list2) {
    log.info('List 1:\n  ${list1.map((c) => c.toJson()).join('\n  ')}');
    log.info('List 2:\n  ${list2.map((c) => c.toJson()).join('\n  ')}');

    expect(list1.length, equals(list2.length));

    list2.forEach((model.Call updatedCall) {
      model.Call originalCall =
          list1.firstWhere((model.Call c) => c.id == updatedCall.id);

      expect(originalCall.toJson(), equals(updatedCall.toJson()));
      expect(
          originalCall.arrivalTime
              .difference(updatedCall.arrivalTime)
              .inMilliseconds
              .abs(),
          lessThan(1000));
      expect(originalCall.assignedTo, equals(updatedCall.assignedTo));
      expect(originalCall.bLeg, equals(updatedCall.bLeg));
      expect(originalCall.callerId, equals(updatedCall.callerId));
      expect(originalCall.channel, equals(updatedCall.channel));
      expect(originalCall.orCid, equals(updatedCall.orCid));
      expect(originalCall.destination, equals(updatedCall.destination));
      expect(originalCall.greetingPlayed, equals(updatedCall.greetingPlayed));
      expect(originalCall.id, equals(updatedCall.id));
      expect(originalCall.inbound, equals(updatedCall.inbound));
      expect(originalCall.locked, equals(updatedCall.locked));
      expect(originalCall.orRid, equals(updatedCall.orRid));
      expect(originalCall.state, equals(updatedCall.state));
    });
  }

  /**
   *
   */
  static Future inboundUnansweredCall(model.OriginationContext context,
      Receptionist receptionist, Customer caller) async {
    log.info('Caller dials the reception at ${context.dialplan}');
    await caller.dial(context.dialplan);

    log.info('Waiting for the call to be queued');
    final call = await receptionist.nextOfferedCall();

    await receptionist.waitForQueueJoin(call.id);
    log.info('Fetching call list');
    final Iterable<model.Call> originalCallQueue =
        await receptionist.callFlowControl.callList();
    await receptionist.callStateReload();
    log.info('Comparing reloaded list with original list');
    Iterable<model.Call> reloadedList =
        await receptionist.callFlowControl.callList();
    _validateCallLists(originalCallQueue, reloadedList);
    expect(originalCallQueue.length, equals(1));
    expect(originalCallQueue.first.assignedTo, equals(model.noId));
    log.info('Test Succeeded');
  }

  /**
   *
   */
  static Future inboundAnsweredCall(model.OriginationContext context,
      Receptionist receptionist, Customer caller) async {
    log.info('Caller dials the reception at ${context.dialplan}');
    await caller.dial(context.dialplan);
    log.info('Receptionist hunt down the call');
    await receptionist.huntNextCall();
    log.info('Receptionist got call');
    final Iterable<model.Call> orignalCallQueue =
        await receptionist.callFlowControl.callList();
    expect(orignalCallQueue.length, equals(1));
    expect(orignalCallQueue.first.assignedTo, equals(receptionist.user.id));

    await receptionist.callStateReload();
    log.info('Comparing reloaded list with original list');
    Iterable<model.Call> reloadedList =
        await receptionist.callFlowControl.callList();
    _validateCallLists(orignalCallQueue, reloadedList);
    log.info('Test Succeeded');
  }

  /**
   *
   */
  static Future inboundParkedCall(model.OriginationContext context,
      Receptionist receptionist, Customer caller) async {
    log.info('Caller dials the reception at ${context.dialplan}');
    await caller.dial(context.dialplan);
    log.info('Receptionist hunt down the call');
    final model.Call assignedCall = await receptionist.huntNextCall();
    log.info('Receptionist got call');
    log.info('Receptionist parks call');
    await receptionist.park(assignedCall, waitForEvent: true);
    await receptionist.waitForPhoneHangup();
    log.info('Fetching original call list');
    final Iterable<model.Call> orignalCallQueue =
        await receptionist.callFlowControl.callList();
    expect(orignalCallQueue.length, equals(1));
    expect(orignalCallQueue.first.assignedTo, equals(receptionist.user.id));

    await receptionist.callStateReload();
    log.info('Comparing reloaded list with original list');
    _validateCallLists(
        orignalCallQueue, await receptionist.callFlowControl.callList());
    log.info('Test Succeeded');
  }

  /**
   *
   */
  static Future inboundUnparkedCall(model.OriginationContext context,
      Receptionist receptionist, Customer caller) async {
    log.info('Caller dials the reception at ${context.dialplan}');
    await caller.dial(context.dialplan);
    log.info('Receptionist hunts down the call');
    model.Call assignedCall = await receptionist.huntNextCall();

    log.info('Receptionist got call $assignedCall');
    log.info('Receptionist parks call');
    await receptionist.park(assignedCall, waitForEvent: true);
    log.info('Receptionist picks up call again');
    receptionist.eventStack.clear();
    try {
      await receptionist.pickup(assignedCall, waitForEvent: true);
    } catch (_) {
      fail('${assignedCall.toJson()}');
    }

    log.info('Fetching original call list');
    final Iterable<model.Call> orignalCallQueue =
        await receptionist.callFlowControl.callList();
    expect(orignalCallQueue.length, equals(1));
    expect(orignalCallQueue.first.assignedTo, equals(receptionist.user.id));
    expect(orignalCallQueue.first.state, equals(model.CallState.speaking_));

    await receptionist.callStateReload();
    log.info('Comparing reloaded list with original list');
    _validateCallLists(
        orignalCallQueue, await receptionist.callFlowControl.callList());

    log.info('Test Succeeded');
  }

  /**
   *
   */
  static Future outboundUnansweredCall(model.OriginationContext context,
      Receptionist receptionist, Customer callee) async {
    log.info('Receptionist dials the callee at ${callee.extension}');
    final model.Call outboundCall =
        await receptionist.originate(callee.extension, context);

    log.info('Fetching original call list');
    Iterable<model.Call> orignalCallQueue =
        await receptionist.callFlowControl.callList();
    expect(orignalCallQueue.length, equals(1));
    expect(orignalCallQueue.first.assignedTo, equals(receptionist.user.id));
    expect(orignalCallQueue, contains(outboundCall));

    await receptionist.callStateReload();
    log.info('Comparing reloaded list with original list');
    _validateCallLists(
        orignalCallQueue, await receptionist.callFlowControl.callList());

    log.info('Test Succeeded');
  }

  /**
   *
   */
  static Future outboundAnsweredCall(model.OriginationContext context,
      Receptionist receptionist, Customer callee) async {
    log.info('Receptionist dials the callee at ${callee.extension}');
    model.Call outboundCall =
        await receptionist.originate(callee.extension, context);

    await callee.waitForInboundCall();
    await callee.pickupCall();
    await receptionist.waitForPickup(outboundCall.id);
    log.info('Fetching original call list');
    final Iterable<model.Call> orignalCallQueue =
        await receptionist.callFlowControl.callList();

    expect(orignalCallQueue.length, equals(1));
    expect(orignalCallQueue.first.assignedTo, equals(receptionist.user.id));
    expect(orignalCallQueue, contains(outboundCall));

    await receptionist.callStateReload();
    log.info('Comparing reloaded list with original list');
    _validateCallLists(
        orignalCallQueue, await receptionist.callFlowControl.callList());

    log.info('Test Succeeded');
  }

  /**
   *
   */
  static Future transferredCalls(model.OriginationContext context,
      Receptionist receptionist, Customer caller, Customer callee) async {
    log.info('Caller dials the reception at ${context.dialplan}');
    await caller.dial(context.dialplan);
    log.info('Receptionist hunt down the call');
    final model.Call inboundCall = await receptionist.huntNextCall();

    log.info('Receptionist parks call');
    await receptionist.park(inboundCall, waitForEvent: true);

    log.info('Receptionist dials the callee at ${callee.extension}');

    model.Call outboundCall =
        await receptionist.originate(callee.extension, context);

    await callee.waitForInboundCall();
    await callee.pickupCall();
    await receptionist.waitForPickup(outboundCall.id);
    log.info('Fetching original call list');
    Iterable<model.Call> orignalCallQueue =
        await receptionist.callFlowControl.callList();

    expect(orignalCallQueue.length, equals(2));
    expect(orignalCallQueue.first.assignedTo, equals(receptionist.user.id));
    expect(orignalCallQueue.last.assignedTo, equals(receptionist.user.id));
    expect(orignalCallQueue, contains(outboundCall));

    await receptionist.callStateReload();
    log.info('Comparing reloaded list with original list');
    _validateCallLists(
        orignalCallQueue, await receptionist.callFlowControl.callList());

    log.info('Transferring call');
    await receptionist.transferCall(outboundCall, inboundCall);
    await receptionist.waitForTransfer(outboundCall.id);
    await receptionist.waitForTransfer(inboundCall.id);
    log.info('Fetching original call list');

    await receptionist.callFlowControl
        .callList()
        .then((Iterable<model.Call> calls) {
      expect(calls.length, equals(2));
      expect(calls.first.assignedTo, equals(receptionist.user.id));
      expect(calls, contains(outboundCall));
      orignalCallQueue = calls;
    });

    await receptionist.callStateReload();
    log.info('Comparing reloaded list with original list');
    _validateCallLists(
        orignalCallQueue, await receptionist.callFlowControl.callList());

    log.info('Test Succeeded');
  }
}
