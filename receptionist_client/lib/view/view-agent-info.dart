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
 * The agent info view. This contains information about the amount of agents
 * currently logged in and how many are active/paused.
 */
class AgentInfo extends ViewWidget {
  final ui_model.AppClientState _appState;
  final Logger _log = new Logger('$libraryName.AgentInfo');
  final controller.Notification _notification;
  final ui_model.UIAgentInfo _uiModel;
  final controller.User _user;
  final controller.Call _call;
  final Map<int, int> _userConnectionCount = {};
  final Map<int, String> _userPeer = {};
  final Map<String, bool> _peerState = {};
  final Map<int, bool> _userPaused = {};

  /**
   * Constructor.
   */
  AgentInfo(
      ui_model.UIAgentInfo this._uiModel,
      ui_model.AppClientState this._appState,
      controller.User this._user,
      controller.Notification this._notification,
      controller.Call this._call) {
    _ui.activeCount = 0;
    _ui.pausedCount = 0;
    _ui.agentState = ui_model.AgentState.unknown;
    _ui.alertState = ui_model.AlertState.off;
    _ui.portrait = 'images/face.png';

    if (_appState.currentUser.portrait.isNotEmpty) {
      _ui.portrait = _appState.currentUser.portrait;
    }

    _reloadUserState().then((_) {
      _observers();
      _user.setPaused(_appState.currentUser);
    });
  }

  @override
  controller.Destination get _destination => null;
  @override
  ui_model.UIAgentInfo get _ui => _uiModel;

  @override
  void _onBlur(controller.Destination _) {}
  @override
  void _onFocus(controller.Destination _) {}

  /**
   * Update the users state in the UI.
   */
  Future _reloadUserState() async {
    await _user.list().then((users) async {
      await Future.forEach(
          users,
          ((user) async {
            _userPeer[user.id] = (await _user.get(user.id)).extension;
          }));
    });

    await _user.stateList().then((status) {
      status.forEach((s) {
        _userPaused[s.userId] = s.paused;
      });
    });

    await _call.peerList().then((peers) {
      peers.forEach((peer) {
        _peerState[peer.name] = peer.registered;
      });
    });

    await _notification.clientConnections().then((connections) {
      connections.forEach((conn) {
        _userConnectionCount[conn.userID] = conn.connectionCount;
      });
    });
  }

  /**
   * Observers.
   */
  void _observers() {
    _hotKeys.onCtrlAltP.listen((KeyboardEvent _) => _toggleAgentState());

    _notification.onAgentStateChange.listen((model.UserStatus userStatus) {
      _userPaused[userStatus.userId] = userStatus.paused;
      _updateCounters();

      if (userStatus.userId == _appState.currentUser.id &&
          _appState.activeCall == model.Call.noCall) {
        if (_userPaused.containsKey(_appState.currentUser.id) &&
            _userPaused[_appState.currentUser.id]) {
          _ui.agentState = ui_model.AgentState.paused;
        } else {
          _ui.agentState = ui_model.AgentState.idle;
        }
      }
    });

    _notification.onClientConnectionStateChange
        .listen((or_event.ClientConnectionState state) {
      _userConnectionCount[state.conn.userID] = state.conn.connectionCount;
      _log.info('View.AgentInfo got '
          'Model.ClientConnectionState: ${state.toJson()}');
      _updateCounters();
    });

    _notification.onPeerStateChange.listen((or_event.PeerState state) {
      _log.info('View.AgentInfo got OREvent.PeerState: ${state.toJson()}');
      _peerState[state.peer.name] = state.peer.registered;
      _updateCounters();
    });

    _appState.activeCallChanged.listen((model.Call newCall) {
      if (newCall != model.Call.noCall) {
        _ui.agentState = ui_model.AgentState.busy;
      } else {
        if (_userPaused.containsKey(_appState.currentUser.id) &&
            _userPaused[_appState.currentUser.id]) {
          _ui.agentState = ui_model.AgentState.paused;
        } else {
          _ui.agentState = ui_model.AgentState.idle;
        }
      }
    });
  }

  /**
   * Toggle the idle/pause agent state. If idle, then set paused and vice versa.
   */
  void _toggleAgentState() {
    if (_userPaused[_appState.currentUser.id]) {
      _user.setIdle(_appState.currentUser);
    } else {
      _user.setPaused(_appState.currentUser);
    }
  }

  /**
   * Update the active/passive counters and the user state graphic.
   */
  void _updateCounters() {
    int active = 0;
    int passive = 0;
    bool available = false;

    /// Update counters.
    _userPeer.forEach((userId, peerId) {
      bool peerRegistered = _userPeer.containsKey(userId)
          ? _peerState.containsKey(_userPeer[userId])
              ? _peerState[_userPeer[userId]]
              : false
          : false;

      int connectionCount = _userConnectionCount.containsKey(userId)
          ? _userConnectionCount[userId]
          : 0;

      available = peerRegistered && connectionCount > 0;
      if (available) {
        if (_userPaused.containsKey(userId) ? _userPaused[userId] : false) {
          passive++;
        } else {
          active++;
        }
      }
    });

    _ui.activeCount = active;
    _ui.pausedCount = passive;
  }
}
