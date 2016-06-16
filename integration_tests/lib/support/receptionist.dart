part of openreception_tests.support;

/**
 * Class modeling the domain actor "Receptionist".
 * Contains references to resources needed in order to make the actor perform
 * the actions described in the use cases.
 * Actions are outlined by public functions such as [pickup].
 */
class Receptionist {
  static final Logger log = new Logger('Receptionist');

  final model.User user;
  final Phonio.SIPPhone phone;
  final String authToken;

  Service.NotificationSocket notificationSocket;
  Service.CallFlowControl callFlowControl;
  Transport.Client _transport = null;

  Completer readyCompleter = new Completer();
  Queue<event.Event> eventStack = new Queue<event.Event>();

  Phonio.Call currentCall = null;

  Map toJson() => {
        'id': this.hashCode,
        'user': user,
        'auth_token': authToken,
        'phone': phone,
        'event_stack': eventStack.toList()
      };

  int get hashCode => user.id.hashCode;

  /// The amout of time the actor will wait before answering an incoming call.
  Duration answerLatency = new Duration(seconds: 0);

  /**
   * Default constructor. Provides an _uninitialized_ [Receptionist] object.
   */
  Receptionist(this.phone, this.authToken, this.user) {
    log.finest('Creating new Receptionist with ${phone.runtimeType} phone '
        'and account ${phone.defaultAccount.username}@'
        '${phone.defaultAccount.server} - ${phone.defaultAccount.password}');
  }

  /**
   * Perform object initialization.
   * Return a future that completes when the initialization process is done.
   * This method should only be called by once, and other callers should
   * use the [whenReady] function to wait for the object to become ready.
   */
  Future initialize(Uri callFlowUri, Uri notificationSocketUri) async {
    _transport = new Transport.Client();

    log.finest('Connecting to callflow on $callFlowUri');
    callFlowControl = new Service.CallFlowControl(
        callFlowUri, this.authToken, this._transport);

    if (this.readyCompleter.isCompleted) {
      this.readyCompleter = new Completer();
    }

    Transport.WebSocketClient wsc = new Transport.WebSocketClient();
    this.notificationSocket = new Service.NotificationSocket(wsc);

    final notifyUri =
        Uri.parse('${notificationSocketUri}?token=${this.authToken}');
    log.finest('Connecting websocket to $notifyUri');

    await wsc.connect(notifyUri);
    notificationSocket.onEvent.listen(_handleEvent,
        onDone: () => log.fine('$this closing notification listener.'));

    await phone.initialize();
    phone.eventStream.listen(this._onPhoneEvent,
        onDone: () => log.fine('$this closing event listener.'));
    await phone.autoAnswer(true);
    await phone.register();
    eventStack.clear();
    currentCall = null;

    readyCompleter.complete();
  }

  /**
   * Perform object teardown.
   * Return a future that completes when the teardown process is done.
   * After teardown is completed, the object may be initialized again.
   */
  Future teardown() {
    log.finest('Clearing state of $this');
    if (this._transport != null) {
      this._transport.client.close(force: true);
    }
    Future notificationSocketTeardown = this.notificationSocket == null
        ? new Future.value()
        : this.notificationSocket.close();

    this.callFlowControl = null;
    Future phoneTeardown = this.phone.teardown();

    return Future.wait([
      notificationSocketTeardown,
      phoneTeardown,
      new Future.delayed(new Duration(milliseconds: 10))
    ]).catchError((error, stackTrace) {
      log.severe(
          'Potential race condition in teardown of Receptionist, ignoring as test error, but logging it');
      log.severe(error, stackTrace);
    });
  }

  Future finalize() =>
      phone.ready ? teardown().then((_) => phone.finalize()) : phone.finalize();

  /**
   * Future that enables you the wait for the object to become ready.
   */
  Future ready() {
    if (this.readyCompleter.isCompleted) {
      return new Future.value(null);
    }

    return this.readyCompleter.future;
  }

