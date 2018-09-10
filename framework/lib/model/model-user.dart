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

/// User groups "enum".
abstract class UserGroups {
  /// Receptionist group.
  static const String receptionist = 'Receptionist';

  /// Administrator group.
  static const String administrator = 'Administrator';

  /// Service agent group.
  static const String serviceAgent = 'Service agent';

  /// List of all valid groups.
  static const Iterable<String> validGroups = const <String>[
    receptionist,
    administrator,
    serviceAgent
  ];

  /// Determine if [group] is valid.
  static bool isValid(String group) => validGroups.toSet().contains(group);
}

class UserReference implements ObjectReference {
  @override
  final int id;
  @override
  final String name;

  const UserReference(this.id, this.name);

  factory UserReference.fromJson(Map<String, dynamic> map) =>
      new UserReference(map[key.id], map[key.name]);

  @deprecated
  static UserReference decode(Map<String, dynamic> map) =>
      new UserReference.fromJson(map);

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() =>
      <String, dynamic>{key.id: id, key.name: name};

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is UserReference && other.id == id;
}

/// User model class.
class User {
  /// Static ID representing no user.
  ///
  /// Also used as special ID for system user.
  static const int noId = 0;

  /// Primary email address
  String address;

  /// ID of the user (uid)
  int id = noId;

  /// Name of the user
  String name = '';

  /// The current phone extension.
  String extension = '';

  /// User portrait URI.
  String portrait = '';

  /// The current groups that the user is member of
  Set<String> groups = new Set<String>();

  /// Authentication identities
  Set<String> identities = new Set<String>();

  /// Constructor for creating an empty object.
  User.empty();

  /// Deserializing constructor.
  User.fromJson(Map<String, dynamic> map)
      : id = map[key.id],
        address = map[key.address],
        name = map[key.name],
        extension = map[key.extension],
        groups = map.containsKey(key.groups)
            ? Set<String>.from(map[key.groups])
            : Set<String>(),
        identities = map.containsKey(key.identites)
            ? Set<String>.from(map[key.identites])
            : Set<String>(),
        portrait = map.containsKey('remote_attributes') &&
                (map['remote_attributes'] as Map<String, dynamic>)
                    .containsKey('picture')
            ? (map['remote_attributes'] as Map<String, dynamic>)['picture']
            : '';

  /// Deserializing factory
  @deprecated
  static User decode(Map<String, dynamic> map) => new User.fromJson(map);

  /// Serialization function.
  Map<String, dynamic> toJson() => <String, dynamic>{
        key.id: id,
        key.name: name,
        key.identites: identities.toList(growable: false),
        key.address: address,
        key.extension: extension,
        key.groups: groups.toList(growable: false)
      };

  /// The short-hand reference object of the user.
  UserReference get reference => new UserReference(id, name);
}
