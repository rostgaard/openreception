part of ort.rest;

void _runCallTests() {
//  _runCallHangupTests();
//  _runCallListTests();
//  _runCallPickupTests();
//  _runCallActiveRecordingTests();
//  _runPeerRegistrationTests();
//  _runCallParkTests();
//  _runCallOriginateTests();
//  _runCallUserStateTests();
  _runCallStateReloadTests();
//  _runCallTransferTests();
}

/// CallFlowControl Call transfer.
void _runCallTransferTests() {
  group('$_namespace.Call.Transfer', () {
    ServiceAgent sa;
    TestEnvironment env;
    Receptionist r;
    Customer c;
    Customer c2;

    /// Transient object
    model.ReceptionDialplan rdp;
    model.Reception rec;
    model.OriginationContext context;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      final org = await sa.createsOrganization();
      rec = await sa.createsReception(org);
      rdp = await sa.createsDialplan();
      await sa.deploysDialplan(rdp, rec);

      context = model.OriginationContext()
        ..dialplan = rdp.extension
        ..receptionId = rec.id;
      r = await sa.createsReceptionist();
      c = await sa.spawnCustomer();
      c2 = await sa.spawnCustomer();
    });

    tearDown(() async {
      Logger.root.finest(
          'FSLOG:\n ${(await env.requestFreeswitchProcess()).latestLog.readAsStringSync()}');
      await env.clear();
    });

    test('inboundCall Call list length checks',
        () => serviceTest.Transfer.inboundCallListLength(r, c, c2, context));

    test(
        'Inbound Call',
        () =>
            serviceTest.Transfer.transferParkedInboundCall(r, c, c2, context));

    test(
        'Outbound Call',
        () =>
            serviceTest.Transfer.transferParkedOutboundCall(r, c, c2, context));
  });
}

/// CallFlowControl state reload.
void _runCallStateReloadTests() {
  group('$_namespace.Call.StateReload', () {
    ServiceAgent sa;
    TestEnvironment env;
    Receptionist r;
    Customer c;

    /// Transient object
    model.ReceptionDialplan rdp;
    model.Reception rec;
    model.OriginationContext context;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      final org = await sa.createsOrganization();
      rec = await sa.createsReception(org);
      rdp = await sa.createsDialplan();
      await sa.deploysDialplan(rdp, rec);

      context = model.OriginationContext()
        ..dialplan = rdp.extension
        ..receptionId = rec.id;
      r = await sa.createsReceptionist();
      c = await sa.spawnCustomer();
    });

    tearDown(() async {
   //   Logger.root.finest(
     //     'FSLOG:\n ${(await env.requestFreeswitchProcess()).latestLog.readAsStringSync()}');
      await env.clear();
    });

    test('inboundCallUnanswered',
        () => serviceTest.StateReload.inboundUnansweredCall(context, r, c));

//    test('inboundAnsweredCall',
//        () => serviceTest.StateReload.inboundAnsweredCall(context, r, c));
//
//    test('inboundParkedCall',
//        () => serviceTest.StateReload.inboundParkedCall(context, r, c));
//
//    test('inboundUnparkedCall',
//        () => serviceTest.StateReload.inboundUnparkedCall(context, r, c));
//
//    test('outboundUnansweredCall',
//        () => serviceTest.StateReload.outboundUnansweredCall(context, r, c));
//
//    test('outboundAnsweredCall',
//        () => serviceTest.StateReload.outboundAnsweredCall(context, r, c));
  });

  group('$_namespace.Call.StateReload', () {
    ServiceAgent sa;
    TestEnvironment env;
    Receptionist r;
    Customer c;
    Customer c2;

    /// Transient object
    model.ReceptionDialplan rdp;
    model.Reception rec;
    model.OriginationContext context;
    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      final org = await sa.createsOrganization();
      rec = await sa.createsReception(org);
      rdp = await sa.createsDialplan();
      await sa.deploysDialplan(rdp, rec);

      context = model.OriginationContext()
        ..dialplan = rdp.extension
        ..receptionId = rec.id;
      r = await sa.createsReceptionist();
      c = await sa.spawnCustomer();
      c2 = await sa.spawnCustomer();
    });

    tearDown(() async {
      Logger.root.finest(
          'FSLOG:\n ${(await env.requestFreeswitchProcess()).latestLog.readAsStringSync()}');
      await env.clear();
    });

