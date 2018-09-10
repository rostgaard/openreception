/*                  This file is part of OpenReception
                   Copyright (C) 2016-, BitStackers K/S

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

/// Event for notifying about a change in the UI. Specifically, a change of
///  whether or not the window (or tab) is in focus or not.
class FocusChange implements Event {
  @override
  final DateTime timestamp;

  @override
  final String eventName = _Key._focusChange;

  /// The user ID of the user that changed focus.
  final int uid;

  /// Determines if the application is in focus.
  final bool inFocus;

  /// Default constructor. Takes [uid] of the user changing the widget and
  ///  the focus state ([inFocus]) as mandatory arguments.
  FocusChange(this.uid, this.inFocus) : timestamp = DateTime.now();

  /// Bluring constructor. Takes [uid] of the user changing the widget and
  /// returns an event with [inFocus] set to `false`.
  FocusChange.blur(this.uid)
      : inFocus = false,
        timestamp = DateTime.now();

  /// Focusing constructor. Takes [uid] of the user changing the widget and
  /// returns an event with [inFocus] set to `true`.
  FocusChange.focus(this.uid)
      : inFocus = true,
        timestamp = DateTime.now();

  /// Create a [FocusChange] object from serialized data stored in [map].
  FocusChange.fromJson(Map<String, dynamic> map)
      : uid = map[_Key._changedBy],
        inFocus = map[_Key._inFocus],
        timestamp = util.unixTimestampToDateTime(map[_Key._timestamp]);

  /// Returns an umodifiable map representation of the object, suitable for
  /// serialization.
  @override
  Map<String, dynamic> toJson() =>
      Map<String, dynamic>.unmodifiable(<String, dynamic>{
        _Key._event: eventName,
        _Key._timestamp: util.dateTimeToUnixTimestamp(timestamp),
        _Key._changedBy: uid,
        _Key._inFocus: inFocus
      });

  /// Returns a brief string-represented summary of the event, suitable for
  /// logging or debugging purposes.
  @override
  String toString() => '$timestamp-$eventName '
      'uid:$uid, '
      'focus:$inFocus';
}