  /**
   * Dumps the current event stack of the Receptionist to log stream.
   */
  void dumpEventStack() {
    log.severe('=== $this eventStack contents: ${this.eventStack}');
    this.eventStack.forEach(log.severe);
    log.severe('=== End of stack');
  }

  /**
   * Globally enable autoanswer on phone.
   */
  Future autoAnswer(bool enabled) => this.phone.autoAnswer(enabled);

  /**
   * Registers the phone in the PBX SIP registry.
   */
  Future registerAccount() {
    if (this.phone is Phonio.PJSUAProcess) {
      return (this.phone as Phonio.PJSUAProcess).registerAccount();
    } else if (this.phone is Phonio.SNOMPhone) {
      log.severe('Assuming that SNOM phone is already registered.');
      return new Future(() => null);
    } else {
      return new Future.error(new UnimplementedError(
          'Unable to register phone type : ' '${this.phone.runtimeType}'));
    }
  }

  /**
   * Transfers active [callA] to active [callB] via the
   * [CallFlowControl] service.
   */
  Future transferCall(model.Call callA, model.Call callB) =>
      this.callFlowControl.transfer(callA.id, callB.id);

  /**
   * Parks [call] in the parking lot associated with the user via the
   * [CallFlowControl] service. May optionally
   * set [waitForEvent] that will make this method wait until the notification
   * socket confirms the the call was sucessfully parked.
   */
  Future park(model.Call call, {bool waitForEvent: false}) {
    Future parkAction = this.callFlowControl.park(call.id);

    model.Call validateCall(model.Call parkedCall) {
      expect(call.id, parkedCall.id);
      expect(
          call.answeredAt
              .difference(parkedCall.answeredAt)
              .inMilliseconds
              .abs(),
          lessThan(500));
      expect(call.arrived.difference(parkedCall.arrived).inMilliseconds.abs(),
          lessThan(500));
      expect(call.assignedTo, parkedCall.assignedTo);
      expect(call.callerId, parkedCall.callerId);
      expect(call.channel, parkedCall.channel);
      expect(call.cid, parkedCall.cid);
      expect(call.destination, parkedCall.destination);
      expect(call.greetingPlayed, parkedCall.greetingPlayed);
      expect(call.inbound, parkedCall.inbound);
      //expect(call.locked, parkedCall.locked);
      expect(call.rid, parkedCall.rid);
      expect(parkedCall.state, equals(model.CallState.parked));

      return parkedCall;
    }

    if (waitForEvent) {
      return parkAction
          .then((_) => this.waitFor(
              eventType: event.Key.callPark,
              callID: call.id,
              timeoutSeconds: 2))
          .then((event.CallPark parkEvent) => validateCall(parkEvent.call));
    } else {
      return parkAction;
    }
  }

  /**
   * Returns a Future that completes when an inbound call is
   * received on _the phone_.
   */
  Future<Phonio.Call> waitForInboundCall() {
    log.finest('Receptionist $this waits for inbound call');

    bool match(Phonio.Event event) => event is Phonio.CallIncoming;

    if (this.currentCall != null) {
      log.finest('$this already has call, returning it.');

      return new Future(() => this.currentCall);
    }

    log.finest('$this waits for incoming call from event stream.');
    return this.phone.eventStream.firstWhere(match).then((_) {
      log.finest('$this got expected event, returning current call.');

      return this.currentCall;
    }).timeout(new Duration(seconds: 10));
  }

  /**
   * Returns a Future that completes when the phone associated with the
   * receptionist is hung up.
   */
  Future waitForPhoneHangup() {
    log.finest('Receptionist $this waits for call hangup');

    if (this.currentCall == null) {
      log.finest('$this already has no call, returning.');
      return new Future(() => null);
    }

    log.finest('$this waits for call hangup from event stream.');
    return this
        .phone
        .eventStream
        .firstWhere((Phonio.Event event) => event is Phonio.CallDisconnected)
        .then((_) {
      log.finest('$this got expected event, returning current call.');
      return null;
    }).timeout(new Duration(seconds: 10));
  }

