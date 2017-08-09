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
 * Handles the contact calendar entries.
 */
class Calendar extends ViewWidget {
  final ui_model.UIContactSelector _contactSelector;
  model.Reception _currentReception = model.Reception.noReception;
  final Logger _log = new Logger('$libraryName.Calendar');
  final controller.Destination _myDestination;
  final controller.Notification _notification;
  final ui_model.UIReceptionSelector _receptionSelector;
  final ui_model.UICalendar _uiModel;
  final controller.Contact _contactController;
  final controller.Calendar _calendarController;

  /**
   * Constructor.
   */
  Calendar(
      ui_model.UICalendar this._uiModel,
      controller.Destination this._myDestination,
      ui_model.UIContactSelector this._contactSelector,
      ui_model.UIReceptionSelector this._receptionSelector,
      controller.Contact this._contactController,
      controller.Calendar this._calendarController,
      controller.Notification this._notification) {
    _ui.setHint('alt+k | ctrl+k | ctrl+e');

    _observers();
  }

  @override
  controller.Destination get _destination => _myDestination;
  @override
  void _onBlur(controller.Destination _) {}
  @override
  void _onFocus(controller.Destination _) {}
  @override
  ui_model.UICalendar get _ui => _uiModel;

  /**
   * Activate this widget if it's not already activated.
   */
  void _activateMe() {
    _navigateToMyDestination();
  }

  /**
   * Fetch all calendar entries and [WhenWhat]'s for [cwfc] and [rr].
   */
  void _fetchCalendars(
      ui_model.ContactWithFilterContext cwfc, model.ReceptionReference rr) {
    if (rr.id == _currentReception.id) {
      final List<ui_model.CalendarEntry> allEntries =
          <ui_model.CalendarEntry>[];

      allEntries.addAll(_getWhenWhats(
          _currentReception.whenWhats, new model.OwningReception(rr.id)));
      allEntries.addAll(_getWhenWhats(
          cwfc.attr.whenWhats, new model.OwningContact(cwfc.contact.id)));

      Future rCalendars() => _calendarController
              .receptionCalendar(rr)
              .then((Iterable<model.CalendarEntry> entries) {
            allEntries.addAll(entries.map((model.CalendarEntry entry) =>
                new ui_model.CalendarEntry.empty()
                  ..calendarEntry = entry
                  ..owner = new model.OwningReception(rr.id)));
          });

      Future cCalendars() => _calendarController
              .contactCalendar(cwfc.contact)
              .then((Iterable<model.CalendarEntry> entries) {
            allEntries.addAll(entries.map((model.CalendarEntry entry) =>
                new ui_model.CalendarEntry.empty()
                  ..calendarEntry = entry
                  ..owner = new model.OwningContact(cwfc.contact.id)));
          });

      Future.wait([rCalendars(), cCalendars()]).then((_) {
        _ui.calendarEntries = allEntries
          ..sort(
              (a, b) => a.calendarEntry.start.compareTo(b.calendarEntry.start));
      });
    } else {
      _log.warning('Reception id mismatch. No calendars loaded.');
    }
  }

  /**
   * Return a list of [ui_model.CalendarEntry] based on the given
   * [model.WhenWhat] list and [owner].
   */
  List<ui_model.CalendarEntry> _getWhenWhats(
      List<model.WhenWhat> whenWhats, model.Owner owner) {
    final List<model.WhenWhatMatch> matches = <model.WhenWhatMatch>[];
    final DateTime now = new DateTime.now();

    for (model.WhenWhat ww in whenWhats) {
      matches.addAll(ww.matches(now));
    }

    model.CalendarEntry entry(model.WhenWhatMatch match) =>
        new model.CalendarEntry.empty()
          ..start = match.begin
          ..stop = match.end
          ..content = match.what;

    return matches
        .map((model.WhenWhatMatch match) => new ui_model.CalendarEntry.empty()
          ..owner = owner
          ..editable = false
          ..calendarEntry = entry(match))
        .toList();
  }

  /**
   * Observers.
   */
  void _observers() {
    _navigate.onGo.listen(_setWidgetState);

    _hotKeys.onAltK.listen((KeyboardEvent _) => _activateMe());
    _ui.onClick.listen((MouseEvent _) => _activateMe());

    _notification.onCalendarChange.listen(_updateOnChange);

    _contactSelector.onSelect.listen((ui_model.ContactWithFilterContext c) =>
        _render(c, _receptionSelector.selectedReception));

    _receptionSelector.onSelect.listen((model.Reception r) {
      _currentReception = r;
    });
  }

  /**
   * Render the widget with [cwfc] and [rr].
   */
  void _render(
      ui_model.ContactWithFilterContext cwfc, model.ReceptionReference rr) {
    if (cwfc.contact.isNotEmpty && cwfc.attr.receptionId != rr.id) {
      _log.warning('Contact and Reception does not match. No calendars loaded');
    } else {
      if (cwfc.attr.isEmpty) {
        _ui.clear();
      } else {
        _fetchCalendars(cwfc, rr);
      }
    }
  }

  /**
   * Check if changes to the contact calendar matches the currently selected
   * contact, and update accordingly if so.
   */
  void _updateOnChange(or_event.CalendarChange calendarChange) {
    final model.ReceptionContact rc = _contactSelector.selectedContact;
    final model.ReceptionReference rr = _receptionSelector.selectedReception;
    int cid = model.BaseContact.noId;
    int rid = model.Reception.noId;

    if (calendarChange.owner is model.OwningContact) {
      cid = (calendarChange.owner as model.OwningContact).id;
    } else if (calendarChange.owner is model.OwningReception) {
      rid = (calendarChange.owner as model.OwningReception).id;
    }

    if (rc.contact.id == cid || rr.id == rid) {
      _fetchCalendars(
          new ui_model.ContactWithFilterContext(
              rc.contact, rc.attr, null, null),
          rr);
    }
  }
}