//    test('transferredCalls',
//        () => serviceTest.StateReload.transferredCalls(context, r, c, c2));
  });
}

/**
 * CallFlowControl user state.
 */
void _runCallUserStateTests() {
  group('$_namespace.Call.UserState', () {
    ServiceAgent sa;
    TestEnvironment env;
    Receptionist r;
    Customer c;
    Customer c2;

    /// Transient object
    model.ReceptionDialplan rdp;
    model.Reception rec;
    model.OriginationContext context;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      final org = await sa.createsOrganization();
      rec = await sa.createsReception(org);
      rdp = await sa.createsDialplan();
      await sa.deploysDialplan(rdp, rec);

      context = model.OriginationContext()
        ..dialplan = rdp.extension
        ..receptionId = rec.id;
      r = await sa.createsReceptionist();
      c = await sa.spawnCustomer();
      c2 = await sa.spawnCustomer();
    });

    tearDown(() async {
      Logger.root.finest(
          'FSLOG:\n ${(await env.requestFreeswitchProcess()).latestLog.readAsStringSync()}');
      await env.clear();
    });

    test('originateForbidden',
        () => serviceTest.UserState.originateForbidden(context, r, c, c2));

    test('pickupForbidden',
        () => serviceTest.UserState.pickupForbidden(context, r, c, c2));
  });
}

/// CallFlowControl Call originate.
void _runCallOriginateTests() {
  group('$_namespace.Call.Originate', () {
    ServiceAgent sa;
    TestEnvironment env;
    Receptionist r;

    Customer c;

    /// Transient object
    model.ReceptionDialplan rdp;
    model.Reception rec;
    model.OriginationContext context;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      final org = await sa.createsOrganization();
      rec = await sa.createsReception(org);
      rdp = await sa.createsDialplan();
      await sa.deploysDialplan(rdp, rec);

      context = model.OriginationContext()
        ..dialplan = rdp.extension
        ..receptionId = rec.id;
      r = await sa.createsReceptionist();
      c = await sa.spawnCustomer();
    });

    tearDown(() async {
      Logger.root.finest(
          'FSLOG:\n ${(await env.requestFreeswitchProcess()).latestLog.readAsStringSync()}');
      await env.clear();
    });

    // TODO: This one requires a dialplan change.
    // test('originationToHostedNumber',
    //     () => serviceTest.Originate.originationToHostedNumber(r));

    test(
        'originationOnAgentCallRejected',
        () => serviceTest.Originate.originationOnAgentCallRejected(
            context, r, c));

    test(
        'originationOnAgentAutoAnswer',
        () => serviceTest.Originate.originationOnAgentAutoAnswerDisabled(
            context, r, c));

    test('originationToForbiddenNumber',
        () => serviceTest.Originate.originationToForbiddenNumber(context, r));

    test('originationToPeer',
        () => serviceTest.Originate.originationToPeer(context, r, c));

    test('originationWithCallContext',
        () => serviceTest.Originate.originationWithCallContext(context, r, c));

    test(
        'originationToPeerCheckforduplicate',
        () => serviceTest.Originate.originationToPeerCheckforduplicate(
            context, r, c));
  });

  group('$_namespace.Call.Originate', () {
    ServiceAgent sa;
    TestEnvironment env;
    Receptionist r;
    Receptionist r2;
    Customer c;

    /// Transient object
    model.ReceptionDialplan rdp;
    model.Reception rec;
    model.OriginationContext context;
    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      final org = await sa.createsOrganization();
      rec = await sa.createsReception(org);
      rdp = await sa.createsDialplan();
      await sa.deploysDialplan(rdp, rec);

      context = model.OriginationContext()
        ..dialplan = rdp.extension
        ..receptionId = rec.id;
      r = await sa.createsReceptionist();
      r2 = await sa.createsReceptionist();

      c = await sa.spawnCustomer();
    });

    tearDown(() async {
      Logger.root.finest(
          'FSLOG:\n ${(await env.requestFreeswitchProcess()).latestLog.readAsStringSync()}');
      await env.clear();
    });

    test(
        'multipleOriginationsOnAgentAutoAnswerDisabled',
        () => serviceTest.Originate.agentAutoAnswerDisabledNonBlock(
            context, r, r2, c));
  });
}

