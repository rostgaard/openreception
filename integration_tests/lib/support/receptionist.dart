part of ort.support;

/// Class modeling the domain actor "Receptionist".
/// Contains references to resources needed in order to make the actor perform
/// the actions described in the use cases.
/// Actions are outlined by public functions such as [pickup].
class Receptionist {
  /// Default constructor. Provides an _uninitialized_ [Receptionist] object.
  Receptionist(this.phone, this.authToken, this.user) {
    log.finest('Creating Receptionist with ${phone.runtimeType} phone '
        'and account ${phone.defaultAccount.username}@'
        '${phone.defaultAccount.server} - ${phone.defaultAccount.password}');
  }

  static final Logger log = Logger('Receptionist');

  final model.User user;
  final Phonio.SIPPhone phone;
  final String authToken;

  Service.NotificationSocket notificationSocket;
  Service.CallFlowControl callFlowControl;
  Transport.Client _transport = null;

  Completer readyCompleter = Completer();
  Queue<event.Event> eventStack = Queue<event.Event>();

  Phonio.Call currentCall = null;

  Map toJson() => {
        'id': hashCode,
        'user': user,
        'auth_token': authToken,
        'phone': phone,
        'event_stack': eventStack.toList()
      };

  int get hashCode => user.id.hashCode;

  /// The amout of time the actor will wait before answering an incoming call.
  Duration answerLatency = Duration(seconds: 0);

  /// Perform object initialization.
  /// Return a future that completes when the initialization process is done.
  /// This method should only be called by once, and other callers should
  /// use the [whenReady] function to wait for the object to become ready.
  Future initialize(Uri callFlowUri, Uri notificationSocketUri) async {
    _transport = Transport.Client();

    log.finest('Connecting to callflow on $callFlowUri');
    callFlowControl =
        Service.CallFlowControl(callFlowUri, authToken, _transport);

    if (readyCompleter.isCompleted) {
      readyCompleter = Completer();
    }

    Transport.WebSocketClient wsc = Transport.WebSocketClient();
    notificationSocket = Service.NotificationSocket(wsc);

    final notifyUri = Uri.parse('${notificationSocketUri}?token=${authToken}');
    log.finest('Connecting websocket to $notifyUri');

    await wsc.connect(notifyUri);
    notificationSocket.onEvent.listen(_handleEvent,
        onDone: () => log.fine('$this closing notification listener.'));

    await phone.initialize();
    phone.eventStream.listen(_onPhoneEvent,
        onDone: () => log.fine('$this closing event listener.'));
    await phone.autoAnswer(true);
    await phone.register();
    eventStack.clear();
    currentCall = null;

    readyCompleter.complete();
  }

  /// Perform object teardown.
  /// Return a future that completes when the teardown process is done.
  /// After teardown is completed, the object may be initialized again.
  Future teardown() {
    log.finest('Clearing state of $this');
    if (_transport != null) {
      _transport.client.close(force: true);
    }
    Future notificationSocketTeardown = notificationSocket == null
        ? Future.value()
        : notificationSocket.close();

    callFlowControl = null;
    Future phoneTeardown = phone.teardown();

    return Future.wait([
      notificationSocketTeardown,
      phoneTeardown,
      Future.delayed(Duration(milliseconds: 10))
    ]).catchError((error, stackTrace) {
      log.severe(
          'Potential race condition in teardown of Receptionist, ignoring as test error, but logging it');
      log.severe(error, stackTrace);
    });
  }

  Future finalize() =>
      phone.ready ? teardown().then((_) => phone.finalize()) : phone.finalize();

  /// Future that enables you the wait for the object to become ready.
  Future ready() {
    if (readyCompleter.isCompleted) {
      return Future.value(null);
    }

    return readyCompleter.future;
  }

  /// Dumps the current event stack of the Receptionist to log stream.
  void dumpEventStack() {
    log.severe('=== $this eventStack contents: ${eventStack}');
    eventStack.forEach(log.severe);
    log.severe('=== End of stack');
  }

  /// Globally enable autoanswer on phone.
  Future autoAnswer(bool enabled) => phone.autoAnswer(enabled);

