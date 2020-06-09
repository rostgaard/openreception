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

/// Storage interface for persistent storage of [model.IvrMenu] objects.
abstract class Ivr {
  /// Creates and stores a new [model.IvrMenu] object persistently
  /// using [menu] data.
  ///
  /// Returns a [model.IvrMenu] containing the ID of the newly created
  /// [model.IvrMenu] object. The [modifier] is required for traceability of
  /// who performed the creation.
  Future<model.IvrMenu> create(model.IvrMenu menu, model.User modifier);

  /// Retrive a previously stored [model.IvrMenu] identified by [menuName].
  Future<model.IvrMenu> get(String menuName);

  /// Retrieve a list of [model.IvrMenu] objects in the store.
  Future<List<model.IvrMenu>> list();

  /// Updates the previously stored [model.IvrMenu] object with data
  /// from [menu].
  ///
  /// The ID in [menu] must be valid and exist in the store, or a [NotFound]
  /// exception is thrown.
  Future<model.IvrMenu> update(model.IvrMenu menu, model.User modifier);

  /// Permanently removes the previously stored [model.IvrMenu] object identified
  /// by [menuName].
  ///
  /// The [modifier] is required for traceability of who performed the deletion.
  Future<Null> remove(String menuName, model.User modifier);

  /// List IVR menu object changes for the store, optionally for a
  /// single [menuName].
  Future<List<model.Commit>> changes([String menuName]);
}
