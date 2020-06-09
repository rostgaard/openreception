part of ort.service.call;

abstract class Originate {
  ///Internal logger.
  static Logger _log = Logger('$_namespace.CallFlowControl.Originate');

  //TODO implement
  //static Future  originationToLookedUNumber()

  static Future originationToHostedNumber(
      model.OriginationContext context, Receptionist receptionist) async {
    await receptionist.originate(context.dialplan, context);

    final event.CallOffer e = await receptionist.waitForCallOffer();

    expect(e.call.inbound, isTrue);
    expect(e.call.callerId, equals(receptionist.user.name));
  }

  /// Tests the system behaviour whenever a channel being established to an
  /// agent that has disabled autoanswer and rejects the call.
  /// Expected behaviour is that the server should detect the reject and send
  /// a [storage.ClientError].
  static Future originationOnAgentCallRejected(model.OriginationContext context,
      Receptionist receptionist, Customer customer) async {
    await receptionist.autoAnswer(false);

    /// Asynchronous origination.
    final Future origination =
        receptionist.originate(customer.extension, context);

    await receptionist.waitForInboundCall();
    _log.info('Receptionist $receptionist rejects the call');
    await receptionist.phoneHangupAll();
    await expect(origination, throwsA(const TypeMatcher<ClientError>()));
  }

  /// Tests the system behaviour whenever a channel being established to an
  /// agent that has disabled autoanswer and never accepts the call.
  /// Expected behaviour is that the server should detect the reject and send
  /// a [storage.ClientError].
  static Future originationOnAgentAutoAnswerDisabled(
      model.OriginationContext context,
      Receptionist receptionist,
      Customer customer) async {
    await receptionist.autoAnswer(false);

    /// Asynchronous origination.
    Future origination = receptionist
        .originate(customer.extension, context)
        .timeout(Duration(seconds: 30));
    await receptionist.waitForInboundCall();
    _log.info('Receptionist $receptionist ignores the incoming channel');
    await expect(origination, throwsA(const TypeMatcher<ClientError>()));
  }

  /// Tests the system behaviour whenever a channel being established to an
  /// agent that has disabled autoanswer and never accepts the call _and_
  /// another agent tries to establish a channel to the PBX.
  /// Expected behaviour is that the second receptionist should be able
  /// to get the channel before the timeout.
  static Future agentAutoAnswerDisabledNonBlock(
      model.OriginationContext context,
      Receptionist receptionist,
      Receptionist receptionist2,
      Customer customer) async {
    await receptionist.autoAnswer(false);

    /// Asynchronous origination.
    Future origination = receptionist
        .originate(customer.extension, context)
        .timeout(Duration(seconds: 30));

    /// Ignore errors
    origination.catchError((_) => null);

    await receptionist.waitForInboundCall();
    _log.info('Receptionist $receptionist ignores the incoming channel');

    Future secondOrigination = receptionist2
        .originate(customer.extension, context)
        .timeout(Duration(seconds: 10));

    await secondOrigination;
  }

  /// Origination to a number that is known (by the call-flow-control server) to
  /// be forbidden.
  static void originationToForbiddenNumber(
      model.OriginationContext context, Receptionist receptionist) {
    return expect(receptionist.originate('X', context),
        throwsA(const TypeMatcher<ClientError>()));
  }

  /// Test if the system is able to originate to another peer.
  static Future originationToPeer(model.OriginationContext context,
      Receptionist receptionist, Customer customer) async {
    await receptionist.originate(customer.extension, context);
    phonio.Call call = await customer.waitForInboundCall();
    expect(call.callerId, equals(customer.phone.defaultAccount.username));
  }

  /// Test if the system tags the callId to the channel.
  static Future originationWithCallContext(model.OriginationContext context,
      Receptionist receptionist, Customer customer) async {
    final String callId = DateTime.now().millisecondsSinceEpoch.toString();
    context.callId = callId;

    await customer.autoAnswer(false);
    model.Call call = await receptionist.callFlowControl
        .originate(customer.extension, context);

    await customer.waitForInboundCall();
    await customer.pickupCall();
    await Future.delayed(Duration(seconds: 1));
    Map channel = null;
    //await receptionist.callFlowControl.channelMap(call.channel);

    expect(channel['variables'][pbxKey.ORPbxKey.contextCallId], equals(callId));
  }

  /// Check that only one call is present in the call list when performing an
  /// outbound dial.
  static Future originationToPeerCheckforduplicate(
      model.OriginationContext context,
      Receptionist receptionist,
      Customer customer) async {
    await receptionist.originate(customer.extension, context);
    await customer.waitForInboundCall();

    final Iterable calls = await receptionist.callFlowControl.callList();
    expect(calls.length, equals(1));
  }
}
