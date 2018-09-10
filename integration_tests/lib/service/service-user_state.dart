part of ort.service;

abstract class UserState {
  static Logger log = Logger('$_namespace.CallFlowControl.UserState');

  /// Tests if the receptionist receives an error when trying originate
  /// a call while in call.
  static Future originateForbidden(model.OriginationContext context,
      Receptionist receptionist, Customer caller, Customer callee) async {
    log.info('Caller dials the reception at ${context.dialplan}');

    await caller.dial(context.dialplan);
    log.info('Receptionist tries to hunt down the next call');
    final model.Call firstCall = await receptionist.huntNextCall();
    expect(firstCall, isNotNull);
    expect(firstCall.id, isNot(model.Call.noId));

    log.info('Receptionist tries to orignate a call to $callee');
    expect(receptionist.originate(callee.extension, context),
        throwsA(TypeMatcher<ClientError>()));
    await receptionist.hangUp(firstCall);
    await receptionist.waitForPhoneHangup();

    log.info('$receptionist tries to orignate a call to $callee again');
    final model.Call outboundCall =
        await receptionist.originate(callee.extension, context);
    await receptionist.hangUp(outboundCall);
    await receptionist.waitForPhoneHangup();
  }

  /// Tests if the receptionist receives an error when trying to pick
  /// up a second call while in call.
  static Future pickupForbidden(
      model.OriginationContext context,
      Receptionist receptionist,
      Customer caller,
      Customer second_caller) async {
    log.info('Caller dials the reception at ${context.dialplan}');
    await caller.dial(context.dialplan);
    log.info('Receptionist tries to hunt down the next call');
    final model.Call firstCall = await receptionist.huntNextCall();
    log.info('$receptionist got $firstCall');
    receptionist.eventStack.clear();
    log.info('Second caller dials the reception at ${context.dialplan}');
    await second_caller.dial(context.dialplan);

    log.info('Receptionist waits second call');
    final model.Call secondCall = await receptionist.nextOfferedCall();

    log.info('Receptionist tries to pick up second call $secondCall');
    expect(
        receptionist.pickup(secondCall), throwsA(TypeMatcher<ClientError>()));

    await receptionist.hangUp(firstCall);
    await receptionist.waitForPhoneHangup();
    await receptionist.pickup(secondCall, waitForEvent: true);
    await receptionist.hangUp(secondCall);
    await receptionist.waitForPhoneHangup();
  }
}
