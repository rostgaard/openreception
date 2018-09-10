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
 * The calendar editor widget.
 */
class CalendarEditor extends ViewWidget {
  final ui_model.UICalendar _calendar;
  final controller.Calendar _calendarController;
  final ui_model.UIContactSelector _contactSelector;
  final Map<String, String> _langMap;
  final Logger _log = new Logger('$libraryName.CalendarEditor');
  final controller.Destination _myDestination;
  final controller.Popup _popup;
  final ui_model.UIReceptionSelector _receptionSelector;
  final ui_model.UICalendarEditor _uiModel;
  final controller.User _userController;

  /**
   * Constructor
   */
  CalendarEditor(
      ui_model.UICalendarEditor this._uiModel,
      controller.Destination this._myDestination,
      ui_model.UICalendar this._calendar,
      ui_model.UIContactSelector this._contactSelector,
      ui_model.UIReceptionSelector this._receptionSelector,
      controller.Calendar this._calendarController,
      controller.Popup this._popup,
      controller.User this._userController,
      Map<String, String> this._langMap) {
    _ui.setHint('Esc | ctrl+backspace | ctrl+s | ctrl+alt+s');

    _observers();
  }

  @override
  controller.Destination get _destination => _myDestination;
  @override
  void _onBlur(controller.Destination _) {}
  @override
  void _onFocus(controller.Destination destination) {
    if (_receptionSelector.selectedReception.isEmpty) {
      _log.info('No reception selected. Navigating back to home context');
      _navigate.goHome();
    }
  }

  @override
  ui_model.UICalendarEditor get _ui => _uiModel;

  /**
   * Activate this widget if it's not already activated.
   *
   * Sets the entry owner.
   */
  void _activateMe(controller.Cmd cmd) {
    if (_receptionSelector.selectedReception.isNotEmpty) {
      ui_model.CalendarEntry ce;

      if (cmd == controller.Cmd.edit) {
        ce = _calendar.selectedCalendarEntry;

        if (ce.calendarEntry == null) {
          ce = _calendar.firstEditableCalendarEntry;
        }

        if (ce.calendarEntry != null &&
            ce.calendarEntry.id != model.CalendarEntry.noId) {
          final String name = ce.owner is model.OwningContact
              ? _contactSelector.selectedContact.contact.name
              : _receptionSelector.selectedReception.name;

          _ui.headerExtra = '(${_langMap[Key.editDelete]} $name)';

          if (_ui.currentAuthorStamp.isEmpty) {
            _setAuthorStamp(ce.calendarEntry);
          }

          _render(ce, false);

          _navigateToMyDestination();
        }
      } else {
        final model.CalendarEntry entry = new model.CalendarEntry.empty()
          ..start = new DateTime.now()
          ..stop = new DateTime.now().add(new Duration(hours: 1))
          ..content = '';
        ce = new ui_model.CalendarEntry.empty()
          ..calendarEntry = entry
          ..owner = new model.OwningContact(
              _contactSelector.selectedContact.contact.id);

        _ui.headerExtra = '(${_langMap[Key.editorNew]})';
        _ui.authorStamp(null, null);

        _render(ce, true);

        _navigateToMyDestination();
      }
    }
  }

  /**
   * Close the widget and cancel edit/create calendar entry.
   *
   * Clear the form and navigate one step back in history.
   */
  void _close() {
    _ui.reset();
    window.history.back();
  }

  /**
   * Delete the calendar entry.
   *
   * Clear the form and navigate one step back in history.
   */
  void _delete(ui_model.CalendarEntry entry) {
    Function reInstateDeletedEntry = _calendar.preDeleteEntry(entry);

    _calendarController
        .deleteCalendarEvent(_ui.loadedEntry.calendarEntry, entry.owner)
        .then((_) {
      _log.info('$entry successfully deleted from database');
      _popup.success(_langMap[Key.calendarEditorDelSuccessTitle],
          'ID ${entry.calendarEntry.id}');
    }).catchError((error) {
      _log.shout('Could not delete calendar entry $entry');
      _popup.error(_langMap[Key.calendarEditorDelErrorTitle],
          'ID ${entry.calendarEntry.id}');
      reInstateDeletedEntry();
    }).whenComplete(() => _close());
  }

  /**
   * Observers.
   */
  void _observers() {
    _navigate.onGo.listen(_setWidgetState);

    _hotKeys.onCtrlE.listen((_) => _activateMe(controller.Cmd.edit));
    _hotKeys.onCtrlK.listen((_) => _activateMe(controller.Cmd.create));

    _ui.onCancel.listen((MouseEvent _) => _close());
    _ui.onDelete.listen((MouseEvent _) => _delete(_ui.loadedEntry));
    _ui.onSave.listen((MouseEvent _) => _save(_ui.harvestedEntry));
    _ui.onSaveReception.listen((ui_model.CalendarEntry entry) {
      entry.owner =
          new model.OwningReception(_receptionSelector.selectedReception.id);
      _save(entry);
    });
  }

  /// Save the calendar entry.
  ///
  /// Clear the form when done, and then navigate one step back in history.
  Future<Null> _save(ui_model.CalendarEntry entry) async {
    Function removeUnsavedElement = _calendar.unsavedEntry(entry);

    try {
      final savedEntry = await _calendarController.saveCalendarEvent(entry.calendarEntry, entry.owner);
      _log.info('$savedEntry successfully saved to database');
      _popup.success(
          _langMap[Key.calendarEditorSaveSuccessTitle], 'ID ${savedEntry.id}');
    } catch (error) {
      model.CalendarEntry loadedEntry = _ui.loadedEntry.calendarEntry;
      _log.shout('Could not save calendar entry $loadedEntry');
      _popup.error(
          _langMap[Key.calendarEditorSaveErrorTitle], 'ID ${loadedEntry.id}');
      removeUnsavedElement();
    }

    _close();
  }

  /// Render the widget with the [calendarEntry].
  void _render(ui_model.CalendarEntry calendarEntry, bool isNew) {
    _ui.setCalendarEntry(calendarEntry, isNew);
  }

  /**
   * Set the `authorStamp` of [_ui]. This is populated with data from the latest
   * calendar entry change object for [entry].
   */
  Future _setAuthorStamp(model.CalendarEntry entry) async {
    model.User user;
    try {
      user = await _userController.get(entry.lastAuthorId);
    } catch (error) {
      user = new model.User.empty()..name = 'uid ${entry.lastAuthorId}';
    }
    _ui.authorStamp(user.name, entry.touched);
  }
}
