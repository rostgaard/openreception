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

/// Extract all [Playback] actions of a [ReceptionDialplan].
Iterable<Playback> playbackActions(ReceptionDialplan rdp) =>
    rdp.allActions.whereType<Playback>();

/// Dialplan class for a reception.
class ReceptionDialplan {
  ReceptionDialplan();

  /// Decodes and creates a [ReceptionDialplan] from a previously
  /// deserialized [Map].
  factory ReceptionDialplan.fromJson(final Map<String, dynamic> map) =>
      ReceptionDialplan()
        ..extension = map['extension'] as String
        ..open = List<HourAction>.from(
            (map['open'] as List<dynamic>).map<HourAction>((dynamic map) => HourAction.parse(map as Map<String, dynamic>)))
        ..extraExtensions =
            (map['extraExtensions'] as List<dynamic>)
                .map((dynamic map) => NamedExtension.fromJson(map as Map<String, dynamic>))
                .toList()
        ..defaultActions =
           (map['closed'] as List<dynamic>).cast<String>().map(Action.parse).toList()
        ..note = map['note'] as String;
  /// The extension that this reception dialplan may be reached at.
  ///
  /// This value is typically a PSTN number reachable from that net.
  String extension = 'empty';

  /// The list of opening hours of the reception.
  List<HourAction> open = <HourAction>[];

  /// Descriptive note for this [ReceptionDialplan].
  String note = '';

  /// Determines if this [ReceptionDialplan] is active.
  @deprecated
  bool active = true;

  /// A list of sub-extensions used by this [ReceptionDialplan].
  List<NamedExtension> extraExtensions = <NamedExtension>[];

  /// Collect an [Iterable] of all actions in this [ReceptionDialplan].
  Iterable<Action> get allActions => <Action>[]
    ..addAll(defaultActions)
    ..addAll(open.fold(
        <Action>[],
        (List<Action> list, HourAction hour) =>
            list..addAll(hour.actions)).toList())
    ..addAll(extraExtensions.fold(
        <Action>[],
        (List<Action> list, NamedExtension exten) =>
            list..addAll(exten.actions)).toList());

  /// The [Action]s to execute if none of the [open] hours match.
  List<Action> defaultActions = <Action>[];

  /// Decodes and creates a [ReceptionDialplan] from a previously
  /// deserialized [Map].
  @deprecated
  static ReceptionDialplan decode(Map<String, dynamic> map) =>
      ReceptionDialplan.fromJson(map);

  /// Serialization function.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'extension': extension,
        'open': List<Map<String, dynamic>>.from(
            open.map<Map<String,dynamic>>((HourAction ha) => ha.toJson())),
        'note': note,
        'closed':
            List<String>.from(defaultActions.map<dynamic>((Action a) => a.toJson())),
        'extraExtensions': List<Map<String, dynamic>>.from(
            extraExtensions.map<Map<String,dynamic>>((NamedExtension ee) => ee.toJson())),
      };
}
