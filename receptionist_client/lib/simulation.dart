/*                  This file is part of OpenReception
                   Copyright (C) 2014-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

library orc.simulation;

import 'dart:async';
import 'dart:html';
import 'dart:math' show Random;

import 'package:logging/logging.dart';
import 'package:orc/controller/controller.dart' as controller;
import 'package:orc/model/model.dart' as ui_model;
import 'package:orf/model.dart' as model;

_Simulation simulation = new _Simulation();

controller.SimulationHotKeys key =
    new controller.SimulationHotKeys(new controller.HotKeys());

/// Important. Fill out this one with actual PSTN numbers.
List<String> calleeNumbers = [];

/// Automated simulation of the UI.
class _Simulation {
  final Random _rand = new Random(new DateTime.now().millisecondsSinceEpoch);
  ui_model.AppClientState _appState;
  final Logger _log = new Logger('_Simulation');
  final Duration _oneSecond = new Duration(milliseconds: 1000);

  controller.Call _callController;
  Duration _actionTimeout = new Duration(seconds: 30);

  OListElement get _callQueue => querySelector('#global-call-queue ol');

  OListElement get _localCalls => querySelector('#my-call-queue ol');

  model.Call get _activeCall => _appState.activeCall;

  UListElement get _infoBox => querySelector('ul#simulation-info');

  ParagraphElement get _stateBox => querySelector('p#simulation-state');

  SpanElement get _showPstnBox => querySelector('#contact-data span.show-pstn');
  InputElement get _pstnInputField => querySelector('#contact-data input.pstn');

  bool get _isInCall => querySelector('.greeting').classes.contains('incall');

  bool get _callsInCallQueue => _callQueue.children.length > 0;

  bool get _hasLocalCalls => _localCalls.children.length > 0;
  int get _numLocalCalls => _localCalls.children.length;

  int get randomResponseTime => _rand.nextInt(900) + 100;
  Duration get randomDelay => new Duration(milliseconds: randomResponseTime);

  dynamic _randomChoice(List pool) {
    if (pool.isEmpty) {
      throw new ArgumentError('Cannot find a random value in an empty list');
    }

    int index = _rand.nextInt(pool.length);

    return pool[index];
  }

  void _refreshInfo(model.Call activeCall) {
    _stateBox.text = 'call:$activeCall';
  }

  Future _checkState() async {
    await _sleep(_oneSecond);

    /// In call
    if (_isInCall) {
      _log.info('Active call detected handling it');

      try {
        await _sleep(randomDelay);
        await _handleActiveCall().timeout(_actionTimeout);
      } catch (_) {}
    }

    /// has parked calls
    else if (_hasLocalCalls) {
      _log.info('Calls detected in local call list.');

      try {
        await _sleep(randomDelay);
        await _handleParkedCall().timeout(_actionTimeout);
      } catch (_) {}
    }

    /// Calls are available for pickup
    else if (_callsInCallQueue) {
      _log.info('Calls detected in call list, hunting one.');

      try {
        await _sleep(randomDelay);
        await _continouslyPickup().timeout(_actionTimeout);
      } catch (_) {}
    }

    await _checkState();
  }

  Future _unparkCall() async {
    _log.info('Picking up parked call');
    Future tryPickup() async {
      Future response =
          _nextOfAny([controller.CallCommand.pickup]).timeout(randomDelay);

      key.f8();
      await response;

      return await _nextOfAny([
        controller.CallCommand.pickupFailure,
        controller.CallCommand.pickupSuccess
      ]);
    }

    await Future.doWhile(() async {
      controller.CallCommand response;

      await Future.doWhile(() async {
        try {
          response = await tryPickup();
          return false;
        } on TimeoutException {
          return _hasLocalCalls;
        }
      });

      if (response == controller.CallCommand.pickupSuccess) {
        return false;
      } else {
        await _sleep(randomDelay);
        return _hasLocalCalls;
      }
    });
    _log.info('Picked up parked call');
  }

  Future _handleParkedCall() async {
    await _unparkCall();
    await _handleActiveCall();
  }

  Future _handleActiveCall() async {
    /// Determine what to do with the call.
    final int action = _randomChoice(new List.generate(10, (int i) => i));

    /// Take a message
    if (action < 5) {
      _log.info('Caller wants us to take a message');
      await _sleep(_oneSecond);
      await _hangupCall();
    }

    /// Try to perform a transfer.
    else {
      _log.info('Caller wants us to perform a transfer');
      await _sleep(_oneSecond);
      await _tryTransfer();
    }
  }

  void _observers() {
    _log.onRecord.listen((LogRecord rec) {
      if (_infoBox.children.length > 29) {
        _infoBox.children.first.remove();
      }

      _infoBox.append(new LIElement()..text = '$rec');
    });

    _checkState();

    _appState.activeCallChanged.listen(_refreshInfo);
  }

  Future _sleep(Duration duration) => new Future.delayed(duration);

  Future _continouslyPickup() async {
    Future tryPickup() async {
      Future response =
          _nextOfAny([controller.CallCommand.pickup]).timeout(randomDelay);

      key.numPlus();
      await response;

      return await _nextOfAny([
        controller.CallCommand.pickupFailure,
        controller.CallCommand.pickupSuccess
      ]);
    }

    await Future.doWhile(() async {
      controller.CallCommand response;

      await Future.doWhile(() async {
        try {
          response = await tryPickup();
          return false;
        } on TimeoutException {
          return !_isInCall;
        }
      });

      if (response == controller.CallCommand.pickupSuccess) {
        return false;
      } else {
        await _sleep(randomDelay);
        return !_isInCall;
      }
    });

    await _handleActiveCall();
  }

  void start(controller.Call cc, final ui_model.AppClientState as) {
    _callController = cc;
    _appState = as;

    setup();
    _observers();
    _log.info('Started simulation mode. DO NOT USE the interface manually!');
  }

  Future _hangupCall() async {
    Future sendHangup() async {
      Future response =
          _nextOfAny([controller.CallCommand.hangup]).timeout(randomDelay);

      key.numDiv();
      await response;

      return await _nextOfAny([
        controller.CallCommand.hangupFailure,
        controller.CallCommand.hangupSuccess
      ]);
    }

    await Future.doWhile(() async {
      controller.CallCommand response;

      await Future.doWhile(() async {
        try {
          response = await sendHangup();
          return false;
        } on TimeoutException {
          return _isInCall;
        }
      });

      if (response == controller.CallCommand.hangupSuccess) {
        return false;
      } else {
        await _sleep(randomDelay);
        return _isInCall;
      }
    });
    _log.info('Hung up call!');
  }

  Future<controller.CallCommand> _nextOfAny(
          List<controller.CallCommand> callCommands,
          {Duration timeout: const Duration(seconds: 10)}) =>
      _callController.commandStream.firstWhere(callCommands.contains);

  Future _performOrigination() async {
    await new Future.delayed(new Duration(seconds: 1));
    _showPstnBox.click();
    _pstnInputField.value = _randomChoice(calleeNumbers);

    Future sendOriginate() async {
      Future response =
          _nextOfAny([controller.CallCommand.dial]).timeout(randomDelay);

      key.numMult();
      await response;

      return await _nextOfAny([
        controller.CallCommand.dialSuccess,
        controller.CallCommand.dialFailure
      ]);
    }

    await Future.doWhile(() async {
      controller.CallCommand response;

      await Future.doWhile(() async {
        try {
          response = await sendOriginate();
          return false;
        } on TimeoutException {
          return _isInCall;
        }
      });

      if (response == controller.CallCommand.dialSuccess) {
        return false;
      } else {
        await _sleep(randomDelay);
        return !_isInCall;
      }
    });
    _log.info('Originated call!');

    await _outboundCallOK();
    _showPstnBox.click();
  }

  /// Poll and wait for the call to be picked up, hung up or just timed out.
  Future _outboundCallOK() async {
    final DateTime deadline = new DateTime.now().add(new Duration(seconds: 6));
    final Duration period = new Duration(milliseconds: 500);

    await Future.doWhile(() async {
      await new Future.delayed(period);

      _log.info(_activeCall.state);

      if (_activeCall == model.Call.noCall) {
        _log.info('Call hung up, returning');

        return false;
      }

      if (_activeCall.inbound) {
        _log.warning('Active call is inbound, bailing!');

        return false;
      }

      if (_activeCall.state == model.CallState.speaking) {
        _log.info('Call answered!');

        return false;
      }

      return deadline.isAfter(new DateTime.now());
    });

    if (_activeCall.state == model.CallState.ringing) {
      _log.info('Call was not answered within 6s. Hanging it up');
      await _hangupCall();
    }
  }

  Future _tryTransfer() async {
    await _performOrigination();

    if (!_isInCall) {
      _log.info('No outbound call - returning to ready');
      return;
    }

    Future sendTransfer() async {
      Future response =
          _nextOfAny([controller.CallCommand.transfer]).timeout(randomDelay);

      key.ctrlNumMinus();
      await response;

      return await _nextOfAny([
        controller.CallCommand.transferFailure,
        controller.CallCommand.transferSuccess
      ]);
    }

    _log.info('Outbound call is ready, performing transfer in 1 second');

    await _sleep(_oneSecond);

    if (_numLocalCalls < 2) {
      _log.info('Not enough calls to perform transfer');
      return;
    }

    await Future.doWhile(() async {
      controller.CallCommand response;

      await Future.doWhile(() async {
        try {
          response = await sendTransfer();
          return false;
        } on TimeoutException {
          return _isInCall;
        }
      });

      if (response == controller.CallCommand.transferSuccess) {
        return false;
      } else {
        await _sleep(randomDelay);
        return !_isInCall;
      }
    });
    _log.info('Transferred call!');
  }

  void setup() {
    hierarchicalLoggingEnabled = true;
    _callController.commandStream.listen((controller.CallCommand command) {
      _log.finest('Got $command');
    });

    DivElement root = new DivElement()
      ..id = 'simulation-overlay'
      ..style.margin = '5%'
      ..style.position = 'absolute'
      ..style.width = '90%'
      ..style.zIndex = '999'
      ..style.backgroundColor = 'rgba(255,255,255,0.65)'
      ..children = [
        new HeadingElement.h1()..text = 'Simulation mode. DO NOT USE INTERFACE',
        new ParagraphElement()..id = 'simulation-state',
        new UListElement()..id = 'simulation-info'
      ];

    querySelector('body').insertBefore(root, querySelector('#orc-ready'));
  }
}
