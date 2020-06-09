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

/// Storage interface for persistent storage of [model.Message] objects.
abstract class Message {
  /// Retrive a previously stored [model.Message] identified by [mid].
  Future<model.Message> get(int mid);

  /// Get messages with [ids].
  Future<List<model.Message>> getByIds(List<int> ids);

  /// List all messages that was created on given [day].
  Future<List<model.Message>> listDay(DateTime day);

  /// List all draft messages currently stored in this message store.
  Future<List<model.Message>> listDrafts();

  /// Creates and stores a new [model.Message] object persistently
  /// using [message] data.
  ///
  /// Returns a [model.Message] containing the ID of the newly created
  /// [model.Message] object. The [modifier] is required for traceability of
  /// who performed the creation.
  Future<model.Message> create(model.Message message, model.User modifier);

  /// Updates the previously stored [model.Message] object with data
  /// from [message].
  ///
  /// The ID in [message] must be valid and exist in the store, or a [NotFound]
  /// exception is thrown.
  Future<model.Message> update(model.Message message, model.User modifier);

  /// Permanently removes the previously stored [model.Message] object identified
  /// by [mid].
  ///
  /// The [modifier] is required for traceability of who performed the deletion.
  Future<Null> remove(int mid, model.User modifier);

  /// List message object changes for the store, optionally for a single [mid].
  Future<List<model.Commit>> changes([int mid]);
}
