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
 * Show the global call queue and registers keyboard shortcuts for call handling.
 *
 * TODO(TL): Clean this doc:
 *   This reloads the call queue list at a fixed refresh rate of ...
 */
class GlobalCallQueue extends ViewWidget {
  final ui_model.AppClientState _appState;
  final controller.Call _callController;
  DateTime _lastPling = new DateTime.now();
  final controller.Destination _myDestination;
  final controller.Notification _notification;
  final controller.Sound _sound;
  final ui_model.UIGlobalCallQueue _uiModel;
  model.UserStatus _userState;

  /**
   * Constructor.
   */
  GlobalCallQueue(
      ui_model.UIGlobalCallQueue this._uiModel,
      ui_model.AppClientState this._appState,
      controller.Destination this._myDestination,
      controller.Notification this._notification,
      controller.Call this._callController,
      controller.Sound this._sound,
      model.UserStatus this._userState) {
    _loadCallList();

    _observers();
  }

  @override
  controller.Destination get _destination => _myDestination;
  @override
  ui_model.UIGlobalCallQueue get _ui => _uiModel;

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
   * Add, remove, update the queue list, depending on the state of `call`
   * carried in [event].
   */
  void _handleCallStateChanges(or_event.CallEvent event) {
    final model.Call call = event.call;

    if (event is or_event.CallOffer) {
      _ui.appendCall(call);
      _pling();
    } else if (event is or_event.CallHangup ||
        call.assignedTo != model.User.noId) {
      _ui.removeCall(call);
    } else if (call.inbound) {
      _ui.updateCall(call);
    }
  }

  /**
   * Load the list of calls not currently assigned to anybody.
   */
  void _loadCallList() {
    bool unassigned(model.Call call) => call.assignedTo == model.User.noId;

    _callController.listCalls().then((Iterable<model.Call> calls) {
      _ui.calls = calls.where(unassigned).toList(growable: false);
    });
  }

  /**
   * Observers.
   */
  void _observers() {
    _navigate.onGo.listen(_setWidgetState);

    _ui.onClick.listen((MouseEvent _) => _activateMe());

    _notification.onAnyCallStateChange.listen(_handleCallStateChanges);

    /**
     * Change the user/agent state for the currently logged in user.
     */
    _notification.onAgentStateChange.listen((model.UserStatus userStatus) {
      if (userStatus.userId == _appState.currentUser.id) {
        _userState = userStatus;
      }
    });

    /**
     * Check each second to see if it is time to pling!
     */
    new Timer.periodic(new Duration(seconds: 1), (_) {
      _pling();
    });
  }

  /**
   * Pling - if:
   *  there are calls in the queue AND
   *  appState.activeCall is NOT noCall AND
   *  the agent state is idle or unknown AND
   *  >= 5 seconds have passed since the previous ping.
   */
  void _pling() {
    final DateTime now = new DateTime.now();
    final Duration difference = now.difference(_lastPling);
    if (difference.inSeconds >= 5 &&
        _ui.hasCalls &&
        _appState.activeCall == model.Call.noCall &&
        !_userState.paused) {
      _lastPling = now;
      _sound.pling();
    }
  }
}
