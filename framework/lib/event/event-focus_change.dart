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

part of openreception.framework.event;

/// Event for notifying about a change in the UI. Specifically, a change of
///  whether or not the window (or tab) is in focus or not.
class FocusChange implements Event {
  /// Common [Event] fields.
  @override
  final DateTime timestamp;
  @override
  String get eventName => _Key._focusChange;

  /// The user ID of the user that changed focus.
  final int uid;

  /// Determines if the application is in focus.
  final bool inFocus;

  /// Default constructor. Takes [uid] of the user changing the widget and
  ///  the new focus state ([inFocus]) as mandatory arguments.
  FocusChange(int this.uid, bool this.inFocus) : timestamp = new DateTime.now();

  /// Bluring constructor. Takes [uid] of the user changing the widget and
  /// returns an event with [inFocus] set to [false].
  FocusChange.blur(int this.uid)
      : inFocus = false,
        timestamp = new DateTime.now();

  /// Focusing constructor. Takes [uid] of the user changing the widget and
  /// returns an event with [inFocus] set to [true].
  FocusChange.focus(int this.uid)
      : inFocus = true,
        timestamp = new DateTime.now();

  /// Deserializing constructor.
  FocusChange.fromMap(Map map)
      : uid = map[_Key._changedBy],
        inFocus = map[_Key._inFocus],
        timestamp = util.unixTimestampToDateTime(map[_Key._timestamp]);

  /// Serialization function.
  @override
  Map toJson() => {
        _Key._event: eventName,
        _Key._timestamp: util.dateTimeToUnixTimestamp(timestamp),
        _Key._changedBy: uid,
        _Key._inFocus: inFocus
      };

  /// Returns a string reprensentation of the object.
  @override
  String toString() => toJson().toString();
}
