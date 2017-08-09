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

part of orc.model;

enum AppState { loading, error, ready }

class AppClientState {
  model.Call _activeCall = model.Call.noCall;
  final Bus<model.Call> _activeCallChangeBus = new Bus<model.Call>();

  /// The currently logged in user.
  model.User currentUser = new model.User.empty();
  final Logger _log = new Logger('$libraryName.AppClientState');
  final controller.Notification _notification;
  final Bus<AppState> _stateChange = new Bus<AppState>();

  model.OriginationContext _originationContext;

  /**
   * Constructor.
   */
  AppClientState(controller.Notification this._notification) {
    _observers();
  }

  model.OriginationContext get originationContext => _originationContext;

  /**
   * Fires an ORModel.Call on pickup and hangup.
   */
  Stream<model.Call> get activeCallChanged => _activeCallChangeBus.stream;

  /**
   * Return the currently active call.
   */
  model.Call get activeCall => _activeCall;

  /**
   * Set the currently active call. A hangup is when [newCall] is
   * [ORModel.Call.noCall].
   */
  set activeCall(model.Call newCall) {
    _activeCall = newCall;

    _activeCallChangeBus.fire(_activeCall);
    _log.finest(
        'Setting active call to ${_activeCall == model.Call.noCall ? 'noCall' : _activeCall}');
  }

  /**
   * Change the application to [newState]
   */
  void changeState(AppState newState) {
    _stateChange.fire(newState);
  }

  /**
   * Setup listeners needed for this object.
   */
  void _observers() {
    _notification.onAnyCallStateChange.listen((or_event.CallEvent e) {
      final model.Call call = e.call;

      if (call.assignedTo != currentUser.id) {
        return;
      }

      if (call.state == model.CallState.ringing ||
          call.state == model.CallState.speaking) {
        activeCall = call;
      } else if (activeCall == call) {
        activeCall = model.Call.noCall;
      }
    });
  }

  /**
   * Listen for [AppState] change events.
   */
  Stream<AppState> get onStateChange => this._stateChange.stream;
}