/**
 * CallFlowControl Call Park.
 */
void _runCallParkTests() {
  group('$_namespace.Call.Park', () {
    ServiceAgent sa;
    TestEnvironment env;
    Receptionist r;
    Customer c;

    /// Transient object
    model.ReceptionDialplan rdp;
    model.Reception rec;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      final org = await sa.createsOrganization();
      rec = await sa.createsReception(org);
      rdp = await sa.createsDialplan();
      await sa.deploysDialplan(rdp, rec);

      r = await sa.createsReceptionist();
      c = await sa.spawnCustomer();
    });

    tearDown(() async {
      Logger.root.finest(
          'FSLOG:\n ${(await env.requestFreeswitchProcess()).latestLog.readAsStringSync()}');
      await env.clear();
    });

    test('parkCallListLength',
        () => serviceTest.CallPark.parkCallListLength(rdp, r, c));

    test('explicitParkPickup',
        () => serviceTest.CallPark.explicitParkPickup(rdp, r, c));

    test('unparkEventFromHangup',
        () => serviceTest.CallPark.unparkEventFromHangup(rdp, r, c));

    test('parkNonexistingCall',
        () => serviceTest.CallPark.parkNonexistingCall(rdp, r));
  });
}

/**
 * CallFlowControl Peer tests.
 */
void _runPeerRegistrationTests() {
  group('$_namespace.Call.Peer', () {
    ServiceAgent sa;
    TestEnvironment env;
    Receptionist r;

    /// Transient object
    model.ReceptionDialplan rdp;
    model.Reception rec;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      final org = await sa.createsOrganization();
      rec = await sa.createsReception(org);
      rdp = await sa.createsDialplan();
      await sa.deploysDialplan(rdp, rec);

      r = await sa.createsReceptionist();
    });

    tearDown(() async {
      Logger.root.finest(
          'FSLOG:\n ${(await env.requestFreeswitchProcess()).latestLog.readAsStringSync()}');
      await env.clear();
    });

    test('Event presence', () => serviceTest.Peer.eventPresence(r));
    test('Peer listing', () => serviceTest.Peer.list(r.callFlowControl));
  });
}

/**
 * CallFlowControl active recordings tests.
 */
void _runCallActiveRecordingTests() {
  group('$_namespace.Call.Recording', () {
    Logger log = Logger('$_namespace.Call');

    ServiceAgent sa;
    TestEnvironment env;
    service.CallFlowControl callflow;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      await env.requestFreeswitchProcess();
      callflow = (await env.requestCallFlowProcess())
          .bindClient(env.httpClient, sa.authToken);
    });

    tearDown(() async {
      log.finest(
          'FSLOG:\n ${(await env.requestFreeswitchProcess()).latestLog.readAsStringSync()}');
      await env.clear();
    });

    test('empty list', () => serviceTest.ActiveRecording.listEmpty(callflow));

    test('non-existing recording',
        () => serviceTest.ActiveRecording.getNonExisting(callflow));
  });
}

