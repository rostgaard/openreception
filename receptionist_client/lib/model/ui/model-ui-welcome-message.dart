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

/**
 * UI model for welcome message.
 */
class UIWelcomeMessage extends UIModel {
  final DivElement _myRoot;

  /**
   * Constructor.
   */
  UIWelcomeMessage(DivElement this._myRoot);

  @override
  HtmlElement get _firstTabElement => null;
  @override
  HtmlElement get _focusElement => null;
  @override
  HtmlElement get _lastTabElement => null;
  @override
  HtmlElement get _root => _myRoot;

  SpanElement get _greeting => _root.querySelector('.greeting') as SpanElement;

  /**
   * Color the greeting box background when in active call.
   */
  set inActiveCall(bool inCall) {
    _greeting.classes.toggle('incall', inCall);
  }

  /**
   * Clear the welcome message widget.
   */
  void clear() {
    greeting = '';
  }

  /**
   * Set the [model.Reception] greeting.
   */
  set greeting(String value) {
    _greeting.text = value;
  }
}
