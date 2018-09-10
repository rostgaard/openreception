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

part of orf.event;

/// General event class that is meant to be emitted upon _any_ channel update.
/// Used primarily in development environment to notify clients about raw channel
/// updates. This is very useful for debuggin UI's.
class ChannelState implements Event {
  @override
  final DateTime timestamp;
  @override
  final String eventName = _Key._channelState;

  /// The uuid of the channel that changed state.
  final String channelUuid;

  /// Create a [ChannelState] event for [channelUuid].
  ChannelState(this.channelUuid) : timestamp = DateTime.now();

  /// Create a [ChannelState] object from serialized data stored in [map].
  ChannelState.fromJson(Map<String, dynamic> map)
      : channelUuid = map[_Key._channel][_Key._id] as String,
        timestamp = util.unixTimestampToDateTime(map[_Key._timestamp] as int);

  /// Returns an umodifiable map representation of the object, suitable for
  /// serialization.
  @override
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.unmodifiable(<String, dynamic>{
        _Key._event: eventName,
        _Key._timestamp: util.dateTimeToUnixTimestamp(timestamp),
        _Key._channel: <String, dynamic>{_Key._id: channelUuid}
      });

  /// Returns a brief string-represented summary of the event, suitable for
  /// logging or debugging purposes.
  @override
  String toString() => '$timestamp-$eventName $channelUuid';
}
