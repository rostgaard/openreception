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
 * Provides methods for manipulating the contact selector UI widget.
 */
class UIContactSelector extends UIModel {
  final Bus<ContactWithFilterContext> _bus =
      new Bus<ContactWithFilterContext>();
  final Bus<Event> _ctrlEnterBus = new Bus<Event>();
  final Bus<Event> _ctrlSBus = new Bus<Event>();
  final Map<String, String> _langMap;
  final DivElement _myRoot;
  final controller.Popup _popup;

  /**
   * Constructor.
   */
  UIContactSelector(DivElement this._myRoot, controller.Popup this._popup,
      Map<String, String> this._langMap) {
    _setupLocalKeys();
    _observers();
  }

  @override
  HtmlElement get _firstTabElement => _filterInput;
  @override
  HtmlElement get _focusElement => _filterInput;
  @override
  HtmlElement get _lastTabElement => _filterInput;
  @override
  HtmlElement get _listTarget => _list;
  /**
   * Return the mousedown click event stream for this widget. We capture
   * mousedown instead of regular click to avoid the ugly focus/blur flicker
   * on the filter input whenever a contact li element is clicked.
   */
  @override
  Stream<MouseEvent> get onClick => _myRoot.onMouseDown;
  @override
  SelectCallback get _selectCallback => _contactSelectCallback;
  @override
  HtmlElement get _root => _myRoot;

  OListElement get _list => _root.querySelector('.generic-widget-list');
  InputElement get _filterInput => _root.querySelector('.filter');
  String get filterInputValue => _filterInput.value.toLowerCase();
  String get trimmedFilterInputValue => filterInputValue.trim();

  /**
   * Remove all entries from the contact list.
   */
  void clear() {
    _list.children.clear();
    _filterInput.value = '';
    _bus.fire(new ContactWithFilterContext(new model.BaseContact.empty(),
        new model.ReceptionAttributes.empty(), state, filterInputValue));
  }

  /**
   * Add [contacts] to the [Contact] list. Always resets the filter input to
   * empty string.
   */
  set contacts(Iterable<model.ReceptionContact> contacts) {
    _filterInput.value = '';

    final List<LIElement> list = new List<LIElement>();

    contacts.forEach((model.ReceptionContact item) {
      String initials = item.contact.name
          .split(' ')
          .where((value) => value.trim().isNotEmpty)
          .map((value) => value.substring(0, 1))
          .join()
          .toLowerCase();

      final List<String> departments = <String>[]
        ..addAll(item.attr.departments);
      final List<String> tags = new List<String>()
        ..addAll(item.attr.tags)
        ..add(item.contact.name); // treat name as any other normal tag.
      final List<String> titles = <String>[]..addAll(item.attr.titles);

      int compare(String a, b) => a.toLowerCase().compareTo(b.toLowerCase());
      departments.sort(compare);
      tags.sort(compare);
      titles.sort(compare);

      list.add(new LIElement()
        ..dataset['initials'] = initials
        ..dataset['firstinitial'] = initials.substring(0, 1)
        ..dataset['otherinitials'] = initials.substring(1)
        ..dataset['departments'] = departments.toSet().join('-|-').toLowerCase()
        ..dataset['tags'] = tags.toSet().join('-|-').toLowerCase()
        ..dataset['titles'] = titles.toSet().join('-|-').toLowerCase()
        ..dataset['object'] = json.encode(item)
        ..classes.addAll(item.contact.enabled ? [] : ['disabled'])
        ..classes.addAll(item.contact.type == 'function' ? ['function'] : [])
        ..text = item.contact.name);
    });

    _list.children = list;
  }

  /**
   * Fire a [ContactWithFilterContext] on [_bus]. The wrapped [Contact] is
   * constructed from json found in the data-object attribute of [li].
   */
  void _contactSelectCallback(LIElement li) {
    model.ReceptionContact rc = new model.ReceptionContact.fromJson(
        json.decode(li.dataset['object']) as Map<String, dynamic>);
    _bus.fire(new ContactWithFilterContext(
        rc.contact, rc.attr, state, filterInputValue));
  }

