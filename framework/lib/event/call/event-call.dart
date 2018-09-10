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

/// Convenience class/interface that provides a mean for grouping all
/// call-related events and providing a common shared interface for them.
abstract class CallEvent implements Event {
  /// Generative constructor for use
  CallEvent(this.call) : timestamp = DateTime.now();

  /// Generative constructor needed by specializations of the [CallEvent] class.
  CallEvent.fromJson(Map<String, dynamic> map)
      : call = model.Call.fromJson(map[_Key._call] as Map<String, dynamic>),
        timestamp = util.unixTimestampToDateTime((map[_Key._timestamp] as int));

  @override
  final DateTime timestamp;

  /// The [model.Call] object of the event.
  final model.Call call;
}
