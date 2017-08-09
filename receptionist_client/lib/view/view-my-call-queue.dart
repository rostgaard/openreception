/*                  This file is part of OpenReception
                   Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orc.view;

/**
 * Show the my call queue and registers keyboard shortcuts for call handling.
 *
 * TODO(TL): Clean this doc:
 *   This reloads the call queue list at a fixed refresh rate of ...
 */
class MyCallQueue extends ViewWidget {
  final ui_model.AppClientState _appState;
  final controller.Call _callController;
  bool _callControllerBusy = false;
  final ui_model.UIContactData _contactData;
  final ui_model.UIContactSelector _contactSelector;
  String _contextCallId = '';
  bool _homeIsFocused = true;
  final Map<String, String> _langMap;
  final Logger _log = new Logger('$libraryName.MyCallQueue');
  final controller.Destination _myDestination;
  final controller.Notification _notification;
  final controller.Popup _popup;
  final ui_model.UIReceptionSelector _receptionSelector;
  final ui_model.UIMyCallQueue _uiModel;
  final ui_model.UIMessageCompose _uiModelMessageCompose;

  /**
   * Constructor.
   */
  MyCallQueue(
      ui_model.UIMyCallQueue this._uiModel,
      ui_model.UIMessageCompose this._uiModelMessageCompose,
      ui_model.AppClientState this._appState,
      controller.Destination this._myDestination,
      controller.Notification this._notification,
      controller.Call this._callController,
      controller.Popup this._popup,
      Map<String, String> this._langMap,
      ui_model.UIContactData this._contactData,
      ui_model.UIContactSelector this._contactSelector,
      ui_model.UIReceptionSelector this._receptionSelector) {
    _loadCallList();

    _observers();
  }

  @override
  controller.Destination get _destination => _myDestination;
  @override
  ui_model.UIMyCallQueue get _ui => _uiModel;

  @override
  void _onBlur(controller.Destination _) {}
  @override
  void _onFocus(controller.Destination _) {}

  /**
   * Simply navigate to my [Destination]. Matters not if this widget is already
   * focused.
   */
  void _activateMe() {
    _navigateToMyDestination();
  }

  /**
   * Tries to dial the [phoneNumber].
   *
   * If this is called while `activeCall` of [_appState] is not
   * [model.Call.noCall]
   * then mark both calls ready for transfer.
   */
  Future _call(model.PhoneNumber phoneNumber) async {
    model.Call parkedCall;
    bool markTransfer = _appState.activeCall == model.Call.noCall &&
        _ui.markedForTransfer.length == 1;
    bool parkAndMarkTransfer = _appState.activeCall != model.Call.noCall &&
        _ui.markedForTransfer.length < 2;

    if (parkAndMarkTransfer) {
      _ui.removeTransferMarks();
      parkedCall = await park(_appState.activeCall);
      _ui.markForTransfer(parkedCall);
      _log.info('marked ${parkedCall.id} for transfer');
    }

    _busyCallController();
    try {
      model.Call newCall =
          await _callController.dial(phoneNumber, _appState.originationContext);
      if (markTransfer || parkAndMarkTransfer) {
        _ui.markForTransfer(newCall);
        _log.info('marked ${newCall.id} for transfer');
      }
    } catch (error) {
      _error(error, _langMap[Key.callFailed], phoneNumber.destination);
      _log.warning('dialing failed with $error');
    }

    _contactData.removeRinging();

    await _readyCallController();
  }

  /**
   * Mark the call controller busy. This is just a simply protection against
   * hammering the call controller with too many commands.
   */
  void _busyCallController() {
    _callControllerBusy = true;
  }

  /**
   * Clear stale calls from the call list
   */
  void clearStaleCalls() {
    _ui.calls.forEach((model.Call call) {
      _callController.get(call.id).then((model.Call c) {
        if (c == model.Call.noCall || c.state == model.CallState.transferred) {
          if (c.id == contextCallId) {
            contextCallId = '';
          }
          _ui.removeCall(c);
          _log.info('removing stale call ${c.id} from queue');
        }
      });
    });
  }

  /**
   * Return the contextCallId string.
   */
  String get contextCallId => _contextCallId;

  /**
   * Set the contextCallId string.
   */
  set contextCallId(String id) {
    _contextCallId = id == null ? '' : id;
    _log.info('contextCallId set to "$id"');
  }

  /**
   *  Mark the call controller ready. This operation is delayed 100ms, to
   *  prevent against agents spamming commands at the call controller.
   */
  Future _readyCallController() {
    return new Future.delayed(
        new Duration(milliseconds: 100), () => _callControllerBusy = false);
  }

  /**
   * Popup with errors.
   */
  void _error(error, String title, String message) {
    if (error is controller.BusyException) {
      _popup.error(
          _langMap[Key.errorSystem], _langMap[Key.errorCallControllerBusy]);
    } else {
      _popup.error(title, message);
    }
  }

  /**
   * Add, remove, update the queue list, depending on the `call` state of [event].
   */
  void _handleCallStateChanges(or_event.CallEvent event) {
    if (event.call.assignedTo != _appState.currentUser.id) {
      return;
    }

    switch (event.call.state) {
      case model.CallState.created:
        if (!event.call.inbound) {
          /// My outbound call.
          _ui.appendCall(event.call);
        }
        break;

      case model.CallState.hungup:
      case model.CallState.transferred:
        if (event.call.id == contextCallId) {
          contextCallId = '';
        }

        _ui.removeCall(event.call);
        break;

      default:
        _ui.updateCall(event.call);
        break;
    }
  }

