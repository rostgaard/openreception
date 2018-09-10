part of ort.service.call;

abstract class Pickup {
  static Logger log = Logger('$_namespace.CallFlowControl.Pickup');

  /// Tests the case where a receptionist tries to pick up a locked call.
  static Future pickupLockedCall(model.ReceptionDialplan rdp,
      Receptionist receptionist, Customer customer) async {
    log.info('Customer $customer dials ${rdp.extension}');
    await customer.dial(rdp.extension);

    log.info('Receptionist $receptionist waits for call.');
    final model.Call call = await receptionist.nextOfferedCall();
    await receptionist.waitForLock(call.id);

    await expect(
        receptionist.pickup(call), throwsA(const TypeMatcher<Conflict>()));
  }

  /// Tests the case where a receptionist tries to pick up a locked call.
  static Future pickupCallTwice(model.ReceptionDialplan rdp,
      Receptionist receptionist, Customer customer) async {
    log.info('Customer $customer dials ${rdp.extension}');
    await customer.dial(rdp.extension);

    log.info('Receptionist $receptionist waits for call.');
    final model.Call call = await receptionist.huntNextCall();
    log.info('Receptionist $receptionist got call $call.');
    log.info('Receptionist $receptionist picks up call again');
    await expect(
        receptionist.pickup(call), throwsA(const TypeMatcher<ClientError>()));
  }

  /**
   *
   */
  static Future pickupAllocatedCall(
      model.ReceptionDialplan rdp,
      Receptionist receptionist,
      Receptionist receptionist2,
      Customer customer) async {
    log.info('Customer $customer dials ${rdp.extension}');
    await customer.dial(rdp.extension);

    log.info('Receptionist $receptionist hunts call.');
    final model.Call call = await receptionist.huntNextCall();
    log.info(
        'Receptionist 2 $receptionist2 tries to pick up the call as well.');
    await expect(
        receptionist2.pickup(call), throwsA(const TypeMatcher<Forbidden>()));

    log.info('Test done');
  }

  /**
   *
   */
  static Future pickupRace(
      model.ReceptionDialplan rdp,
      Receptionist receptionist,
      Receptionist receptionist2,
      Customer customer) async {
    Completer c1 = Completer();
    Completer c2 = Completer();

    log.info('Customer $customer dials ${rdp.extension}');
    await customer.dial(rdp.extension);

    log.info('Receptionist ${receptionist.user.name} hunts call.');

    final model.Call offeredCall = await receptionist.nextOfferedCall();

    log.info('Receptionist 1 and 2 both tries to get the call');
    receptionist.pickup(offeredCall).then((model.Call call) {
      log.info('Receptionist 1 got call $call');
      c1.complete();
    }).catchError((error, stackTrace) {
      if (error is Forbidden) {
        log.info('Receptionist 1 got call Forbidden');
        c1.complete();
      } else {
        c1.completeError(error, stackTrace);
      }
    });

    receptionist2.pickup(offeredCall).then((model.Call call) {
      log.info('Receptionist 2 got call $call');
      c2.complete();
    }).catchError((error, stackTrace) {
      if (error is Forbidden) {
        log.info('Receptionist 2 got call Forbidden');
        c2.complete();
      } else {
        c2.completeError(error, stackTrace);
      }
    });

    await Future.wait([c1.future, c2.future]);

    final model.Call pickedUpCall =
        await receptionist.callFlowControl.get(offeredCall.id);

    expect(
        [receptionist.user.id, receptionist2.user.id]
            .contains(pickedUpCall.assignedTo),
        isTrue);

    log.info('Test done');
  }

  /**
   *
   */
  static Future pickupUnspecified(model.ReceptionDialplan rdp,
      Receptionist receptionist, Customer customer) async {
    log.info('$customer dials ${rdp.extension}');
    await customer.dial(rdp.extension);

    log.info('$receptionist waits for call.');

    final model.Call call = await receptionist.huntNextCall();
    log.info('$receptionist got call $call.');
    log.info('$receptionist retrieves the call information from the server.');
    final model.Call fetched = await receptionist.callFlowControl.get(call.id);

    expect(fetched.assignedTo, equals(receptionist.user.id));
    expect(fetched.state, equals(model.CallState.speaking));
  }

  /**
   *
   */
  static Future pickupSpecified(model.ReceptionDialplan rdp,
      Receptionist receptionist, Customer customer) async {
    log.info('$customer dials ${rdp.extension}');
    await customer.dial(rdp.extension);

    log.info('Receptionist ${receptionist.user.name} waits for call.');
    final model.Call inboundCall = await receptionist.nextOfferedCall();
    await receptionist.pickup(inboundCall, waitForEvent: false);

    final event.CallPickup pickupEvent =
        await receptionist.waitForPickup(inboundCall.id);

    expect(pickupEvent.call.assignedTo, equals(receptionist.user.id));
    expect(pickupEvent.call.state, equals(model.CallState.speaking));
  }

  /**
   *
   */
  static Future pickupNonExistingCall(Receptionist receptionist) async {
    await expect(receptionist.callFlowControl.pickup('null'),
        throwsA(const TypeMatcher<NotFound>()));
  }

  /**
   *
   */
  static Future pickupEventInboundCall(model.ReceptionDialplan rdp,
      Receptionist receptionist, Customer customer) async {
    log.info('$customer dials ${rdp.extension}');
    await customer.dial(rdp.extension);

    log.info('Receptionist ${receptionist.user.name} hunts call.');
    final model.Call call = await receptionist.huntNextCall();
    await receptionist.waitForPickup(call.id);
    log.info('Test done');
  }

  /**
   *
   */
  static Future pickupEventOutboundCall(model.OriginationContext context,
      Receptionist receptionist, Customer customer) async {
    log.info('$receptionist dials contact');
    final model.Call outboundCall =
        await receptionist.originate(customer.extension, context);

    await customer.waitForInboundCall();
    log.info('$customer got inbound call');
    await customer.pickupCall();
    await receptionist.waitForPickup(outboundCall.id);
    log.info('Test done');
  }
}
