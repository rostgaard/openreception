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

class Message {
  /// Constructor.
  Message(this._store, this._user);
  final service.RESTMessageStore _store;
  final model.User _user;

  /// Enqueues a [model.Message] object.
  Future<model.MessageQueueEntry> enqueue(model.Message message) =>
      _store.enqueue(message);

  /// Fetch the [messageID] [model.Message].
  Future<model.Message> get(int messageID) => _store.get(messageID);

  /// Return an iterable containing [model.Message] taken on the supplied [day].
  Future<Iterable<model.Message>> list(DateTime day) => _store.listDay(day);

  /// Return an iterable containing [model.Message] drafts.
  Future<Iterable<model.Message>> listDrafts() => _store.listDrafts();

  /// Delete [messageId] from the database. Throws Storage.NotFound if the
  /// message does not exist or if the action did not succeed.
  Future remove(int messageId) => _store.remove(messageId, _user);

  /// Saves a [model.Message] object.
  Future<model.Message> save(model.Message message) =>
      message.id == model.Message.noId
          ? _store.create(message, _user)
          : _store.update(message, _user);
}
