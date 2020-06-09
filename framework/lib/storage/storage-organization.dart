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

/// Storage interface for persistent storage of [model.Organization] objects.
abstract class Organization {
  /// Return a list of [model.BaseContact]s associated with [oid].
  Future<List<model.BaseContact>> contacts(int oid);

  /// Creates and stores a new [model.Organization] object persistently
  /// using [organization] data.
  ///
  /// Returns a [model.OrganizationReference] containing the ID of the newly
  /// created [model.Organization] object.
  /// The [modifier] is required for traceability of who performed the creation.
  Future<model.OrganizationReference> create(
      model.Organization organization, model.User modifier);

  /// Retrive a previously stored [model.Organization] identified by [oid].
  Future<model.Organization> get(int oid);

  /// Retrieve a list of [model.OrganizationReference] to all available
  /// organization in the store.
  Future<List<model.OrganizationReference>> list();

  /// Permanently removes the previously stored [model.Organization] object
  /// identified by [oid].
  ///
  /// The [modifier] is required for traceability of who performed the deletion.
  Future<Null> remove(int oid, model.User modifier);

  /// Updates the previously stored [model.Organization] object with data
  /// from [organization].
  ///
  /// The ID in [organization] must be valid and exist in the store, or
  /// a [NotFound] exception is thrown.
  Future<model.OrganizationReference> update(
      model.Organization organization, model.User modifier);

  /// Retrieve a list of [model.ReceptionReference]s associated with [oid].
  Future<List<model.ReceptionReference>> receptions(int oid);

  /// List organization object changes for the store, optionally for a
  /// single [oid].
  Future<List<model.Commit>> changes([int oid]);

}
