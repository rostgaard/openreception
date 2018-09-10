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

/// Model classes for dialplans.
part of orf.model.dialplan;

/// Interface for extensions.
///
/// Every realization of the interface must provide a [name], a [List]
/// of [actions] and a serialization function ([toJson()]).
/// These fields and this method is used by the dialplan compiler.
abstract class Extension {
  /// The name of the extension, which effectively is the extension itself.
  /// An example of an extension name could be `34904622-test`. There is
  /// no requirement, at this level, that the extension is PTSN-reachable.
  String get name;

  /// The actions that will be executed, if the extension is reached.
  List<Action> get actions;

  /// Serialization function.
  Map<String, dynamic> toJson();
}

/// Model class for an extension without conditions, other than the
/// extension name which must match the channel destination of a channel.
///
/// The class is meant as a way to execute a specific set of actions in a
/// dialplan by simply transferring a channel to the [name] of the
/// [NamedExtension].
class NamedExtension implements Extension {
  @override
  final String name;

  @override
  final List<Action> actions;

  /// Create a new [NamedExtension] with [name] that performs [actions] on a
  /// channel, once reached.
  NamedExtension(this.name, this.actions);

  /// Decode a [Map] into a new [NamedExtension] object.
  factory NamedExtension.fromJson(Map<String, Object> map) {
    final Iterable<Action> actionIter =
        (map[key.actions] as Iterable<dynamic>).map(Action.parse);

    return new NamedExtension(
        map[key.name], actionIter.toList(growable: false));
  }

  /// Decode a [Map] into a new [NamedExtension] object.
  @deprecated
  static NamedExtension decode(Map<String, dynamic> map) =>
      new NamedExtension.fromJson(map);

  /// Serialization function. Suitable for creating a new object from
  /// the [NamedExtension.fromJson] constructor.
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{key.name: name, key.actions: actions};
}
