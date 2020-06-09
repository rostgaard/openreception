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
 * Provides methods to manipulate and extract data from the widget UX parts.
 */
class UIReceptionSelector extends UIModel {
  final Bus<model.Reception> _bus = new Bus<model.Reception>();
  final Map<String, String> _langMap;
  DateTime _lastClick = new DateTime.now();
  final DivElement _myRoot;
  final controller.Popup _popup;
  final controller.Reception _receptionController;
  List<LIElement> _receptionsCache = new List<LIElement>();

  /**
   * Constructor.
   */
  UIReceptionSelector(DivElement this._myRoot, controller.Popup this._popup,
      this._receptionController, Map<String, String> this._langMap) {
    _setupLocalKeys();
    _observers();
  }

  @override
  HtmlElement get _firstTabElement => _filter;
  @override
  HtmlElement get _focusElement => _filter;
  @override
  HtmlElement get _lastTabElement => _filter;
  @override
  HtmlElement get _listTarget => _list;
  /**
   * Return the mousedown click event stream for this widget. We capture
   * mousedown instead of regular click to avoid the ugly focus/blur flicker
   * on the filter input whenever a reception li element is clicked.
   */
  @override
  Stream<MouseEvent> get onClick => _myRoot.onMouseDown;
  @override
  SelectCallback get _selectCallback => _receptionSelectCallback;
  @override
  HtmlElement get _root => _myRoot;

  OListElement get _list => _root.querySelector('.generic-widget-list') as OListElement;
  InputElement get _filter => _root.querySelector('.filter') as InputElement;

  /**
   * Construct a [reception] <li> element.
   */
  LIElement _buildReceptionElement(model.ReceptionReference reception) =>
      new LIElement()
        ..dataset['id'] = reception.id.toString()
        ..dataset['name'] = reception.name.toLowerCase()
        ..dataset['object'] = json.encode(reception)
        ..text = reception.name;

  /**
   * Mark the [receptionId] list item as selected.
   */
  void changeActiveReception(int receptionId) {
    _markSelected(_list.querySelector('[data-id="$receptionId"]') as LIElement);
  }

  /**
   * Filter the reception list whenever the user enters data into the [_filter]
   * input field.
   */
  void _filterList() {
    final String filter = _filter.value.toLowerCase();
    final String trimmedFilter = filter.trim();

    if (filter.length == 0 || trimmedFilter.isEmpty) {
      /// Empty filter. Remove .hide from all list elements.
      _list.children.forEach((Element li) => li.classes.toggle('hide', false));
      _list.classes.toggle('zebra', true);
    } else if (trimmedFilter.length == 1) {
      _list.classes.toggle('zebra', false);

      _list.children.forEach((Element li) {
        if (li.dataset['name'].startsWith(trimmedFilter)) {
          li.classes.toggle('hide', false);
        } else {
          li.classes.toggle('hide', true);
        }
      });
    } else {
      _list.classes.toggle('zebra', false);

      _list.children.forEach((Element li) {
        if (li.dataset['name'].contains(trimmedFilter)) {
          li.classes.toggle('hide', false);
        } else {
          li.classes.toggle('hide', true);
        }
      });
    }
  }

  /**
   * Deal with enter.
   *
   * If the filter is not empty and all but one element are hidden, then hitting
   * enter will result in the remaining visible element being selected.
   */
  void _handleEnter(Event _) {
    if (_filter.value.trim().isNotEmpty &&
        _list.querySelectorAll(':not(.hide)').length == 1) {
      _markSelected(_scanForwardForVisibleElement(_list.children.first as LIElement));
    }
  }

  /**
   * Observers
   */
  void _observers() {
    _filter.onKeyDown.listen(_keyboard.press);

    _filter.onInput.listen((Event _) => _filterList());

    _list.onDoubleClick.listen((Event event) {
      if (event.target is LIElement) {
        final String text = (event.target as LIElement).firstChild.text;
        _copyToClipboard(text);
        _popup.success(_langMap[Key.nameCopied], text,
            closeAfter: new Duration(milliseconds: 1500));
      }
    });

    /// NOTE (TL): Don't switch this to _root.onClick. We need the mousedown
    /// event, not the mouseclick event. We want to keep focus on the filter at
    /// all times.
    onClick.listen(_selectFromClick);
  }

  /**
   * Fires the selected [model.Reception].
   */
  Stream<model.Reception> get onSelect => _bus.stream;

  /**
   * Add [items] to the receptions list.
   */
  set receptions(List<model.ReceptionReference> items) {
    final List<LIElement> list = new List<LIElement>();

    items.forEach((model.ReceptionReference item) {
      list.add(_buildReceptionElement(item));
    });

    _list.children = list;
  }

  /**
   * Set [items] as the receptions list cache. This does NOT update the actual
   * receptions list. Call [refreshReceptions] to update the list using the
   * cached values.
   */
  set receptionsShadow(List<model.ReceptionReference> items) {
    _receptionsCache = items.map(_buildReceptionElement).toList();
  }

  /**
   * Fire a [model.Reception] on [_bus]. The [model.Reception] is constructed
   * from JSON found in the data-object attribute of [li].
   */
  Future _receptionSelectCallback(LIElement li) async {
    final int rid = int.parse(li.dataset['id']);

    _bus.fire(await _receptionController.get(rid));
  }

  /**
   * Refresh [reception] in the reception list, and mark it selected.
   */
  void refreshReception(model.ReceptionReference reception) {
    final LIElement newLi = _buildReceptionElement(reception);
    final LIElement oldLi = _list.querySelector('[data-id="${reception.id}"]') as LIElement;
    oldLi.replaceWith(newLi);
    _markSelected(newLi);
  }

  /**
   * Reloads the receptions list. Does not take selected receptions into
   * account, so should only be called when no receptions are selected.
   */
  void refreshReceptions() {
    if (_receptionsCache.isNotEmpty) {
      _list.children = _receptionsCache;
      _receptionsCache.clear();
    }
  }

  /**
   * Remove selections, scroll to top and empty filter input and fire an empty
   * [model.Reception].
   */
  void resetFilter() {
    _filter.value = '';
    _filterList();
    _list.children.forEach((Element e) => e.classes.toggle('selected', false));
    _bus.fire(new model.Reception.empty());
  }

  /// Mark a [LIElement] in the reception list selected, if one such is the
  /// target of the [event].
  ///
  /// Only allow one click per 100 milliseconds.
  void _selectFromClick(MouseEvent event) {
    final DateTime now = new DateTime.now();

    if (event.target != _filter &&
        now.difference(_lastClick).inMilliseconds > 100) {
      _lastClick = now;

      /// NOTE (TL): This keeps focus on the _filter field, despite clicks on
      /// other elements.
      event.preventDefault();

      final target = event.target;
      if (target is LIElement) {
        _markSelected(target);
      }
    }
  }

  /// Setup keys and bindings to methods specific for this widget.
  void _setupLocalKeys() {
    final Map<String, EventListener> bindings = {
      'Enter': _handleEnter,
      'Esc': (_) => resetFilter()
    };

    _hotKeys.registerKeysPreventDefault(
        _keyboard, _defaultKeyMap(myKeys: bindings));
  }

  /// Returns the currently selected [model.Reception].
  ///
  /// Return [model.Reception.empty] if no [model.Reception] is selected.
  model.ReceptionReference get selectedReception {
    LIElement li = _list.querySelector('.selected') as LIElement;

    if (li != null) {
      return new model.ReceptionReference.fromJson(
          json.decode(li.dataset['object']) as Map<String, dynamic>);
    } else {
      return const model.ReceptionReference.none();
    }
  }
}
