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

part of orf.model;

class MessageQueueEntry {
  final DateTime createdAt;
  Set<MessageEndpoint> _handledRecipients = new Set<MessageEndpoint>();
  int id = noId;
  static const int noId = 0;
  int tries = 0;
  Set<MessageEndpoint> _unhandledRecipients = new Set<MessageEndpoint>();

  /// Default constructor
  Message message = new Message.empty();

  /// Default empty constructor.
  MessageQueueEntry.empty() : createdAt = new DateTime.now();

  /// Creates a message from the information given in [map].
  MessageQueueEntry.fromJson(Map<String, dynamic> map)
      : createdAt = util.unixTimestampToDateTime(map[key.createdAt]),
        id = map[key.id],
        message = Message.fromJson(map[key.message]),
        _handledRecipients = List<dynamic>.from(map[key.handledRecipients])
            .fold(Set<MessageEndpoint>(),
                (s, map) => s..add(new MessageEndpoint.fromJson(map))),
        _unhandledRecipients = List<dynamic>.from(map[key.unhandledRecipients])
            .fold(Set<MessageEndpoint>(),
                (s, map) => s..add(new MessageEndpoint.fromJson(map))),
        tries = map[key.tries];

  /// Decoding factory.
  @deprecated
  static MessageQueueEntry decode(Map<String, dynamic> map) =>
      new MessageQueueEntry.fromJson(map);

  Iterable<MessageEndpoint> get handledRecipients => _handledRecipients;

  /// Update the handled recipients set.
  ///
  /// This operation will automatically remove the handled recipients from
  /// the unhandled set by using the aweseom power of math set theory.
  set handledRecipients(Iterable<MessageEndpoint> handled) {
    _unhandledRecipients = _unhandledRecipients.difference(handled.toSet());
    _handledRecipients.addAll(handled);
  }

  /// Serialization function
  Map<String, dynamic> toJson() => <String, dynamic>{
        key.id: id,
        key.tries: tries,
        key.createdAt: util.dateTimeToUnixTimestamp(createdAt),
        key.message: message.toJson(),
        key.handledRecipients: _handledRecipients
            .map((MessageEndpoint r) => r.toJson())
            .toList(growable: false),
        key.unhandledRecipients: _unhandledRecipients
            .map((MessageEndpoint r) => r.toJson())
            .toList(growable: false)
      };

  Iterable<MessageEndpoint> get unhandledRecipients => _unhandledRecipients;

  /// Set the unhandled recipients set.
  set unhandledRecipients(Iterable<MessageEndpoint> unhandled) {
    _unhandledRecipients = new Set<MessageEndpoint>()
      ..addAll(unhandled.toSet());
  }
}