  /**
   * Load the list of calls assigned to current user and not being transferred.
   * Updates `activeCall` of [_appState] if any call is detected as being active.
   */
  void _loadCallList() {
    bool isMine(model.Call call) =>
        call.assignedTo == _appState.currentUser.id &&
        call.state != model.CallState.transferred;

    _callController.listCalls().then((Iterable<model.Call> calls) {
      Iterable<model.Call> myCalls = calls.where(isMine);
      _ui.calls = myCalls.toList(growable: false);
      _appState.activeCall = myCalls.firstWhere(
          (model.Call call) =>
              call.state == model.CallState.speaking ||
              call.state == model.CallState.ringing,
          orElse: () => model.Call.noCall);
    });
  }

  /**
   * Observers.
   */
  void _observers() {
    _navigate.onGo.listen((controller.Destination destination) {
      _homeIsFocused = destination.context == controller.Context.home;
      _setWidgetState;
    });

    _ui.onClick.listen((MouseEvent _) => _activateMe());

    _ui.onDblClick.listen((model.Call call) => unpark(call: call));

    _receptionSelector.onSelect.listen((model.Reception reception) {
      if (_appState.activeCall == model.Call.noCall ||
          !_appState.activeCall.inbound) {
        contextCallId = '';
      }
    });

    /// Transfer
    _hotKeys.onCtrlNumMinus.listen((_) {
      final Iterable<model.Call> calls = _ui.markedForTransfer;

      if (!_callControllerBusy &&
          _appState.activeCall != model.Call.noCall &&
          calls.length == 2 &&
          calls.any((model.Call call) => _appState.activeCall == call)) {
        final model.Call source = calls.firstWhere(
            (model.Call call) => call.id == _appState.activeCall.id);
        final model.Call destination = calls.firstWhere(
            (model.Call call) => call.id != _appState.activeCall.id);

        _busyCallController();

        _callController.transfer(source, destination).then((_) {
          if (source.id == contextCallId || destination.id == contextCallId) {
            contextCallId = '';
          }
          clearStaleCalls();
        }).catchError((error) {
          _error(error, _langMap[Key.errorCallTransfer],
              'ID ${_appState.activeCall.id}');
          _log.warning('transfer failed with $error');
        }).whenComplete(() => _readyCallController());
      }
    });

    /// Park
    _hotKeys.onF7.listen((KeyboardEvent _) => park(_appState.activeCall));

    /// Unpark
    _hotKeys.onF8.listen((_) => unpark());

    /// Hangup
    _hotKeys.onNumDiv.listen((_) {
      if (!_callControllerBusy && _appState.activeCall != model.Call.noCall) {
        _callControllerBusy = true;
        final hangupCallId = _appState.activeCall.id;
        _callController.hangup(_appState.activeCall).then((_) {
          if (hangupCallId == contextCallId) {
            contextCallId = '';
          }
          clearStaleCalls();
        }).catchError((error) {
          _error(error, _langMap[Key.errorCallHangup],
              'ID ${_appState.activeCall.id}');
          _log.warning('hangup failed with $error');
        }).whenComplete(() => _readyCallController());
      }
    });

    /// Pickup new call
    _hotKeys.onNumPlus.listen((_) {
      if (_homeIsFocused &&
          _uiModelMessageCompose.noMessage &&
          !_callControllerBusy) {
        _busyCallController();
        _receptionSelector.refreshReceptions();

        _callController.pickupNext().then((model.Call call) {
          contextCallId = call.id;
          _ui.removeTransferMarks();
          clearStaleCalls();
        }).catchError((error) {
          _error(error, _langMap[Key.errorCallNotFound],
              _langMap[Key.errorCallNotFoundExtended]);
          _log.warning('pickup failed with $error');
        }).whenComplete(() => _readyCallController());
      }
    });

    /// Make call
    _hotKeys.onNumMult.listen((KeyboardEvent _) => _setRinging());
    _contactData.onMarkedRinging.listen(_call);

    _notification.onAnyCallStateChange.listen(_handleCallStateChanges);
  }

  /**
   * Park [call].
   */
  Future<model.Call> park(model.Call call) async {
    model.Call parkedCall = model.Call.noCall;

    if (!_callControllerBusy && call != model.Call.noCall) {
      try {
        _busyCallController();
        parkedCall = await _callController.park(call);
      } catch (error) {
        _error(error, _langMap[Key.errorCallPark],
            'ID ${_appState.activeCall.id}');
        _log.warning('parking failed with $error');
      }
    }

    await _readyCallController();

    return parkedCall;
  }

  /**
   * If no phonenumber is marked ringing, mark the currently selected phone
   * number ringing.
   */
  void _setRinging() {
    _contactData.ring();
  }

  /**
   * Unpark the first parked call or the given [call].
   */
  void unpark({model.Call call}) {
    if (!_callControllerBusy &&
        _appState.activeCall == model.Call.noCall &&
        _ui.calls
            .any((model.Call call) => call.state == model.CallState.parked)) {
      _busyCallController();
      final Future<model.Call> unparkCall = call != null
          ? _callController.pickup(call)
          : _callController.pickupFirstParkedCall();

      unparkCall.then((model.Call call) {
        if (call.inbound) {
          contextCallId = call.id;
        }
        clearStaleCalls();
      }).catchError((error) {
        _error(error, _langMap[Key.errorCallUnpark], '');
        _log.warning('unpark failed with $error');
      }).whenComplete(() => _readyCallController());
    }
  }
}
