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

part of orc.controller;

/// Exposes methods for calendar CRUD operations.
class Calendar {
  /// Constructor.
  Calendar(this._calendarStore, this._user);

  final model.User _user;
  final service.RESTCalendarStore _calendarStore;

  /// Return the latest entry change information for the [entry] calendar entry.
  Future<Iterable<model.Commit>> calendarEntryChanges(
          model.CalendarEntry entry, model.Owner owner) =>
      _calendarStore.changes(owner, entry.id);

  /// Return the latest entry change information for the [entry] calendar entry.
  Future<model.Commit> calendarEntryLatestChange(
          model.CalendarEntry entry, model.Owner owner) async =>
      (await _calendarStore.changes(owner, entry.id)).first;

  /// Return all the [contact] [model.CalendarEntry]s.
  Future<Iterable<model.CalendarEntry>> contactCalendar(
          model.BaseContact contact) =>
      _calendarStore.list(new model.OwningContact(contact.id));

  /// Delete [entry] from the database.
  Future deleteCalendarEvent(model.CalendarEntry entry, model.Owner owner) =>
      _calendarStore.remove(entry.id, owner, _user);

  /// Return all the [model.CalendarEntry]s of a [reception].
  Future<Iterable<model.CalendarEntry>> receptionCalendar(
          model.ReceptionReference reception) =>
      _calendarStore.list(new model.OwningReception(reception.id));

  /// Save [entry] to the database.
  Future saveCalendarEvent(model.CalendarEntry entry, model.Owner owner) =>
      entry.id == model.CalendarEntry.noId
          ? _calendarStore.create(entry, owner, _user)
          : _calendarStore.update(entry, owner, _user);
}
