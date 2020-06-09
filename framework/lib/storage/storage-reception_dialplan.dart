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

part of orf.storage;

/// Storage interface for persistent storage of [model.ReceptionDialplan] objects.
abstract class ReceptionDialplan {
  /// Creates and stores a new [model.ReceptionDialplan] object persistently
  /// using [rdp] data.
  ///
  /// Returns a [model.ReceptionDialplan] containing the ID of the newly created
  /// [model.ReceptionDialplan] object.
  /// The [modifier] is required for traceability of who performed the creation.
  Future<model.ReceptionDialplan> create(
      model.ReceptionDialplan rdp, model.User modifier);

  /// Retrive a previously stored [model.ReceptionDialplan] identified
  /// by [extension].
  Future<model.ReceptionDialplan> get(String extension);

  /// Retrieve a list of [model.ReceptionDialplan] to all available dialplans
  /// in the store.
  Future<List<model.ReceptionDialplan>> list();

  /// Updates the previously stored [model.ReceptionDialplan] object with data
  /// from [rdp].
  ///
  /// The `extension` in [rdp] must be valid and exist in the store, or
  /// a [NotFound] exception is thrown.
  Future<model.ReceptionDialplan> update(
      model.ReceptionDialplan rdp, model.User modifier);

  /// Permanently removes the previously stored [model.ReceptionDialplan] object
  /// identified by [extension].
  ///
  /// The [modifier] is required for traceability of who performed the deletion.
  Future<Null> remove(String extension, model.User modifier);

  /// List dialplan object changes for the store, optionally for a
  /// single [extension].
  Future<List<model.Commit>> changes([String extension]);
}
