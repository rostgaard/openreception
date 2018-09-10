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

part of orf.model;

/// Class representing an organization.
class Organization {
  /// Default empty constructor.
  Organization.empty();

  /// Constructor used for deserialization.
  Organization.fromJson(Map<String, dynamic> map)
      : id = map[key.id],
        name = map[key.name],
        notes = map.containsKey(key.notes)
            ? stringList(map[key.notes])
            : <String>[];

  static const int noId = 0;

  int id = noId;
  String name = '';
  List<String> notes = <String>[];

  /// Deserializing factory.
  @deprecated
  static Organization decode(Map<String, dynamic> map) =>
      new Organization.fromJson(map);

  OrganizationReference get reference => new OrganizationReference(id, name);

  /// Returns a Map representation of the Organization.
  ///
  /// Serialization function.

  Map<String, dynamic> toJson() =>
      <String, dynamic>{key.id: id, key.name: name, key.notes: notes};

  @override
  String toString() => toJson().toString();
}
