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

/// Valid states for a message.
enum MessageState {
  /// Default initialized state, without anything other specified.
  unknown,

  /// Message is current a draft in composition.
  draft,

  /// Message has been sent
  sent,

  /// Message has been closed manually
  closed
}

class Message {
  static const int noId = 0;

  Set<MessageEndpoint> recipients = new Set<MessageEndpoint>();

  int id = noId;
  MessageContext context = new MessageContext.empty();
  MessageFlag flag = new MessageFlag.empty();
  MessageState state = MessageState.unknown;

  CallerInfo callerInfo;
  DateTime createdAt;
  String body = '';
  String callId = '';

  /// The user of the sender.
  User sender;

  /// Default empty constructor.
  Message.empty();

  /// Deserializing constructor.
  Message.fromJson(Map<String, dynamic> map) {
    Iterable<MessageEndpoint> iterRcp = (map[key.recipients]
            as Iterable<dynamic>)
        .map((map) => MessageEndpoint.fromJson(map));

    id = (map.containsKey(key.id) ? map[key.id] : noId);
    recipients.addAll(iterRcp);
    context = MessageContext.fromJson(map[key.context] as Map<String, dynamic>);
    flag = MessageFlag(List<String>.from(map['flags']));
    callerInfo =
        new CallerInfo.fromJson(map[key.caller] as Map<String, dynamic>);
    body = map[key.body];
    callId = map[key.callId];
    sender = new User.fromJson(map[key.takenByAgent] as Map<String, dynamic>);
    createdAt = util.unixTimestampToDateTime(map[key.createdAt]);

    if (map[key.state] == null) {
      state = MessageState.unknown;
    } else if (map[key.state] == MessageState.values.length) {
      state = MessageState.unknown;
    } else {
      state = MessageState.values[map[key.state]];
    }
  }

  bool get isClosed => state == MessageState.closed;
  bool get isDraft => state == MessageState.draft;
  bool get isSent => state == MessageState.sent;
  bool get isUnknown => state == MessageState.unknown;

  Iterable<MessageEndpoint> get emailTo => recipients
      .where((MessageEndpoint ep) => ep.type == MessageEndpointType.emailTo);

  Iterable<MessageEndpoint> get emailCc => recipients
      .where((MessageEndpoint ep) => ep.type == MessageEndpointType.emailCc);

  Iterable<MessageEndpoint> get emailBcc => recipients
      .where((MessageEndpoint ep) => ep.type == MessageEndpointType.emailBcc);

  Iterable<MessageEndpoint> get sms => recipients
      .where((MessageEndpoint ep) => ep.type == MessageEndpointType.sms);

  bool get hasRecpients => recipients.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
        key.id: id,
        key.body: body,
        key.context: context.toJson(),
        key.takenByAgent: sender.toJson(),
        key.caller: callerInfo.toJson(),
        key.callId: callId,
        key.flags: flag.toJson(),
        key.createdAt: util.dateTimeToUnixTimestamp(createdAt),
        key.recipients: recipients
            .map((MessageEndpoint ep) => ep.toJson())
            .toList(growable: false),
        key.state: state.index
      };

  @deprecated
  static Message decode(Map<String, dynamic> map) => new Message.fromJson(map);

  @deprecated
  Map<String, dynamic> get asMap => toJson();
}
