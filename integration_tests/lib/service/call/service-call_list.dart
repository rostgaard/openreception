part of ort.service.call;

/// Tests for the call listing interface.
abstract class CallList {
  static Logger log = Logger('$_namespace.CallFlowControl.CallList');

  /// Validates the current call list from [callFlow] is empty.
  static Future _validateListEmpty(service.CallFlowControl callFlow) async {
    log.info('Checking if the call queue is empty');

    final Iterable<model.Call> calls = await callFlow.callList();
    expect(calls, isEmpty);
  }

  /**
   *
   */
  static Future _validateListContains(
      service.CallFlowControl callFlow, Iterable<model.Call> calls) async {
    Iterable<model.Call> queuedCalls = await callFlow.callList();
    bool existsInQueue(model.Call call) =>
        queuedCalls.any((model.Call queuedCall) => queuedCall.id == call.id);

    bool intersection() => calls.every(existsInQueue);

    expect(intersection(), isTrue);
  }

  /**
   *
   */
  static Future callPresence(model.ReceptionDialplan rdp,
      Receptionist receptionist, Customer customer) async {
    log.info('Customer ${customer.name} dials ${rdp.extension}.');
    await customer.dial(rdp.extension);

    log.info('Receptionist ${receptionist.user.name} waits for call.');
    final model.Call call = await receptionist.nextOfferedCall();
    await _validateListContains(receptionist.callFlowControl, [call]);

    log.info('Call is present in call list, asserting call list.');
    {
      Iterable<model.Call> calls =
          await receptionist.callFlowControl.callList();
      expect(calls.length, equals(1));
    }

    log.info('Customer ${customer.name} hangs up all crrent calls.');
    await customer.hangupAll();
    log.info('Receptionist ${receptionist.user.name} awaits call hangup.');
    await receptionist.waitForHangup(call.id);
    log.info('Test complete');
  }

  static Future callDataOK(model.Reception rec, model.ReceptionDialplan rdp,
      Receptionist receptionist, Customer customer) async {
    log.info('Customer ${customer.name} dials ${rdp.extension}.');
    await customer.dial(rdp.extension);

    log.info('Receptionist ${receptionist.user.name} waits for call.');
    final model.Call call = await receptionist.nextOfferedCall();
    expect(call.rid, equals(rec.id));
    //expect (call.destination, equals(reception));
    expect(call.assignedTo, equals(model.User.noId));
    expect(call.bLeg, isNull);
    expect(call.channel, isNotNull);
    expect(call.channel, isNotEmpty);
    expect(call.cid, equals(model.BaseContact.noId));
    expect(call.greetingPlayed, equals(false));
    expect(call.id, isNotNull);
    expect(call.id, isNotEmpty);
    expect(call.inbound, equals(true));
    expect(call.locked, equals(false));
    expect(call.arrived.difference(DateTime.now()).inMilliseconds.abs(),
        lessThan(1000));

    log.info('Call is present in call list, asserting call list.');
    {
      Iterable<model.Call> calls =
          await receptionist.callFlowControl.callList();
      expect(calls.length, equals(1));
    }

    log.info('Customer ${customer.name} hangs up all current calls.');
    await customer.hangupAll();
    log.info('Receptionist ${receptionist.user.name} awaits call hangup.');
    await receptionist.waitForHangup(call.id);
    log.info('Test complete.');
  }

  static Future queueLeaveEventFromPickup(model.ReceptionDialplan rdp,
      Receptionist receptionist, Customer caller) async {
    log.fine('Expecting call list to be empty');
    {
      Iterable<model.Call> calls =
          await receptionist.callFlowControl.callList();
      expect(calls, isEmpty);
    }

    await caller.dial(rdp.extension);
    log.info('Wating for the call to be received by the PBX.');
    final model.Call inboundCall = await receptionist.nextOfferedCall();

    log.info('Wating for the call $inboundCall to be queued.');
    await receptionist.waitForQueueJoin(inboundCall.id);

    {
      Iterable<model.Call> calls =
          await receptionist.callFlowControl.callList();
      expect(calls.length, equals(1));
    }

    await _validateListContains(receptionist.callFlowControl, [inboundCall]);
    {
      Iterable<model.Call> calls =
          await receptionist.callFlowControl.callList();
      expect(calls.first.state, equals(model.CallState.queued));
    }
    await receptionist.pickup(inboundCall, waitForEvent: true);
    {
      Iterable<model.Call> calls =
          await receptionist.callFlowControl.callList();
      expect(calls.first.state, isNot(model.CallState.queued));
    }

    await receptionist.waitForQueueLeave(inboundCall.id);
    log.info('Checking if the call is now absent from the call list.');
    await caller.hangupAll();

    await receptionist.waitForHangup(inboundCall.id);

    await _validateListEmpty(receptionist.callFlowControl);
    log.info('Test success.');
  }

  /// Tests if call an unpark event occur when a call is being hung
  /// up while in a queue.
  static Future queueLeaveEventFromHangup(model.ReceptionDialplan rdp,
      Receptionist receptionist, Customer caller) async {
    await _validateListEmpty(receptionist.callFlowControl);

    await caller.dial(rdp.extension);
    log.info('Wating for the call to be received by the PBX.');
    final model.Call inboundCall = await receptionist.nextOfferedCall();
    log.info('Wating for the call $inboundCall to be queued.');
    await receptionist.waitForQueueJoin(inboundCall.id);

    {
      Iterable<model.Call> calls =
          await receptionist.callFlowControl.callList();
      expect(calls.length, equals(1));
    }

    await _validateListContains(receptionist.callFlowControl, [inboundCall]);

    {
      final Iterable<model.Call> calls =
          await receptionist.callFlowControl.callList();
      expect(calls.first.state, equals(model.CallState.queued));
    }

    log.info('Caller hangs up call $inboundCall');
    await caller.hangupAll();

    await receptionist.waitForQueueLeave(inboundCall.id);

    log.info('Checking if the call is now absent from the call list.');

    await receptionist.waitForHangup(inboundCall.id);

    await _validateListEmpty(receptionist.callFlowControl);
    log.info('Test success. Cleaning up.');
  }
}
