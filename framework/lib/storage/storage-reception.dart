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

/// Storage interface for persistent storage of [model.Reception] objects.
abstract class Reception {
  /// Creates and stores a new [model.Reception] object persistently
  /// using [reception] data.
  ///
  /// Returns a [model.ReceptionReference] containing the ID of the newly created
  /// [model.Reception] object. The [modifier] is required for traceability of
  /// who performed the creation.
  Future<model.ReceptionReference> create(
      model.Reception reception, model.User modifier);

  /// Retrive a previously stored [model.Reception] identified by [rid].
  Future<model.Reception> get(int rid);

  /// Retrieve a list of [model.ReceptionReference] to all available receptions
  /// in the store.
  Future<List<model.ReceptionReference>> list();

  /// Permanently removes the previously stored [model.Reception] object
  /// identified by [rid].
  ///
  /// The [modifier] is required for traceability of who performed the deletion.
  Future<Null> remove(int rid, model.User modifier);

  /// Updates the previously stored [model.Reception] object with data
  /// from [reception].
  ///
  /// The ID in [reception] must be valid and exist in the store, or a [NotFound]
  /// exception is thrown.
  Future<model.ReceptionReference> update(
      model.Reception reception, model.User modifier);

  /// List reception object changes for the store, optionally for a single [rid].
  Future<List<model.Commit>> changes([int rid]);
}
