part of ort.support;

/// TODO: Implement event stack here instead of just perform logic based on the
/// current call.
class Customer {
  static final Logger _log = Logger('Customer');

  String get extension => '${this.phone.contact}';

  Phonio.Call currentCall = null;
  Iterable<Phonio.Call> get call => phone.activeCalls;

  /// The amout of time the actor will wait before answering an incoming call.
  Duration answerLatency = Duration(seconds: 0);

  Phonio.SIPPhone phone = null;
  Stream<Phonio.Event> get phoneEvents => phone.eventStream;
  String get name => this.phone.defaultAccount.username;
  StreamSubscription eventSubscription = null;

  Customer(this.phone);

  Map toJson() => {
        'id': this.hashCode,
        'current_call': currentCall,
        'extension': extension
      };

  @override
  int get hashCode => this.phone.contact.hashCode;

  /**
   *
   */
  Future initialize() => this.phone.initialize().then((_) => eventSubscription =
      this.phone.eventStream.listen(this._onPhoneEvent,
          onDone: () => _log.fine('$this closing event listener.')));

  teardown() {
    _log.fine('$this Waiting for teardown');

    return this
        .phone
        .teardown()
        .then((_) => _log.fine('$this Got phone teardown'))
        .then((_) => this.currentCall = null)
        .then((_) => _log.fine('$this is done teardown'))
        .then((_) => Future.delayed(Duration(milliseconds: 10)))
        .catchError((error, stackTrace) {
      _log.severe(
          'Potential race condition in teardown of Customer, ignoring as test error, but logging it');
      _log.severe(error, stackTrace);
    });
  }

  Future Wait_For_Dialtone() => this.waitForInboundCall();

  Future autoAnswer(bool enabled) => this.phone.autoAnswer(enabled);

  /// Dials an extension and returns a future with a call object.
  Future<Phonio.Call> dial(String extension) {
    _log.finest('$this dials $extension');

    return this
        .phone
        .originate('$extension@${this.phone.defaultAccount.server}');
  }

  /// TODO Use event Stack instead.
  Future waitForHangup() {
    _log.finest('$this waits for current call to vanish.');
    //TODO: Assert that the call is not and is acutally outbound.
    if (this.currentCall == null) {
      _log.finest('$this already has no call, returning it.');
      return Future.value(null);
    }

    _log.finest('$this waits for call disconnect from event stream.');
    return this
        .phone
        .eventStream
        .firstWhere((Phonio.Event event) => event is Phonio.CallDisconnected)
        .then((_) {
      _log.finest('$this got expected event, returning .');
      return Future.value(null);
    }).timeout(Duration(seconds: 10));
  }

  pickupCall() => this.phone.answer();

  pickup(Phonio.Call call) => this.phone.answerSpecific(call);

  Future hangup(Phonio.Call call) => phone.hangupSpecific(call);

  Future hangupAll() => this.phone.hangupAll();

  Future finalize() =>
      phone.ready ? teardown().then((_) => phone.finalize()) : phone.finalize();

  /// Returns a Future that completes when an outbound call is confirmed placed.
  Future<Phonio.Call> waitForOutboundCall() {
    _log.finest('$this waits for outbound call');
    //TODO: Assert that the call is not answered and is acutally outbound.
    if (this.currentCall != null) {
      _log.finest('$this already has call, returning it.');
      return Future(() => this.currentCall);
    }

    _log.finest('$this waits for outgoing call from event stream.');
    return this
        .phone
        .eventStream
        .firstWhere((Phonio.Event event) => event is Phonio.CallOutgoing)
        .then((_) {
      _log.finest('$this got expected event, returning current call.');
      return this.currentCall;
    }).timeout(Duration(seconds: 10));
  }

  /// Returns a Future that completes when an inbound call is received.
  Future<Phonio.Call> waitForInboundCall() {
    _log.finest('$this waits for inbound call');
    //TODO: Assert that the call is not answered and is actually inbound.
    if (this.currentCall != null) {
      _log.finest('$this already has call, returning it.');
      return Future.value(this.currentCall);
    }

    _log.finest('$this waits for incoming call from event stream.');
    return this
        .phone
        .eventStream
        .firstWhere((Phonio.Event event) => event is Phonio.CallIncoming)
        .then((_) {
      _log.finest('$this got expected event, returning current call.');
      return this.currentCall;
    }).timeout(Duration(seconds: 10));
  }

  @override
  String toString() => 'Customer peerID:${this.phone.id} '
      'PhoneType:${this.phone.runtimeType}';

  void _onPhoneEvent(Phonio.Event event) {
    if (event is Phonio.CallOutgoing) {
      _log.finest('$this received call outgoing event');
      Phonio.Call call = Phonio.Call(
          event.callId, event.callee, false, phone.defaultAccount.username);
      _log.finest('$this sets call to $call');

      this.currentCall = call;
    } else if (event is Phonio.CallIncoming) {
      _log.finest('$this received incoming call event');
      Phonio.Call call = Phonio.Call(
          event.callId, event.callee, false, phone.defaultAccount.username);
      _log.finest('$this sets call to $call');
      this.currentCall = call;

      //this._handleIncomingCall();
    } else if (event is Phonio.CallDisconnected) {
      _log.finest('$this received call diconnect event');
      //this._handleDisconnectedCall();
      this.currentCall = null;
    } else {
      _log.severe('$this got unhandled event ${event.eventName}');
    }
  }

  // void _handleIncomingCall() {
  //   //TODO: Check if phone autoanswer is enabled and return if so.
  //   if (this.answerLatency.isNegative) {
  //     return;
  //   } else {
  //     // Schedule a pickup later on.
  //     Future.delayed(this.answerLatency,
  //         () => this.phone.answer())
  //     .catchError((error, stackTrace) => log.severe(error, stackTrace));
  //   }
  // }
  //
  // void _handleDisconnectedCall() {
  //   log.finest('Clearing current call');
  //   this.currentCall = null;
  // }
}