  /// Registers the phone in the PBX SIP registry.
  Future registerAccount() {
    if (phone is Phonio.PJSUAProcess) {
      return (phone as Phonio.PJSUAProcess).registerAccount();
    } else if (phone is Phonio.SNOMPhone) {
      log.severe('Assuming that SNOM phone is already registered.');
      return Future(() => null);
    } else {
      return Future.error(UnimplementedError(
          'Unable to register phone type : ' '${phone.runtimeType}'));
    }
  }

  /// Transfers active [callA] to active [callB] via the
  /// [CallFlowControl] service.
  Future transferCall(model.Call callA, model.Call callB) =>
      callFlowControl.transfer(callA.id, callB.id);

  /// Parks [call] in the parking lot associated with the user via the
  /// [CallFlowControl] service. May optionally
  /// set [waitForEvent] that will make this method wait until the notification
  /// socket confirms the the call was sucessfully parked.
  Future park(model.Call call, {bool waitForEvent: false}) async {
    Future parkAction = callFlowControl.park(call.id);

    model.Call validateCall(model.Call parkedCall) {
      expect(call.id, parkedCall.id);
      expect(
          call.answeredAt
              .difference(parkedCall.answeredAt)
              .inMilliseconds
              .abs(),
          lessThan(500));
      expect(call.arrivalTime.difference(parkedCall.arrivalTime).inMilliseconds.abs(),
          lessThan(500));
      expect(call.assignedTo, parkedCall.assignedTo);
      expect(call.callerId, parkedCall.callerId);
      expect(call.channel, parkedCall.channel);
      expect(call.orCid, parkedCall.orCid);
      expect(call.destination, parkedCall.destination);
      expect(call.greetingPlayed, parkedCall.greetingPlayed);
      expect(call.inbound, parkedCall.inbound);
      //expect(call.locked, parkedCall.locked);
      expect(call.orRid, parkedCall.orRid);
      expect(parkedCall.state, equals(model.CallState.parked_));

      return parkedCall;
    }

    if (waitForEvent) {
      final parkEvent = await waitForPark(call.id);

      validateCall(parkEvent.call);

      return parkEvent.call;
    }
    return parkAction;
  }

  /// Returns a Future that completes when an inbound call is
  /// received on _the phone_.
  Future<Phonio.Call> waitForInboundCall() {
    log.finest('Receptionist $this waits for inbound call');

    bool match(Phonio.Event event) => event is Phonio.CallIncoming;

    if (currentCall != null) {
      log.finest('$this already has call, returning it.');

      return Future(() => currentCall);
    }

    log.finest('$this waits for incoming call from event stream.');
    return phone.eventStream.firstWhere(match).then((_) {
      log.finest('$this got expected event, returning current call.');

      return currentCall;
    }).timeout(Duration(seconds: 10));
  }

  /// Perform a call-state reload and await the corresponding event.
  Future callStateReload() async {
    log.info('Performing call-state reload');
    await callFlowControl.stateReload();
    await _waitFor(type: event.CallStateReload().runtimeType);
  }

  /// Returns a Future that completes when the phone associated with the
  /// receptionist is hung up.
  Future waitForPhoneHangup() async {
    log.finest('Receptionist $this waits for call hangup');

    if (currentCall == null) {
      log.finest('$this already has no call, returning.');
      return null;
    }

    log.finest('$this waits for call hangup from event stream.');
    return await phone.eventStream
        .firstWhere((Phonio.Event event) => event is Phonio.CallDisconnected)
        .then((_) {
      log.finest('$this got expected event, returning current call.');
      return null;
    }).timeout(Duration(seconds: 10));
  }

  /// Returns a Future that completes when the hangup event of [callId]
  /// occurs.
  Future<event.CallHangup> waitForHangup(String callId) async {
    log.finest('$this waits for call $callId to hangup');

    return await _waitFor(
        type: event.CallHangup(model.noCall).runtimeType, callID: callId);
  }

  /// Returns a Future that completes when [callId] is parked.
  Future<event.CallPark> waitForPark(String callId) async {
    log.finest('$this waits for call $callId to park');

    return await _waitFor(
        type: event.CallPark(model.noCall).runtimeType, callID: callId);
  }

  /// Returns a Future that completes when [callId] is parked.
  Future<event.CallUnpark> waitForUnpark(String callId) async {
    log.finest('$this waits for call $callId to park');

    return await _waitFor(
        type: event.CallUnpark(model.noCall).runtimeType, callID: callId);
  }

