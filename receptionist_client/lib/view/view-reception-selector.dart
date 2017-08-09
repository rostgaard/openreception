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
 * The reception selector widget.
 */
class ReceptionSelector extends ViewWidget {
  final ui_model.AppClientState _appState;
  final Map<String, String> _langMap;
  controller.Context _latestContext;
  final controller.Destination _myDestination;
  final controller.Notification _notification;
  final List<model.Call> _pickedUpCalls = new List<model.Call>();
  final controller.Popup _popup;
  final controller.Reception _receptionController;
  final List<model.ReceptionReference> _receptions;
  bool _refreshReceptionsCache = false;
  Timer refreshReceptionsCacheTimer;
  final ui_model.UIReceptionSelector _uiModel;

  /**
   * Constructor.
   */
  ReceptionSelector(
      ui_model.UIReceptionSelector this._uiModel,
      ui_model.AppClientState this._appState,
      controller.Destination this._myDestination,
      controller.Notification this._notification,
      List<model.ReceptionReference> this._receptions,
      controller.Reception this._receptionController,
      controller.Popup this._popup,
      Map<String, String> this._langMap) {
    _ui.setHint('alt+v');

    _ui.receptions = _receptions;

    _observers();
  }

  @override
  controller.Destination get _destination => _myDestination;
  @override
  ui_model.UIReceptionSelector get _ui => _uiModel;

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
   * Return true if `receptionId` of [call] is not equal to the currently selected
   * reception.
   */
  bool _receptionMismatch(model.Call call) =>
      _pickedUpCalls.any((model.Call c) => c.id == call.id) &&
      call.rid != _ui.selectedReception.id;

  /**
   * Observers.
   */
  void _observers() {
    _navigate.onGo.listen((controller.Destination destination) {
      _latestContext = destination.context;
      _setWidgetState(destination);
    });

    _hotKeys.onAltV.listen((KeyboardEvent _) => _activateMe());
    _ui.onClick.listen((MouseEvent _) => _activateMe());

    _hotKeys.onCtrlAltR.listen((KeyboardEvent _) {
      final model.ReceptionReference selected = _ui.selectedReception;
      if (selected.id != model.Reception.noId &&
          _latestContext != controller.Context.calendarEdit) {
        _receptionController.get(selected.id).then(
            (model.Reception reception) =>
                _ui.refreshReception(reception.reference));
      }
    });

    _hotKeys.onCtrlEsc.listen((KeyboardEvent _) {
      _navigateToMyDestination();
      _ui.resetFilter();
    });

    _notification.onReceptionChange
        .listen((or_event.ReceptionChange _) => _refreshReceptionsCache = true);

    _notification.onAnyCallStateChange.listen((or_event.CallEvent event) {
      if (event.call.assignedTo == _appState.currentUser.id &&
          event.call.state == model.CallState.hungup) {
        _pickedUpCalls.removeWhere((model.Call c) => c.id == event.call.id);
      }
    });

    refreshReceptionsCacheTimer =
        new Timer.periodic(new Duration(seconds: 5), (_) {
      if (_refreshReceptionsCache) {
        _refreshReceptionsCache = false;
        _popup.info(_langMap[Key.receptionChanged], '',
            closeAfter: new Duration(seconds: 3));
        _receptionController
            .list()
            .then((Iterable<model.ReceptionReference> receptions) {
          _ui.receptionsShadow = receptions.toList()
            ..sort(
                (x, y) => x.name.toLowerCase().compareTo(y.name.toLowerCase()));
        });
      }
    });

    _appState.activeCallChanged.listen((model.Call newCall) {
      if (newCall != model.Call.noCall &&
          newCall.inbound &&
          newCall.assignedTo == _appState.currentUser.id &&
          (!_pickedUpCalls.any((model.Call c) => c.id == newCall.id) ||
              _receptionMismatch(newCall))) {
        _pickedUpCalls.add(newCall);
        _ui.resetFilter();
        _ui.changeActiveReception(newCall.rid);
      }
    });
  }
}
