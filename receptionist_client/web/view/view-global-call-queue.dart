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

part of view;

/**
 * Show the global call queue and registers keyboard shortcuts for call handling.
 *
 * This reloads the call queue list at a fixed refresh rate of [_refreshRate].
 */
class GlobalCallQueue extends ViewWidget {
  final Controller.Destination  _myDestination;
  final Model.UIGlobalCallQueue _uiModel;
  final Controller.Call         _callController;
  final Controller.Notification _notifications;

  /**
   * Constructor.
   */
  GlobalCallQueue(Model.UIGlobalCallQueue this._uiModel,
                  Controller.Destination this._myDestination,
                  Controller.Notification this._notifications,
                  Controller.Call this._callController) {
    _loadCallList();

    _observers();
  }

  @override Controller.Destination  get _destination => _myDestination;
  @override Model.UIGlobalCallQueue get _ui          => _uiModel;

  @override void _onBlur(_){}
  @override void _onFocus(_){}

  /**
   * Simply navigate to my [Destination]. Matters not if this widget is already
   * focused.
   */
  void _activateMe(_) {
    _navigateToMyDestination();
  }

  /**
   * Add, remove, update the queue list, depending on the [call] state.
   */
  void _handleCallStateChanges(ORModel.Call call) {
    switch(call.state) {
      case ORModel.CallState.Created:
        _ui.appendCall(call);
        break;

      case ORModel.CallState.Hungup:
        _ui.removeCall(call);
        break;

      case ORModel.CallState.Speaking:
        _ui.removeCall(call);
        break;

      default:
        _ui.updateCall(call);
        break;
    }
  }

  /**
   * Load the list of calls not currently assigned to anybody.
   */
  void _loadCallList() {
    bool unassigned(ORModel.Call call) => call.assignedTo == ORModel.User.noID;

    _callController.listCalls().then((Iterable<ORModel.Call> calls) {
      _ui.calls = calls.where(unassigned).toList(growable: false);
    });
  }

  /**
   * Observers.
   */
  void _observers() {
    _navigate.onGo.listen(_setWidgetState);

    _ui.onClick.listen(_activateMe);

    _notifications.onAnyCallStateChange.listen(_handleCallStateChanges);

    _hotKeys.onNumPlus.listen((_) => _callController.pickupNext());

    _hotKeys.onNumDiv.listen((_) => _callController.hangup(ORModel.Call.activeCall));

    _hotKeys.onF7.listen((_) => _callController.park(ORModel.Call.activeCall));

    _hotKeys.onF8.listen((_) => _callController.pickupFirstParkedCall());
  }
}
