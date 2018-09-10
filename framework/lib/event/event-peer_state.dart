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

/// Event class that is emitted upon [model.Peer] registration status change.
class PeerState implements Event {
  @override
  final DateTime timestamp;
  @override
  final String eventName = _Key._peerState;

  /// The peer that changed state.
  final model.Peer peer;

  /// Create a [PeerState] object from a [model.Peer] object.
  PeerState(this.peer) : this.timestamp = DateTime.now();

  /// Create a [PeerState] object from serialized data stored in [map].
  PeerState.fromJson(Map<String, dynamic> map)
      : this.peer =
            model.Peer.fromJson(map[_Key._peer] as Map<String, dynamic>),
        this.timestamp = util.unixTimestampToDateTime(map[_Key._timestamp]);

  /// Returns an umodifiable map representation of the object, suitable for
  /// serialization.
  @override
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.unmodifiable(<String, dynamic>{
        _Key._event: eventName,
        _Key._timestamp: util.dateTimeToUnixTimestamp(timestamp),
        _Key._peer: peer.toJson()
      });

  /// Returns a brief string-represented summary of the event, suitable for
  /// logging or debugging purposes.
  @override
  String toString() => '$timestamp-$eventName ${peer.name}, '
      'reg:${peer.registered}';
}
