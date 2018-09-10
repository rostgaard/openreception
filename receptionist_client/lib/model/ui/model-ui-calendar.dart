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
 * Provides methods for manipulating the calendar UI widget.
 */
class UICalendar extends UIModel {
  final Map<String, String> _langMap;
  final DivElement _myRoot;
  final NodeValidatorBuilder _validator = new NodeValidatorBuilder()
    ..allowTextElements()
    ..allowHtml5()
    ..allowInlineStyles()
    ..allowNavigation(new AllUriPolicy());
  final util.WeekDays _weekDays;

  /**
   * Constructor.
   */
  UICalendar(DivElement this._myRoot, util.WeekDays this._weekDays,
      Map<String, String> this._langMap) {
    _setupLocalKeys();
    _observers();
  }

  @override
  HtmlElement get _firstTabElement => _root;
  @override
  HtmlElement get _focusElement => _root;
  @override
  HtmlElement get _lastTabElement => _root;
  @override
  HtmlElement get _listTarget => _list;
  @override
  HtmlElement get _root => _myRoot;

  OListElement get _list => _root.querySelector('.generic-widget-list');

  /**
   * Construct a calendar entry LIElement from [ce]
   */
  LIElement _buildEntryElement(CalendarEntry ce) {
    final LIElement li = new LIElement();
    final DateTime now = new DateTime.now();

    bool isToday(DateTime stamp) =>
        stamp.day == now.day &&
        stamp.month == now.month &&
        stamp.year == now.year;

    String whenWhatLabel(model.CalendarEntry entry) {
      final StringBuffer sb = new StringBuffer();
      String l = entry.id == model.CalendarEntry.noId ? 'L' : '';
      String r = ce.owner is model.OwningReception ? 'R' : '';

      if (l.isNotEmpty || r.isNotEmpty) {
        sb.write('**[$r$l]** ');
      }

      return sb.toString();
    }

    SpanElement labelElement(model.CalendarEntry entry) {
      final SpanElement label = new SpanElement();

      if (!entry.active) {
        final DateTime now = new DateTime.now();
        if (entry.start.isBefore(now)) {
          label.classes.add('label-past');
          label.text = _langMap[Key.past];
        } else {
          label.classes.add('label-future');
          label.text = _langMap[Key.future];
        }
      }

      return label;
    }

    final DivElement content = new DivElement()
      ..classes.add('markdown')
      ..setInnerHtml(
          markdown.markdownToHtml(
              '${whenWhatLabel(ce.calendarEntry)}${ce.calendarEntry.content}'),
          validator: _validator);

    content.querySelectorAll('a').forEach((elem) {
      elem.onClick.listen((MouseEvent event) {
        event.preventDefault();
        final AnchorElement a = event.target;
        window.open(a.href, a.text);
        _markSelected(li);
      });
    });

    String start =
        util.humanReadableTimestamp(ce.calendarEntry.start, _weekDays);
    String stop = util.humanReadableTimestamp(ce.calendarEntry.stop, _weekDays);

    if (isToday(ce.calendarEntry.start) && !isToday(ce.calendarEntry.stop)) {
      start = '${_langMap[Key.today]} $start';
    }

    if (isToday(ce.calendarEntry.stop) && !isToday(ce.calendarEntry.start)) {
      stop = '${_langMap[Key.today]} $stop';
    }

    final DivElement labelAndTimestamp = new DivElement()
      ..classes.add('label-and-timestamp')
      ..children.addAll([
        labelElement(ce.calendarEntry),
        new SpanElement()
          ..classes.add('timestamp')
          ..text = '$start - $stop'
      ]);

    return li
      ..children.addAll([content, labelAndTimestamp])
      ..title = ce.calendarEntry.id == model.CalendarEntry.noId
          ? 'WhenWhat - ${_langMap[Key.lockedForEditing]}'
          : 'Id: ${ce.calendarEntry.id.toString()}'
      ..dataset['object'] = json.encode(ce)
      ..dataset['editable'] = ce.editable.toString()
      ..dataset['id'] = ce.calendarEntry.id.toString()
      ..classes.toggle('active', ce.calendarEntry.active);
  }