  /**
   * Filter the contact list whenever the user enters data into the [_filterInput]
   * input field.
   *
   * Venture forth at your own peril!
   */
  void _filter() {
    _list.querySelectorAll('span').forEach((element) => element.remove());

    void prefixedFilter(String input, String datasetName) {
      _list.classes.toggle('zebra', false);

      _list.children.forEach((Element li) {
        final Iterable<String> hits = li.dataset[datasetName]
            .split('-|-')
            .where((String hit) => hit.contains(input) && input.isNotEmpty);

        if (hits.isNotEmpty) {
          li.classes.toggle('hide', false);
          hits.forEach(
              (String hit) => li.children.add(new SpanElement()..text = hit));
        } else {
          li.classes.toggle('hide', true);
        }
      });
    }

    switch (state) {
      case filterState.department:
        prefixedFilter(trimmedFilterInputValue.substring(2), 'departments');
        break;
      case filterState.empty:
        _list.children
            .forEach((Element li) => li.classes.toggle('hide', false));
        _list.classes.toggle('zebra', true);
        break;
      case filterState.firstInitial:
        _list.classes.toggle('zebra', false);

        _list.children.forEach((Element li) {
          if (li.dataset['firstinitial'] == trimmedFilterInputValue) {
            li.classes.toggle('hide', false);
          } else {
            li.classes.toggle('hide', true);
          }
        });
        break;
      case filterState.otherInitials:
        _list.classes.toggle('zebra', false);

        _list.children.forEach((Element li) {
          if (li.dataset['otherinitials'].contains(trimmedFilterInputValue)) {
            li.classes.toggle('hide', false);
          } else {
            li.classes.toggle('hide', true);
          }
        });
        break;
      case filterState.initials:
        _list.classes.toggle('zebra', false);

        _list.children.forEach((Element li) {
          if (li.dataset['firstinitial'] ==
                  trimmedFilterInputValue.substring(0, 1) &&
              li.dataset['otherinitials']
                  .contains(trimmedFilterInputValue.substring(2))) {
            li.classes.toggle('hide', false);
          } else {
            li.classes.toggle('hide', true);
          }
        });
        break;
      case filterState.tag:
        final String inputValue = trimmedFilterInputValue;
        final List<String> parts = trimmedFilterInputValue.split(' ');

        _list.classes.toggle('zebra', false);

        _list.children.forEach((Element li) {
          final List<String> tags = li.dataset['tags'].split('-|-');

          final Set<String> exactHits =
              tags.where((String tag) => inputValue == tag).toSet();
          final Set<String> partialHits = tags
              .where((String tag) =>
                  parts.every((String part) => tag.contains(part)))
              .toSet();

          final Set<String> hitTags = exactHits.union(partialHits);
          if (hitTags.isNotEmpty) {
            li.classes.toggle('hide', false);
            hitTags.forEach(
                (String tag) => li.children.add(new SpanElement()..text = tag));
          } else {
            li.classes.toggle('hide', true);
          }
        });
        break;
      case filterState.title:
        prefixedFilter(trimmedFilterInputValue.substring(2), 'titles');
        break;
    }

    final List<Element> visible = _list.querySelectorAll('li:not(.hide)');
    if (_list.children.isNotEmpty &&
        !visible.any((Element li) => li.classes.contains('selected'))) {
      _markSelected(_scanForwardForVisibleElement(_list.children.first),
          alwaysFire: true);
    }

    final LIElement selected = _list.querySelector('.selected');
    if (selected != null) {
      selected.scrollIntoView();
    }
  }

  /**
   * Return the state of the filter input. This is defined based on the pattern
   * of the field value.
   */
  filterState get state {
    filterState s;

    if (filterInputValue.isEmpty || trimmedFilterInputValue.isEmpty) {
      /// Empty filter
      s = filterState.empty;
    } else if (filterInputValue.startsWith('a:')) {
      s = filterState.department;
    } else if (filterInputValue.startsWith('t:')) {
      s = filterState.title;
    } else if (!filterInputValue.startsWith(' ') &&
        trimmedFilterInputValue.length == 1) {
      /// Pattern: one non-space character followed by zero or more spaces
      s = filterState.firstInitial;
    } else if (trimmedFilterInputValue.length == 1 &&
        filterInputValue.startsWith(new RegExp(r'\s+[^ ]'))) {
      /// Pattern: one or more spaces followed by one non-space character
      s = filterState.otherInitials;
    } else if (trimmedFilterInputValue.length == 3 &&
        trimmedFilterInputValue.startsWith(new RegExp(r'[^ ]\s[^ ]'))) {
      /// Pattern: one character, one space, one character
      s = filterState.initials;
    } else {
      /// Split filter string on space and search for contacts that have all
      /// the resulting parts in their tag list.
      s = filterState.tag;
    }

    return s;
  }

  /**
   * Observers
   */
  void _observers() {
    _filterInput.onKeyDown.listen(_keyboard.press);

    _filterInput.onInput.listen((Event _) => _filter());

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
   * Fires whenever ctrl+enter is pressed while this widget is in focus.
   */
  Stream<Event> get onCtrlEnter => _ctrlEnterBus.stream;

  /**
   * Fires whenever ctrl+s is pressed while this widget is in focus.
   */
  Stream<Event> get onCtrlS => _ctrlSBus.stream;

  /**
   * Fires the selected [ContactWithFilterContext].
   */
  Stream<ContactWithFilterContext> get onSelect => _bus.stream;

  /**
   * Remove selections, scroll to top, empty filter input and then select the
   * first contact.
   */
  void _reset(Event _) {
    _filterInput.value = '';
    _filter();
    selectFirstContact();
  }

  /**
   * Returns the currently selected [Contact].
   *
   * Return [model.ReceptionContact.empty()] if no [Contact] is selected.
   */
  model.ReceptionContact get selectedContact {
    LIElement li = _list.querySelector('.selected');

    if (li != null) {
      return new model.ReceptionContact.fromJson(
          json.decode(li.dataset['object']) as Map<String, dynamic>);
    } else {
      return new model.ReceptionContact.empty();
    }
  }

  /**
   * Select the first [Contact] in the list.
   */
  void selectFirstContact() {
    if (_list.children.isNotEmpty) {
      _markSelected(_scanForwardForVisibleElement(_list.children.first));
    } else {
      _bus.fire(new ContactWithFilterContext(new model.BaseContact.empty(),
          new model.ReceptionAttributes.empty(), state, filterInputValue));
    }
  }

  /**
   * Mark a [LIElement] in the contact list selected, if one such is the target
   * of the [event].
   */
  void _selectFromClick(MouseEvent event) {
    if (event.target != _filterInput) {
      /// NOTE (TL): This keeps focus on the _filter field, despite clicks on
      /// other elements.
      event.preventDefault();

      if (event.target is LIElement) {
        _markSelected(event.target);
      }
    }
  }

  /**
   * Setup keys and bindings to methods specific for this widget.
   */
  void _setupLocalKeys() {
    final Map<String, EventListener> bindings = {
      'Esc': _reset,
      'Ctrl+enter': _ctrlEnterBus.fire,
      'Ctrl+s': _ctrlSBus.fire
    };

    _hotKeys.registerKeysPreventDefault(
        _keyboard, _defaultKeyMap(myKeys: bindings));
  }
}
