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

part of orf.service;

/// Calendar store client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
class RESTCalendarStore implements storage.Calendar {
  RESTCalendarStore(this.host, this.token, this._backend);

  final WebService _backend;

  /// The uri of the connected backend.
  final Uri host;

  /// The token used for authenticating with the backed.
  final String token;

  Future<String> changelog(model.Owner owner) {
    Uri url = resource.Calendar.changelog(host, owner);
    url = _appendToken(url, token);

    return _backend.get(url);
  }

  @override
  Future<Iterable<model.Commit>> changes(model.Owner owner, [int eid]) async {
    Uri url = resource.Calendar.changeList(host, owner, eid);
    url = _appendToken(url, token);

    final String body = await _backend.get(url);
    final List<dynamic> maps =
        _json.decode(body) as List<dynamic>;

    return maps.map((dynamic map) => model.Commit.fromJson(map as Map<String, dynamic>));
  }

  @override
  Future<model.CalendarEntry> create(
      model.CalendarEntry entry, model.Owner owner, model.User user) async {
    Uri url = resource.Calendar.ownerBase(host, owner);
    url = _appendToken(url, token);

    final String response = await _backend.post(url, _json.encode(entry));

    return model.CalendarEntry.fromJson(
        _json.decode(response) as Map<String, dynamic>);

  }

  @override
  Future<model.CalendarEntry> get(int id, model.Owner owner) async {
    Uri url = resource.Calendar.single(host, id, owner);
    url = _appendToken(url, token);

    final String response = await _backend.get(url);

    return model.CalendarEntry.fromJson(
        _json.decode(response) as Map<String, dynamic>);

  }

  @override
  Future<Iterable<model.CalendarEntry>> list(model.Owner owner) async {
    Uri url = resource.Calendar.ownerBase(host, owner);

    url = _appendToken(url, token);

    final List<dynamic> maps =
        _json.decode(await _backend.get(url)) as List<dynamic>;

    return maps
        .map<model.CalendarEntry>((dynamic map)
    => model.CalendarEntry.fromJson(map as Map<String, dynamic>));
  }

  @override
  Future<Null> remove(int eid, model.Owner owner, model.User user) async {
    Uri url = resource.Calendar.single(host, eid, owner);
    url = _appendToken(url, token);

    await _backend.delete(url);
  }

  @override
  Future<model.CalendarEntry> update(
      model.CalendarEntry entry, model.Owner owner, model.User modifier) async {
    Uri url = resource.Calendar.single(host, entry.id, owner);
    url = _appendToken(url, token);

    final String response = await _backend.put(url, _json.encode(entry));

    return model.CalendarEntry.fromJson(
        _json.decode(response) as Map<String, dynamic>);
  }
}
