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

part of orf.model.monitoring;

/// Model class for persistent storage of message/user log entry.
///
/// The log entry will record when a message was created, by whom, and
/// store a reference to the ID message that was created.
class MessageHistory {
  /// The ID of the message that was created.
  final int mid;

  /// The ID of the user that created the message.
  final int uid;

  /// The creation time of the message.
  final DateTime createdAt;

  /// Creates a new [MessageHistory] log entry from values.
  MessageHistory(this.mid, this.uid, this.createdAt);

  /// Creates a new [MessageHistory] log entry from a decoded map.
  factory MessageHistory.fromJson(Map<String, dynamic> map) {
    final int mid = map['mid'] != null ? map['mid'] : noId;
    final int uid = map['uid'] != null ? map['uid'] : noId;

    final DateTime createdAt = DateTime.parse(map['created']);

    return new MessageHistory(mid, uid, createdAt);
  }

  /// The hash of a [MessageHistory] entry is different if at least one
  /// value differs.
  ///
  /// If no values differ, the hashcode is the same.
  @override
  int get hashCode => '$mid.$uid.${createdAt.millisecondsSinceEpoch}'.hashCode;

  /// Serialization function.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'mid': mid,
        'uid': uid,
        'created': createdAt.toString()
      };

  /// A [MessageHistory] object is equal to another [MessageHistory] object
  /// if their [mid] are the same.
  ///
  /// The motivation for this, is that any message is created _exactly once_
  /// and message ids should, by definition, _never_ be duplicated in
  /// message history logs.
  @override
  bool operator ==(Object other) => other is MessageHistory && other.mid == mid;
}