  /**
   * Add [items] to the [CalendarEntry] list.
   */
  set calendarEntries(Iterable<CalendarEntry> items) {
    _list.children = items.map(_buildEntryElement).toList(growable: false);
  }

  /**
   * Remove all entries from the entry list and clear the header.
   */
  void clear() {
    _headerExtra.text = '';
    _list.children.clear();
  }

  /**
   * Return the first editable [CalendarEntry]. Return empty entry if none is
   * found.
   */
  CalendarEntry get firstEditableCalendarEntry {
    final LIElement li = _list.children.firstWhere(
        (Element elem) => elem.dataset['editable'] == 'true',
        orElse: () => null);

    if (li != null) {
      return new CalendarEntry.fromJson(
          json.decode(li.dataset['object']) as Map<String, dynamic>);
    } else {
      return new CalendarEntry.empty();
    }
  }

  /**
   * Observers
   */
  void _observers() {
    _root.onKeyDown.listen(_keyboard.press);
    _root.onClick.listen(_selectFromClick);
  }

  /**
   * Delete the [entry] in the calendar entry list. This does not perform any
   * action on the server.
   *
   * The returned function re-instates the entry into the list when called.
   */
  Function preDeleteEntry(CalendarEntry entry) {
    final LIElement li =
        _list.querySelector('[data-id="${entry.calendarEntry.id}"]');
    li.style.display = 'none';

    return () => li.style.display = 'block';
  }

  /**
   * Return currently selected [CalendarEntry]. Return empty entry if nothing is
   * selected or if the selected item is not editable.
   */
  CalendarEntry get selectedCalendarEntry {
    final LIElement selected = _list.querySelector('.selected');

    if (selected == null || selected.dataset['editable'] != 'true') {
      return new CalendarEntry.empty();
    } else {
      return new CalendarEntry.fromJson(
          json.decode(selected.dataset['object']) as Map<String, dynamic>);
    }
  }

  /**
   * Mark a [LIElement] in the calendar entry list selected, if one such is the
   * target of the [event].
   */
  void _selectFromClick(MouseEvent event) {
    if (event.target is LIElement) {
      _markSelected(event.target);
    }
  }

  /**
   * Setup keys and bindings to methods specific for this widget.
   */
  void _setupLocalKeys() {
    _hotKeys.registerKeysPreventDefault(_keyboard, _defaultKeyMap(myKeys: {}));
  }

  /**
   * Either add or update the [ce] in the calendar entry listing. This does
   * not perform any actions on the server.
   *
   * The returned function removes the created/changed LIElement when called.
   */
  Function unsavedEntry(CalendarEntry ce) {
    final LIElement newLi = _buildEntryElement(ce);

    if (ce.calendarEntry.id == model.CalendarEntry.noId) {
      if (_list.children.isEmpty) {
        _list.children.add(newLi);
      } else {
        LIElement found;
        for (LIElement li in _list.children) {
          final CalendarEntry foundEntry = new CalendarEntry.fromJson(
              json.decode(li.dataset['object']) as Map<String, dynamic>);
          if (foundEntry.calendarEntry.start.isAfter(ce.calendarEntry.start) ||
              foundEntry.calendarEntry.start
                  .isAtSameMomentAs(ce.calendarEntry.start)) {
            found = li;
            break;
          }
        }

        if (found != null) {
          _list.insertBefore(newLi, found);
        } else {
          _list.children.add(newLi);
        }
      }
    } else {
      final LIElement orgLi =
          _list.querySelector('[data-id="${ce.calendarEntry.id}"]');
      orgLi.replaceWith(newLi);
    }

    return () => newLi.remove();
  }
}
