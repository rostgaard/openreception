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

/// Storage interface for persistent storage of [model.MessageQueueEntry] objects.
abstract class MessageQueue {
  /// Enqueue a message.
  ///
  /// Returns the [model.MessageQueueEntry] object that was created as an
  /// effect of the [enqueue] action.
  Future<model.MessageQueueEntry> enqueue(model.Message message);

  /// Update an existing [queueEntry].
  Future<Null> update(model.MessageQueueEntry queueEntry);

  /// Remove the [model.MessageQueueEntry] with [mqid].
  Future<Null> remove(int mqid);

  /// List every [model.MessageQueueEntry] currently stored.
  Future<List<model.MessageQueueEntry>> list();
}
