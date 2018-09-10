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

///Class representing an IVR menu.
class IvrMenu {
  /// Default constructor.
  IvrMenu(this.name, this.greetingLong);

  /// Decoding factory.
  factory IvrMenu.fromJson(Map<String, dynamic> map) =>
      (IvrMenu(map[key.name] as String, Playback.parse(map[key.greeting] as String))

        .._greetingShort = Playback.parse(map[key.greetingShort] as String))
        ..entries =
        ((map[key.ivrEntries] as List<dynamic>).cast<String>()
          .map<IvrEntry>(IvrEntry.parse)
            .toList())
        ..submenus = List<IvrMenu>.from((map[key.submenus] as List<dynamic>)
            .map<IvrMenu>((dynamic map) => IvrMenu.fromJson(map as Map<String, dynamic>)));

  /// Name of IVR menu.
  String name;

  /// The entries (different possible actions) of the IVR menu
  List<IvrEntry> entries = <IvrEntry>[];

  /// The initial greeting of the menu.
  final Playback greetingLong;

  /// Submenus of this menu.
  List<IvrMenu> submenus = <IvrMenu>[];

  Playback _greetingShort = Playback.none;

  /// Extracts the contained [Action] objects from the menu.
  Iterable<Action> get allActions {
    final List<Action> actions = List<Action>();

    entries.fold(actions, (List<Action> list, IvrEntry entry) {
      if (entry is IvrTransfer) {
        list.add(entry.transfer);
      } else if (entry is IvrVoicemail) {
        list.add(entry.voicemail);
      } else if (entry is IvrReceptionTransfer) {
        list.add(entry.transfer);
      } else if (entry is IvrSubmenu || entry is IvrTopmenu) {
      } else
        throw StateError('Unknown type in entries: ${entry.runtimeType}');

      return list;
    });

    return actions;
  }

  /// The, shorter, greeting for repeating choices.
  Playback get greetingShort =>
      _greetingShort != Playback.none ? _greetingShort : greetingLong;

  /// Decoding factory method.
  @deprecated
  static IvrMenu decode(Map<String, dynamic> map) => IvrMenu.fromJson(map);

  /// An IVR menu equals another IVR menu if their names match.
  @override
  bool operator ==(Object other) => other is IvrMenu && this.name == other.name;

  /// Serialization function.
  Map<String, dynamic> toJson() => <String, dynamic>{
        key.name: name,
        key.greeting: greetingLong.toJson(),
        key.greetingShort: greetingShort.toJson(),
        key.ivrEntries: entries
            .map<dynamic>((IvrEntry entry) => entry.toJson())
            .toList(growable: false),
        key.submenus: submenus
            .map((IvrMenu menu) => menu.toJson())
            .toList(growable: false)
      };

  @override
  int get hashCode => name.hashCode;
}
