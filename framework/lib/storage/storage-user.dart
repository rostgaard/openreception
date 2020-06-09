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

/// Storage interface for persistent storage of [model.User] objects.
abstract class User {
  /// Retrive a previously stored [model.User] identified by [uid].
  Future<model.User> get(int uid);

  /// Retrive a previously stored [model.User] with [identity].
  Future<model.User> getByIdentity(String identity);

  /// Retrieve a list of all available groups of the system.
  Future<List<String>> groups();

  /// Retrieve a list of [model.UserReference] to all available users in
  /// the store.
  Future<List<model.UserReference>> list();

  /// Creates and stores a new [model.User] object persistently using [user] data.
  ///
  /// Returns a [model.UserReference] containing the ID of the newly created
  /// [model.User] object. The [modifier] is required for traceability of
  /// who performed the creation.
  Future<model.UserReference> create(model.User user, model.User modifier);

  /// Updates the previously stored [model.User] object with data
  /// from [user].
  ///
  /// The ID in [user] must be valid and exist in the store, or a [NotFound]
  /// exception is thrown.
  Future<model.UserReference> update(model.User user, model.User modifier);

  /// Permanently removes the previously stored [model.User] object identified
  /// by [uid].
  ///
  /// The [modifier] is required for traceability of who performed the deletion.
  Future<Null> remove(int uid, model.User modifier);

  /// List user object changes for the store, optionally for a single [uid].
  Future<List<model.Commit>> changes([int uid]);
}
