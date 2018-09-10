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
 * Provides methods for manipulating the reception telephone numbers UI widget.
 */
class UIReceptionTelephoneNumbers extends UIModel {
  final DivElement _myRoot;

  /**
   * Constructor.
   */
  UIReceptionTelephoneNumbers(DivElement this._myRoot) {
    _setupLocalKeys();
    _observers();
  }

  @override
  HtmlElement get _firstTabElement => _list;
  @override
  HtmlElement get _focusElement => _list;
  @override
  HtmlElement get _lastTabElement => _list;
  @override
  HtmlElement get _root => _myRoot;

  OListElement get _list => _root.querySelector('.generic-widget-list');

  /**
   * Remove all entries from the list and clear the header.
   */
  void clear() {
    _headerExtra.text = '';
    _list.children.clear();
  }

  /**
   * Observers.
   */
  void _observers() {
    _root.onKeyDown.listen(_keyboard.press);
    _root.onClick.listen((_) => _list.focus());
  }

  /**
   * Setup keys and bindings to methods specific for this widget.
   */
  void _setupLocalKeys() {
    final Map<String, EventListener> bindings = {
      'Shift+Tab': _handleShiftTab,
      'Tab': _handleTab
    };

    _hotKeys.registerKeysPreventDefault(_keyboard, bindings);
  }

  /**
   * Add [items] to the telephone number list.
   */
  set telephoneNumbers(List<model.PhoneNumber> items) {
    final List<LIElement> list = new List<LIElement>();

    items.forEach((model.PhoneNumber item) {
      final SpanElement spanLabel = new SpanElement();
      final SpanElement spanNumber = new SpanElement();

      spanNumber.classes.toggle('secret', item.confidential);
      spanNumber.classes.add('number');
      spanNumber.text = item.destination;

      spanLabel.classes.add('label');
      spanLabel.text = item.note;

      list.add(new LIElement()
        ..children.addAll([spanNumber, spanLabel])
        ..dataset['object'] = json.encode(item));
    });

    _list.children = list;
  }
}
