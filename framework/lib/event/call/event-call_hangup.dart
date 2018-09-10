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

/// Event that is spawned when the channel of a call destroyed. Must only occur
/// once for every call.
class CallHangup extends CallEvent {
  /// Default constructor. Subtypes the general [CallEvent] class.
  ///
  /// Takes the [model.Call] being hung up as well as an optional [hangupCause].
  /// The [hangupCause] should be copied from the PBX hangup reason text.
  CallHangup(model.Call call, {this.hangupCause: ''}) : super(call);

  /// Create a [CallHangup] object from serialized data stored in [map].
  CallHangup.fromJson(Map<String, dynamic> map)
      : hangupCause = map[_Key._hangupCause] as String,
        super.fromJson(map);

  @override
  final String eventName = _Key._callHangup;

  /// The hangup cause associated with the [call] of this event.
  ///
  /// The hangup cause string is directly forwarded from the PBX and may be
  /// referenced in the table located at:
  /// https://freeswitch.org/confluence/display/FREESWITCH/Hangup+Cause+Code+Table
  final String hangupCause;

  /// Returns an unmodifiable map representation of the object, suitable for
  /// serialization.
  @override
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.unmodifiable(<String, dynamic>{
        _Key._event: eventName,
        _Key._timestamp: util.dateTimeToUnixTimestamp(timestamp),
        _Key._hangupCause: this.hangupCause,
        _Key._call: call.toJson()
      });

  /// Returns a brief string-represented summary of the event, suitable for
  /// logging or debugging purposes.
  @override
  String toString() => '$timestamp-$eventName ${call.id}';
}
