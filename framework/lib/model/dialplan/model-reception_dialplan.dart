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
    rdp.allActions.where((Action a) => a is Playback);

/// Dialplan class for a reception.
class ReceptionDialplan {
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

  ReceptionDialplan();

  /// Decodes and creates a new [ReceptionDialplan] from a previously
  /// deserialized [Map].
  factory ReceptionDialplan.fromJson(Map<String, dynamic> map) =>
      new ReceptionDialplan()
        ..extension = map['extension']
        ..open = new List<HourAction>.from(
            List<Map<String, Object>>.from(map['open']).map(HourAction.parse))
        ..extraExtensions =
            List<Map<String,Object>>.from(map['extraExtensions']).map(
                (Map<String, Object> map) => NamedExtension.fromJson(map)).toList()
        ..defaultActions =
            new List<Action>.from(map['closed'].map(Action.parse))
        ..note = map['note'];

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

  /// Decodes and creates a new [ReceptionDialplan] from a previously
  /// deserialized [Map].
  @deprecated
  static ReceptionDialplan decode(Map<String, dynamic> map) =>
      new ReceptionDialplan.fromJson(map);

  /// Serialization function.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'extension': extension,
        'open': new List<Map<String, dynamic>>.from(
            open.map((HourAction ha) => ha.toJson())),
        'note': note,
        'closed':
            new List<String>.from(defaultActions.map((Action a) => a.toJson())),
        'extraExtensions': new List<Map<String, dynamic>>.from(
            extraExtensions.map((NamedExtension ee) => ee.toJson())),
      };
}