  /// Returns a Future that completes when [callId] is parked.
  Future<event.CallLock> waitForLock(String callId) async {
    log.finest('$this waits for call $callId to park');

    return await _waitFor(
        type: event.CallLock(model.noCall).runtimeType, callID: callId);
  }

  /// Returns a Future that completes when [callId] is parked.
  Future<event.CallUnlock> waitForUnlock(String callId) async {
    log.finest('$this waits for call $callId to park');

    return await _waitFor(
        type: event.CallUnlock(model.noCall).runtimeType, callID: callId);
  }

  /// Returns a Future that completes when [callId] is picked up.
  Future<event.CallPickup> waitForPickup(String callId) async {
    log.finest('$this waits for call $callId to be picked up');

    return await _waitFor(
        type: event.CallPickup(model.noCall).runtimeType, callID: callId);
  }

  /// Returns a Future that completes when [callId] is enqueued.
  Future<event.QueueLeave> waitForQueueLeave(String callId) async {
    log.finest('$this waits for call $callId to leave queue');

    return await _waitFor(
            type: event.QueueLeave(model.noCall).runtimeType,
            callID: callId)
        .timeout(Duration(seconds: 10));
  }

  /// Returns a Future that completes when [callId] leaves a queue.
  Future<event.QueueJoin> waitForQueueJoin(String callId) async {
    log.finest('$this waits for call $callId to join queue');

    return await _waitFor(
            type: event.QueueJoin(model.noCall).runtimeType,
            callID: callId)
        .timeout(Duration(seconds: 10));
  }

  /// Returns a Future that completes when [callId] is transferred.
  Future<event.CallTransfer> waitForTransfer(String callId) async {
    log.finest('$this waits for call $callId to join queue');

    return await _waitFor(
            type: event.CallTransfer(model.noCall).runtimeType,
            callID: callId)
        .timeout(Duration(seconds: 10));
  }

  /// Returns a Future that completes a peer event occurs on [peerId]
  Future<event.PeerState> waitForPeerState(String peerId) async {
    log.finest('$this waits for peer $peerId to change state');

    return await _waitFor(type: event.PeerState(null).runtimeType)
        .timeout(Duration(seconds: 10));
  }

  /// Hangs up phone of receptionist directly from the phone.
  Future phoneHangupAll() async {
    log.finest('$this hangs up phone');

    if (currentCall == null) {
      log.finest('$this already has no call, returning.');
      return;
    }

    await phone.hangupAll();
  }

  /// Originates a call to [extension] via the [CallFlowControl] service.
  Future<model.Call> originate(
          String extension, model.OriginationContext context) =>
      callFlowControl.originate(extension, context);

  /// Hangup [call] via the [CallFlowControl] service.
  Future hangUp(model.Call call) =>
      callFlowControl.hangup(call.id).catchError((error, stackTrace) {
        log.severe(
            'Tried to hang up call with info ${call.toJson()}. Receptionist info ${toJson()}',
            error,
            stackTrace);
      });

  /// Hangup all active calls currently connected to the phone.
  Future hangupAll() => phone.hangup();

  /// Waits for an arbitrary event identified either by [eventType], [callID],
  /// [extension], [receptionID], or a combination of them. The method will
  /// wait for, at most, [timeoutSeconds] before returning a Future error.
  Future<event.Event> _waitFor(
      {Type type: null,
      String callID: null,
      String extension: null,
      int receptionID: null,
      int timeoutSeconds: 10}) {
    if (type == null &&
        callID == null &&
        extension == null &&
        receptionID == null) {
      return Future.error(
          ArgumentError('Specify at least one parameter to wait for'));
    }

    bool matches(event.Event e) {
      bool result = false;
      if (type != null) {
        result = e.runtimeType == type;
      }

      if (callID != null && e is event.CallEvent) {
        result = result && e.call.id == callID;
      }

      if (extension != null && e is event.CallEvent) {
        result = result && e.call.destination == extension;
      }

      if (receptionID != null && e is event.CallEvent) {
        result = result && e.call.orRid == receptionID;
      }
      return result;
    }

    event.Event lookup = (eventStack.firstWhere(matches, orElse: () => null));

    if (lookup != null) {
      return Future(() => lookup);
    }
    log.finest(
        'Event is not yet received, waiting for maximum $timeoutSeconds seconds');

    return notificationSocket.onEvent
        .firstWhere(matches)
        .timeout(Duration(seconds: timeoutSeconds))
        .catchError((error, stackTrace) {
      log.severe(error, stackTrace);
      log.severe('Parameters: type:$type, '
          'callID:$callID, '
          'extension:$extension, '
          'receptionID:$receptionID');
      dumpEventStack();
      return Future.error(error, stackTrace);
    });
  }

