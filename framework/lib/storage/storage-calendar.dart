/*                  This file is part of OpenReception
                   Copyright (C) 2014-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.storage;

/// Storage interface for persistent storage of [model.CalendarEntry] objects.
abstract class Calendar {
  /// List calendar entry changes for [owner], optionally for a single [eid] as
  /// well.
  Future<List<model.Commit>> changes(model.Owner owner, [int eid]);

  /// Creates and stores a new [model.CalendarEntry] object persistently
  /// using [entry] data and [owner].
  ///
  /// Returns a [model.CalendarEntry] containing the ID of the newly created
  /// [model.CalendarEntry] object. The [modifier] is required for traceability of
  /// who performed the creation.
  Future<model.CalendarEntry> create(
      model.CalendarEntry entry, model.Owner owner, model.User modifier);

  /// Retrive a previously stored [model.CalendarEntry] identified by [eid]
  /// with [owner].
  Future<model.CalendarEntry> get(int eid, model.Owner owner);

  /// List all [model.CalendarEntry] of [owner].
  Future<List<model.CalendarEntry>> list(model.Owner owner);

  /// Permanently removes the previously stored [model.CalendarEntry] object
  /// identified by [eid].
  ///
  /// The [modifier] is required for traceability of who performed the deletion.
  Future<Null> remove(int eid, model.Owner owner, model.User modifier);

  /// Updates the previously stored [model.CalendarEntry] object with data
  /// from [entry].
  ///
  /// The ID in [entry] must be valid and exist in the store, or a [NotFound]
  /// exception is thrown.
  /// The [modifier] is required for traceability of who performed the deletion.
  Future<model.CalendarEntry> update(
      model.CalendarEntry entry, model.Owner owner, model.User modifier);
}
