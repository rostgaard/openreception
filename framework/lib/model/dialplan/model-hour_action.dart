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

part of orf.model.dialplan;

/// Class wrapping an ordered list of actions that is guarded by [hours].
class HourAction {
  /// The [OpeningHour]s that needs to match for [actions] to be executed.
  List<OpeningHour> hours = <OpeningHour>[];

  /// The [Action]s to be executed.
  List<Action> actions = <Action>[];

  /// Debug-friendly string representation of the object.
  @override
  String toString() => '${hours.join(', ')} - ${actions.join(',')}';

  /// Parse and create a new [HourAction] objec from a decoded [Map].
  static HourAction parse(Map<String, Object> map) => new HourAction()
    ..hours = parseMultipleHours(map['hours']).toList()
    ..actions = List<String>.from(map['actions']).map(Action.parse).toList();

  /// Serialization function.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'hours': hours.map((OpeningHour hour) => hour.toJson()).join(', '),
        'actions': actions
      };

  /// Two [HourAction] objects are equal if the contains the same hours
  /// and actions.
  @override
  bool operator ==(Object other) {
    if (other is HourAction) {
      final Set<OpeningHour> ohLhs = hours.toSet();
      final Set<OpeningHour> ohRhs = other.hours.toSet();

      final Set<Action> aLhs = actions.toSet();
      final Set<Action> aRhs = other.actions.toSet();

      return ohLhs.containsAll(ohRhs) &&
          ohRhs.containsAll(ohLhs) &&
          aLhs.containsAll(aRhs) &&
          aRhs.containsAll(aLhs);
    }
    return false;
  }

  /// Hash code follows convention from [==].
  @override
  int get hashCode => ((new List<OpeningHour>.from(hours)..sort()).join('::') +
          (new List<Action>.from(actions)..sort()).join('::'))
      .hashCode;
}