  /**
   * Hangs up phone of receptionist directly from the phone.
   */
  Future phoneHangupAll() async {
    log.finest('$this hangs up phone');

    if (this.currentCall == null) {
      log.finest('$this already has no call, returning.');
      return;
    }

    await this.phone.hangupAll();
  }

  /**
   * Originates a new call to [extension] via the [CallFlowControl] service.
   */
  Future<model.Call> originate(
          String extension, model.OriginationContext context) =>
      callFlowControl.originate(extension, context);

  /**
   * Hangup [call]  via the [CallFlowControl] service.
   */
  Future hangUp(model.Call call) =>
      this.callFlowControl.hangup(call.id).catchError((error, stackTrace) {
        log.severe(
            'Tried to hang up call with info ${call.toJson()}. Receptionist info ${toJson()}',
            error,
            stackTrace);
      });

  /**
   * Hangup all active calls currently connected to the phone.
   */
  Future hangupAll() => this.phone.hangup();

  /**
   * Waits for an arbitrary event identified either by [eventType], [callID],
   * [extension], [receptionID], or a combination of them. The method will
   * wait for, at most, [timeoutSeconds] before returning a Future error.
   */
  Future<event.Event> waitFor(
      {String eventType: null,
      String callID: null,
      String extension: null,
      int receptionID: null,
      int timeoutSeconds: 10}) {
    if (eventType == null &&
        callID == null &&
        extension == null &&
        receptionID == null) {
      return new Future.error(
          new ArgumentError('Specify at least one parameter to wait for'));
    }

    bool matches(event.Event e) {
      bool result = false;
      if (eventType != null) {
        result = e.eventName == eventType;
      }

      if (callID != null && e is event.CallEvent) {
        result = result && e.call.id == callID;
      }

      if (extension != null && e is event.CallEvent) {
        result = result && e.call.destination == extension;
      }

      if (receptionID != null && e is event.CallEvent) {
        result = result && e.call.rid == receptionID;
      }
      return result;
    }

    event.Event lookup =
        (this.eventStack.firstWhere(matches, orElse: () => null));

    if (lookup != null) {
      return new Future(() => lookup);
    }
    log.finest(
        'Event is not yet received, waiting for maximum $timeoutSeconds seconds');

    return notificationSocket.onEvent
        .firstWhere(matches)
        .timeout(new Duration(seconds: timeoutSeconds))
        .catchError((error, stackTrace) {
      log.severe(error, stackTrace);
      log.severe('Parameters: eventType:$eventType, '
          'callID:$callID, '
          'extension:$extension, '
          'receptionID:$receptionID');
      this.dumpEventStack();
      return new Future.error(error, stackTrace);
    });
  }

  /**
   * Perform a call pickup via the [CallFlowControl] service. May optionally
   * set [waitForEvent] that will make this method wait until the notification
   * socket confirms the the call was picked up.
   * This method picks up a specific call.
   */
  Future pickup(model.Call call, {waitForEvent: false}) {
    Future pickupAction = this.callFlowControl.pickup(call.id);

    if (waitForEvent) {
      return pickupAction
          .then((_) =>
              this.waitFor(eventType: event.Key.callPickup, callID: call.id))
          .then((event.CallPickup pickupEvent) => pickupEvent.call);
    } else {
      return pickupAction;
    }
  }

