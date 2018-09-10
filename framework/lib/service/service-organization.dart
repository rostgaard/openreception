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

/// Organization store client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
class RESTOrganizationStore implements storage.Organization {
  final WebService _backend;

  /// The uri of the connected backend.
  final Uri host;

  /// The token used for authenticating with the backed.
  final String token;

  RESTOrganizationStore(Uri this.host, String this.token, this._backend);

  @override
  Future<Iterable<model.BaseContact>> contacts(int oid) async {
    Uri url = resource.Organization.contacts(this.host, oid);
    url = _appendToken(url, this.token);

    final List<dynamic> maps =
        _json.decode(await _backend.get(url)) as List<dynamic>;

    return maps.map((dynamic map) =>
        model.BaseContact.fromJson(map as Map<String, dynamic>));
  }

  @override
  Future<Iterable<model.ReceptionReference>> receptions(int oid) async {
    Uri url = resource.Organization.receptions(host, oid);
    url = _appendToken(url, this.token);

    final List<dynamic> maps =
        _json.decode(await _backend.get(url)) as List<dynamic>;

    return maps.map((dynamic map) =>
        model.ReceptionReference.fromJson(map as Map<String, dynamic>));
  }

  @override
  Future<Map<String, dynamic>> receptionMap() async {
    Uri url = resource.Organization.receptionMap(host);
    url = _appendToken(url, this.token);

    return (await _json.decode(await _backend.get(url)))
        as Map<String, dynamic>;
  }

  @override
  Future<model.Organization> get(int oid) async {
    Uri url = resource.Organization.single(this.host, oid);
    url = _appendToken(url, this.token);

    final String response = await _backend.get(url);

    return model.Organization.fromJson(
        _json.decode(response) as Map<String, dynamic>);
  }

  @override
  Future<model.OrganizationReference> create(
      model.Organization organization, model.User modifier) async {
    Uri url = resource.Organization.root(this.host);
    url = _appendToken(url, this.token);

    final String response =
        await _backend.post(url, _json.encode(organization));

    return model.OrganizationReference.fromJson(
        _json.decode(response) as Map<String, dynamic>);
  }

  @override
  Future<model.OrganizationReference> update(
      model.Organization organization, model.User modifier) async {
    Uri url = resource.Organization.single(this.host, organization.id);
    url = _appendToken(url, this.token);

    final String response = await _backend.put(url, _json.encode(organization));

    return model.OrganizationReference.fromJson(
        _json.decode(response) as Map<String, dynamic>);
  }

  @override
  Future<Null> remove(int organizationID, model.User modifier) async {
    Uri url = resource.Organization.single(this.host, organizationID);
    url = _appendToken(url, this.token);

    await _backend.delete(url);
  }

  @override
  Future<Iterable<model.OrganizationReference>> list() async {
    Uri url = resource.Organization.list(this.host, token: this.token);
    url = _appendToken(url, this.token);

    final List<dynamic> maps =
        _json.decode(await _backend.get(url)) as List<dynamic>;

    return maps.map((dynamic map) =>
        model.OrganizationReference.fromJson(map as Map<String, dynamic>));
  }

  @override
  Future<Iterable<model.Commit>> changes([int oid]) async {
    Uri url = resource.Organization.changeList(host, oid);
    url = _appendToken(url, this.token);

    final List<dynamic> maps =
        _json.decode(await _backend.get(url)) as List<dynamic>;

    return maps.map(
        (dynamic map) => model.Commit.fromJson(map as Map<String, dynamic>));
  }

  Future<String> changelog(int oid) {
    Uri url = resource.Organization.changelog(host, oid);
    url = _appendToken(url, this.token);

    return _backend.get(url);
  }
}