void _runCallHangupTests() {
  group('$_namespace.Call.Hangup', () {
    Logger log = Logger('$_namespace.Call');

    ServiceAgent sa;
    TestEnvironment env;
    Receptionist r;
    Customer c;
    process.CallFlowControl cfProcess;

    /// Transient object
    model.ReceptionDialplan rdp;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      final org = await sa.createsOrganization();
      final rec = await sa.createsReception(org);
      rdp = await sa.createsDialplan();
      await sa.deploysDialplan(rdp, rec);

      r = await sa.createsReceptionist();
      c = await sa.spawnCustomer();
      cfProcess = await env.requestCallFlowProcess();
    });

    tearDown(() async {
      log.finest(
          'FSLOG:\n ${(await env.requestFreeswitchProcess()).latestLog.readAsStringSync()}');
      await env.clear();
    });

    test(
        'CORS headers present (existingUri)',
        () async => isCORSHeadersPresent(Uri.parse('${cfProcess.uri}/ping'),
            log));

    test(
        'CORS headers present (non-existingUri)',
        () async => isCORSHeadersPresent(
            Uri.parse(
                '${(await env.requestCallFlowProcess()).uri}/nonexistingpath'),
            log));

    test(
        'Non-existing path',
        () async => nonExistingPath(
            Uri.parse(
                '${(await env.requestCallFlowProcess()).uri}/nonexistingpath'
                '?token=${sa.authToken.tokenName}'),
            log));

    test('interfaceCallNotFound',
        () => serviceTest.Hangup.interfaceCallNotFound(sa));

    test('eventPresence', () => serviceTest.Hangup.eventPresence(rdp, r, c));

    test('hangupCause', () => serviceTest.Hangup.hangupCause(rdp, r, c));

    test('interfaceCallFound',
        () => serviceTest.Hangup.interfaceCallFound(rdp, r, c));
  });
}

/// CallFlowControl Call listing.
void _runCallListTests() {
  group('$_namespace.Call.List', () {
    ServiceAgent sa;
    TestEnvironment env;
    Receptionist r;
    Customer c;

    /// Transient object
    model.ReceptionDialplan rdp;
    model.Reception rec;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      final org = await sa.createsOrganization();
      rec = await sa.createsReception(org);
      rdp = await sa.createsDialplan();
      await sa.deploysDialplan(rdp, rec);

      r = await sa.createsReceptionist();
      c = await sa.spawnCustomer();
    });

    tearDown(() async {
      //log.finest('FSLOG:\n ${fsProcess.latestLog.readAsStringSync()}');
      await env.clear();
    });

//    test('callDataOK', () => serviceTest.CallList.callDataOK(rec, rdp, r, c));
//
//    test('interfaceCallFound',
//        () => serviceTest.CallList.callPresence(rdp, r, c));

//    test('queueLeaveEventFromPickup',
//        () => serviceTest.CallList.queueLeaveEventFromPickup(rdp, r, c));

    test('queueLeaveEventFromHangup',
        () => serviceTest.CallList.queueLeaveEventFromHangup(rdp, r, c));
  });
}

/// CallFlowControl Call pickup.
void _runCallPickupTests() {
  group('$_namespace.Call.Pickup', () {
    ServiceAgent sa;
    TestEnvironment env;
    Receptionist r;
    Receptionist r2;
    Customer c;

    /// Transient object
    model.ReceptionDialplan rdp;
    model.Reception rec;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      final org = await sa.createsOrganization();
      rec = await sa.createsReception(org);
      rdp = await sa.createsDialplan();
      await sa.deploysDialplan(rdp, rec);

      r = await sa.createsReceptionist();
      r2 = await sa.createsReceptionist();
      c = await sa.spawnCustomer();
    });

    tearDown(() async {
      Logger.root.finest(
          'FSLOG:\n ${(await env.requestFreeswitchProcess()).latestLog.readAsStringSync()}');
      await env.clear();
    });

    /* Perform test. */
    test(
        'pickupSpecified', () => serviceTest.Pickup.pickupSpecified(rdp, r, c));

    test('pickupUnspecified',
        () => serviceTest.Pickup.pickupUnspecified(rdp, r, c));

    test('pickupNonExistingCall',
        () => serviceTest.Pickup.pickupNonExistingCall(r));

    test('pickupLockedCall',
        () => serviceTest.Pickup.pickupLockedCall(rdp, r, c));

    test(
        'pickupCallTwice', () => serviceTest.Pickup.pickupCallTwice(rdp, r, c));

    test('pickupEventInboundCall',
        () => serviceTest.Pickup.pickupEventInboundCall(rdp, r, c));

    test(
        'pickupEventOutboundCall',
        () => serviceTest.Pickup.pickupEventOutboundCall(
            model.OriginationContext()
              ..receptionId = rec.id
              ..dialplan = rdp.extension,
            r,
            c));

    test('pickupAllocatedCall',
        () => serviceTest.Pickup.pickupAllocatedCall(rdp, r, r2, c));

    test('pickupRace', () => serviceTest.Pickup.pickupRace(rdp, r, r2, c));
  });
}
