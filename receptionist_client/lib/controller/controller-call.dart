part of orc.controller;

enum CallCommand {
  pickup,
  pickupSuccess,
  pickupFailure,
  dial,
  dialSuccess,
  dialFailure,
  hangup,
  hangupSuccess,
  hangupFailure,
  park,
  parkSuccess,
  parkFailure,
  transfer,
  transferSuccess,
  transferFailure
}

/// Is thrown when a [Call] object is busy talking to the server.
class BusyException implements Exception {
  /// Constructor.
  const BusyException([this.message = ""]);
  
  /// Exception error message.
  final String message;

  @override
  String toString() => "BusyException: $message";
}

/// Exposes methods for call operations.
class Call {

  /// Constructor.
  Call(service.CallFlowControl this._service,
      ui_model.AppClientState this._appState);

  final ui_model.AppClientState _appState;
  bool _busyFlag = false;
  final Bus<CallCommand> _command = new Bus<CallCommand>();
  static final Logger _log = new Logger('$libraryName.Call');
  final service.CallFlowControl _service;



  /**
   * Return true if the Call object is already busy talking to the server.
   */
  bool get busy => _busyFlag;

  /**
   * Set the [_busyFlag] state. This marks whether the class is busy talking to the server.
   *
   * This throws a [BusyException] if we're already busy.
   */
  set _busy(bool makeBusy) {
    if (_busyFlag && makeBusy) {
      throw new BusyException('CallController busy');
    }

    _busyFlag = makeBusy;
  }

  /**
   * Returns a stream of [CallCommand] enums.
   */
  Stream<CallCommand> get commandStream => _command.stream;

  /**
   * Tries to dial [phoneNumber] in the supplied [context] which sets reception id
   * and contact id. The call id may also be also set and if set, creates a
   * reference between the newly created call and the given id.
   */
  Future<model.Call> dial(
      model.PhoneNumber phoneNumber, model.OriginationContext context) async {
    _log.info('Dialing ${phoneNumber.destination}.');

    _busy = true;

    _command.fire(CallCommand.dial);

    return await _service
        .originate(phoneNumber.destination, context)
        .then((model.Call call) {
      _command.fire(CallCommand.dialSuccess);

      return call;
    }).catchError((Error error, StackTrace stackTrace) {
      _log.severe(error, stackTrace);
      _command.fire(CallCommand.dialFailure);

      return new ControllerError(error.toString());
    }).whenComplete(() => _busy = false);
  }

  /**
   * Returns the first parked call.
   */
  Future<model.Call> _firstParkedCall() async {
    final Iterable<model.Call> calls = await _service.callList();

    return calls.firstWhere(
        (model.Call call) =>
            call.assignedTo == _appState.currentUser.id &&
            call.state == model.CallState.parked,
        orElse: () => model.Call.noCall);
  }

  /**
   * Returns the [callId] [model.Call].
   *
   * Returns [ORModel.Call.noCall] if [callId] does not exist.
   */
  Future<model.Call> get(String callId) async {
    try {
      return await _service.get(callId);
    } catch (error) {
      return model.Call.noCall;
    }
  }

  /**
   * Tries to hangup [call].
   */
  Future hangup(model.Call call) {
    _busy = true;

    _command.fire(CallCommand.hangup);

    _log.info('Hanging up $call.');

    return _service
        .hangup(call.id)
        .then((_) => _command.fire(CallCommand.hangupSuccess))
        .catchError((Error error, StackTrace stackTrace) {
      _log.severe(error, stackTrace);
      _command.fire(CallCommand.hangupFailure);

      return Future<ControllerError>.error(ControllerError(error.toString()));
    }).whenComplete(() => _busy = false);
  }

  /**
   * Returns a list of current calls.
   */
  Future<Iterable<model.Call>> listCalls() => _service.callList();

  /**
   * Tries to park [call].
   */
  Future<model.Call> park(model.Call call) async {
    if (call == model.Call.noCall) {
      return model.Call.noCall;
    }

    _busy = true;
    _command.fire(CallCommand.park);

    return await _service.park(call.id).then((model.Call parkedCall) {
      _command.fire(CallCommand.parkSuccess);

      _log.info('Parking $parkedCall');

      return parkedCall;
    }).catchError((Error error, StackTrace stackTrace) {
      _log.severe(error, stackTrace);
      _command.fire(CallCommand.parkFailure);

      throw new ControllerError(error.toString());
    }).whenComplete(() => _busy = false);
  }

  /**
   * Returns a list of peers.
   */
  Future<Iterable<model.Peer>> peerList() => _service.peerList();

  /**
   * Make the service layer perform a pickup request to the call-flow-control server.
   */
  Future<model.Call> pickup(model.Call call) async {
    _busy = true;

    _command.fire(CallCommand.pickup);

    _log.info('Picking up $call.');

    return await _service.pickup(call.id).then((model.Call call) {
      _command.fire(CallCommand.pickupSuccess);

      return call;
    }).catchError((Error error, StackTrace stackTrace) {
      _log.severe(error, stackTrace);
      _command.fire(CallCommand.pickupFailure);

      throw new ControllerError(error.toString());
    }).whenComplete(() => _busy = false);
  }

  /**
   * Tries to pickup the first parked call and returns it if successful.
   */
  Future<model.Call> pickupFirstParkedCall() async {
    final model.Call parkedCall = await _firstParkedCall();

    if (parkedCall != model.Call.noCall) {
      return pickup(parkedCall);
    } else {
      return model.Call.noCall;
    }
  }

  /**
   * Requests the next available call, and returns it if successful.
   */
  Future<model.Call> pickupNext() async {
    _busy = true;
    bool availableForPickup(model.Call call) =>
        call.assignedTo == model.User.noId && !call.locked;

    Iterable<model.Call> calls = await _service.callList();
    model.Call foundCall =
        calls.firstWhere(availableForPickup, orElse: () => null);

    _busy = false;

    if (foundCall != null) {
      return await pickup(foundCall);
    } else {
      return model.Call.noCall;
    }
  }

  /**
   * Tries to pickup [call] and returns it if successful.
   */
  Future<model.Call> pickupParked(model.Call call) => pickup(call);

  /**
   * Tries to transfer the [source] call to [destination].
   */
  Future _transfer(model.Call source, model.Call destination) async {
    _busy = true;
    _command.fire(CallCommand.transfer);

    try {
      await _service.transfer(source.id, destination.id);
      _command.fire(CallCommand.transferSuccess);

    } catch (error, stackTrace) {
    _log.severe(error, stackTrace);
    _command.fire(CallCommand.transferFailure);
    } finally {
     _busy = false;
    }
  }

  /**
   * Tries to transfer [source] to [destination].
   */
  Future transfer(model.Call source, model.Call destination) {
    return _transfer(source, destination);
  }

  /**
   * Tries to transfer [source] to the first parked call.
   */
  Future<void> transferToFirstParkedCall(model.Call source) async {
    final model.Call parkedCall = await _firstParkedCall();

    await _transfer(source, parkedCall);
  }
}
