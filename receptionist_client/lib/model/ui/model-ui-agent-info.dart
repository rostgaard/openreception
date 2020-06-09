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

enum AgentState { busy, idle, paused, unknown }

enum AlertState { off, on }

/**
 * Provides methods for manipulating the agent info UIX parts.
 */
class UIAgentInfo extends UIModel {
  final DivElement _myRoot;

  /**
   * Constructor.
   */
  UIAgentInfo(DivElement this._myRoot);

  @override
  HtmlElement get _firstTabElement => null;
  @override
  HtmlElement get _focusElement => null;
  @override
  HtmlElement get _lastTabElement => null;
  @override
  HtmlElement get _root => _myRoot;

  TableCellElement get _activeCount => _root.querySelector('.active-count') as TableCellElement;
  ImageElement get _agentState => _root.querySelector('.agent-state') as ImageElement;
  ImageElement get _alertState => _root.querySelector('.alert-state') as ImageElement;
  TableCellElement get _pausedCount => _root.querySelector('.paused-count') as TableCellElement;
  ImageElement get _portrait => _root.querySelector('.portrait') as ImageElement;

  /**
   * Set the ::active:: count.
   */
  set activeCount(int value) {
    _activeCount.text = value.toString();
  }

  /**
   * Set the visual representation of the current agents state.
   */
  set agentState(AgentState agentState) {
    switch (agentState) {
      case AgentState.busy:
        _agentState.src = 'images/agent_speaking.svg';
        break;
      case AgentState.idle:
        _agentState.src = 'images/agent_idle.svg';
        break;
      case AgentState.paused:
        _agentState.src = 'images/agent_pause.svg';
        break;
      default:
        _agentState.src = 'images/agent_unknown.svg';
        break;
    }
  }

  /**
   * Toggle the alert state graphic.
   */
  set alertState(AlertState alertState) {
    switch (alertState) {
      case AlertState.off:
        _alertState.style.visibility = 'hidden';
        break;
      case AlertState.on:
        _alertState.src = 'images/alert.svg';
        break;
    }
  }

  /**
   * Set the ::paused:: count.
   */
  set pausedCount(int value) {
    _pausedCount.text = value.toString();
  }

  /**
   * Set the agent portrait. [path] must be a valid source path to an image.
   */
  set portrait(String path) {
    _portrait.src = path;
  }
}