  /// Perform a call pickup via the [CallFlowControl] service. May optionally
  /// set [waitForEvent] that will make this method wait until the notification
  /// socket confirms the the call was picked up.
  /// This method picks up a specific call.
  Future<model.Call> pickup(model.Call call, {waitForEvent: false}) async {
    final pickedUpCall = await callFlowControl.pickup(call.id);

    if (waitForEvent) {
      return (await waitForPickup(call.id)).call;
    }

    return pickedUpCall;
  }

  /// Hunts down the next available call, regardless of lockstate. The Future
  /// returned will complete only after the call has been confirmed connected
  /// via the notification socket (a call_pickup event is received).
  Future<model.Call> huntNextCall() async {
    Future<model.Call> pickupAfterCallUnlock(model.Call call) async {
      log.info('Call not aquired. $this expects the call to be locked.');

      await waitForLock(call.id);

      log.info('Call $call was locked, waiting for unlock.');
      await waitForUnlock(call.id);

      return pickup(call, waitForEvent: true);
    }

    log.info('$this goes hunting for a call.');

    final model.Call selectedCall = (await waitForCallOffer()).call;

    log.fine('$this attempts to pickup $selectedCall.');

    try {
      return pickup(selectedCall, waitForEvent: true);
    }
// Call is locked.
    on Conflict {
      return pickupAfterCallUnlock(selectedCall);
    }
// Call is hungup
    on NotFound {
      callEventsOnSelectedCall(event.Event e) {
        e is event.CallEvent ? e.call.id == selectedCall.id : false;
      }

      log.info('$this waits for $selectedCall to hangup');

      try {
        await waitForHangup(selectedCall.id);

        // Clear out the events from selected call.
        eventStack.removeWhere(callEventsOnSelectedCall);

        // Reschedule the hunting.
        return huntNextCall();
      } on TimeoutException {
        dumpEventStack();
        throw StateError(
            'Expected call to hung up, but no hangup event was received.');
      }
    } catch (error, stackTrace) {
      log.severe('huntNextCall experienced an unexpected error.');
      log.severe(error, stackTrace);
      return Future.error(error, stackTrace);
    }
  }

  /// Convenience function for waiting for the next call being offered to the
  /// receptionist.
  Future<event.CallOffer> waitForCallOffer() async {
    log.finest('$this waits for next call offer');

    return await _waitFor(type: event.CallOffer(model.noCall).runtimeType);
  }

  /// Event handler for events coming from the notification server.
  /// Merely pushes events onto a stack.
  void _handleEvent(event.Event event) {
    // Only push actual events to the event stack.
    if (event == null) {
      log.warning('Null event received!');
      return;
    }

    eventStack.add(event);
  }

  /// Debug-friendly representation of the receptionist.
  @override
  String toString() => 'Receptionist:${user.name}, uid:${user.id}, '
      'Phone:${phone}';

  /// Event handler for events coming from the phone. Updates the call state
  /// of the receptionist.
  void _onPhoneEvent(Phonio.Event event) {
    if (event is Phonio.CallOutgoing) {
      log.finest('$this received call outgoing event');
      Phonio.Call call = Phonio.Call(
          event.callId, event.callee, false, phone.defaultAccount.username);
      log.finest('$this sets call to $call');

      currentCall = call;
    } else if (event is Phonio.CallIncoming) {
      log.finest('$this received incoming call event');
      Phonio.Call call = Phonio.Call(
          event.callId, event.callee, false, phone.defaultAccount.username);
      log.finest('$this sets call to $call');
      currentCall = call;
    } else if (event is Phonio.CallDisconnected) {
      log.finest('$this received call diconnect event');

      currentCall = null;
    } else {
      log.severe('$this got unhandled event ${event.eventName}');
    }
  }

  /// Pause the receptionist.
  Future pause(Service.RESTUserStore userStore) =>
      userStore.userStatePaused(user.id);

  /// Await the next available call.
  Future<model.Call> nextOfferedCall() async => (await waitForCallOffer()).call;
}