  /**
   * Hunts down the next available call, regardless of lockstate. The Future
   * returned will complete only after the call has been confirmed connected
   * via the notification socket (a call_pickup event is received).
   */
  Future<model.Call> huntNextCall() {
    model.Call selectedCall;

    Future<model.Call> pickupAfterCallUnlock() {
      log.info('Call not aquired. $this expects the call to be locked.');

      return this
          .waitFor(
              eventType: event.Key.callLock,
              callID: selectedCall.id,
              timeoutSeconds: 10)
          .then((_) =>
              log.info('Call $selectedCall was locked, waiting for unlock.'))
          .then((_) => this.waitFor(
              eventType: event.Key.callUnlock, callID: selectedCall.id))
          .then(
              (_) => log.info('Call $selectedCall got unlocked, picking it up'))
          .then((_) => this.pickup(selectedCall, waitForEvent: true));
    }

    log.info('$this goes hunting for a call.');
    return this
        .waitForCallOffer()
        .then((model.Call offeredCall) => selectedCall = offeredCall)
        .then((_) => log.fine('$this attempts to pickup $selectedCall.'))
        .then((_) => this
                .pickup(selectedCall, waitForEvent: true)
                .then((model.Call pickedUpCall) {
              log.info('$this got call $pickedUpCall');
              return pickedUpCall;
            }).catchError((error, stackTrace) {
              if (error is storage.Conflict) {
                // Call is locked.
                return pickupAfterCallUnlock();
              } else if (error is storage.NotFound) {
                // Call is hungup

                callEventsOnSelecteCall(event.Event e) {
                  if (e is event.CallEvent) return e.call.id == selectedCall.id;
                }

                log.info('$this waits for $selectedCall to hangup');
                this
                    .waitFor(
                        eventType: event.Key.callHangup,
                        callID: selectedCall.id,
                        timeoutSeconds: 2)
                    .then((event.CallHangup hangupEvent) {
                  this.eventStack.removeWhere(callEventsOnSelecteCall);

                  // Reschedule the hunting.
                  return this.huntNextCall();
                });

                this.dumpEventStack();
                throw new StateError(
                    'Expected call to hung up, but no hangup event was received.');
              } else {
                log.severe('huntNextCall experienced an unexpected error.');
                log.severe(error, stackTrace);
                return new Future.error(error, stackTrace);
              }
            }));
  }

  /**
   * Convenience function for waiting for the next call being offered to the
   * receptionist.
   */
  Future<model.Call> waitForCallOffer() => this
      .waitFor(eventType: event.Key.callOffer)
      .then((event.CallOffer offered) => offered.call);

  /**
   * Event handler for events coming from the notification server.
   * Merely pushes events onto a stack.
   */
  void _handleEvent(event.Event event) {
    // Only push actual events to the event stack.
    if (event == null) {
      log.warning('Null event received!');
      return;
    }

    eventStack.add(event);
  }

  /**
   * Debug-friendly representation of the receptionist.
   */
  @override
  String toString() => 'Receptionist:${this.user.name}, uid:${this.user.id}, '
      'Phone:${this.phone}';

  /**
   * Event handler for events coming from the phone. Updates the call state
   * of the receptionist.
   */
  void _onPhoneEvent(Phonio.Event event) {
    if (event is Phonio.CallOutgoing) {
      log.finest('$this received call outgoing event');
      Phonio.Call call = new Phonio.Call(
          event.callID, event.callee, false, phone.defaultAccount.username);
      log.finest('$this sets call to $call');

      this.currentCall = call;
    } else if (event is Phonio.CallIncoming) {
      log.finest('$this received incoming call event');
      Phonio.Call call = new Phonio.Call(
          event.callID, event.callee, false, phone.defaultAccount.username);
      log.finest('$this sets call to $call');
      this.currentCall = call;
    } else if (event is Phonio.CallDisconnected) {
      log.finest('$this received call diconnect event');

      this.currentCall = null;
    } else {
      log.severe('$this got unhandled event ${event.eventName}');
    }
  }

  /**
   * Pause the receptionist.
   */
  Future pause(Service.RESTUserStore userStore) =>
      userStore.userStatePaused(user.id);
}
