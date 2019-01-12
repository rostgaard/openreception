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

/// User store client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
class RESTUserStore implements storage.User {
  final WebService _backend;

  /// The uri of the connected backend.
  final Uri host;

  /// The token used for authenticating with the backed.
  final String token;

  RESTUserStore(Uri this.host, String this.token, this._backend);

  @override
  Future<Iterable<model.UserReference>> list() {
    Uri url = resource.User.list(host);
    url = _appendToken(url, this.token);

    return this
        ._backend
        .get(url)
        .then((String reponse) => _json.decode(reponse))
        .then((Iterable<Map<String, dynamic>> userMaps) => userMaps.map(
            (Map<String, dynamic> map) =>
                new model.UserReference.fromJson(map)));
  }

  @override
  Future<model.User> get(int userId) {
    Uri url = resource.User.single(host, userId);
    url = _appendToken(url, this.token);

    return this
        ._backend
        .get(url)
        .then((String reponse) => _json.decode(reponse))
        .then(((Map<String, dynamic> userMap) =>
            new model.User.fromJson(userMap)));
  }

  @override
  Future<model.User> getByIdentity(String identity) {
    Uri url = resource.User.singleByIdentity(host, identity);
    url = _appendToken(url, this.token);

    return _backend.get(url).then(_json.decode).then(
        ((Map<String, dynamic> userMap) => new model.User.fromJson(userMap)));
  }

  @override
  Future<Iterable<String>> groups() {
    Uri url = resource.User.group(host);
    url = _appendToken(url, this.token);

    return this
        ._backend
        .get(url)
        .then((String reponse) => _json.decode(reponse) as Iterable<String>);
  }

  @override
  Future<model.UserReference> create(model.User user, model.User creator) {
    Uri url = resource.User.root(host);
    url = _appendToken(url, this.token);

    return this
        ._backend
        .post(url, _json.encode(user))
        .then((String reponse) => _json.decode(reponse))
        .then(((Map<String, dynamic> map) =>
            new model.UserReference.fromJson(map)));
  }

  @override
  Future<model.UserReference> update(model.User user, model.User creator) {
    Uri url = resource.User.single(host, user.id);
    url = _appendToken(url, this.token);

    return this
        ._backend
        .put(url, _json.encode(user))
        .then((String reponse) => _json.decode(reponse))
        .then(((Map<String, dynamic> map) =>
            new model.UserReference.fromJson(map)));
  }

  @override
  Future<Null> remove(int userId, model.User creator) async {
    Uri url = resource.User.single(host, userId);
    url = _appendToken(url, this.token);

    await _backend.delete(url);
  }

  /// Returns the [model.UserStatus] object associated with [uid].
  Future<model.UserStatus> userStatus(int uid) {
    Uri uri = resource.User.userState(host, uid);
    uri = _appendToken(uri, token);

    return _backend
        .get(uri)
        .then(_json.decode)
        .then((Map<String, dynamic> map) => new model.UserStatus.fromJson(map));
  }

  /// Updates the [model.UserStatus] object associated with [uid] to
  /// state ready.
  ///
  /// The update is conditioned by the server and phone state and may throw
  /// [ClientError] exeptions.
  Future<model.UserStatus> userStateReady(int uid) {
    Uri uri = resource.User.setUserState(host, uid, model.UserState.ready);
    uri = _appendToken(uri, token);

    return _backend
        .post(uri, '')
        .then(_json.decode)
        .then((Map<String, dynamic> map) => new model.UserStatus.fromJson(map));
  }

  /// Returns an Iterable representation of the all the [model.UserStatus]
  /// objects currently known to the CallFlowControl server.
  Future<Iterable<model.UserStatus>> userStatusList() {
    Uri uri = resource.User.userStateAll(host);
    uri = _appendToken(uri, token);

    return _backend.get(uri).then(_json.decode).then(
        (Iterable<Map<String, dynamic>> maps) => maps.map(
            (Map<String, dynamic> map) => new model.UserStatus.fromJson(map)));
  }

  /// Updates the [model.UserStatus] object associated with [userId] to
  /// state paused.
  ///
  /// The update is conditioned by the server and phone state and may throw
  /// [ClientError] exeptions.
  Future<model.UserStatus> userStatePaused(int userId) {
    Uri uri = resource.User.setUserState(host, userId, model.UserState.paused);
    uri = _appendToken(uri, token);

    return _backend
        .post(uri, '')
        .then(_json.decode)
        .then((Map<String, dynamic> map) => new model.UserStatus.fromJson(map));
  }

  @override
  Future<Iterable<model.Commit>> changes([int uid]) {
    Uri url = resource.User.change(host, uid);
    url = _appendToken(url, this.token);

    Iterable<model.Commit> convertMaps(Iterable<Map<String, dynamic>> maps) =>
        maps.map((Map<String, dynamic> map) => new model.Commit.fromJson(map));

    return this._backend.get(url).then(_json.decode).then(convertMaps);
  }

  Future<String> changelog(int uid) {
    Uri url = resource.User.changelog(host, uid);
    url = _appendToken(url, this.token);

    return _backend.get(url);
  }

  Future<model.DailyReport> dailyReport(DateTime day) {
    Uri url = resource.User.dailyReport(host, day);
    url = _appendToken(url, this.token);

    return _backend
        .get(url)
        .then((String reponse) => _json.decode(reponse))
        .then(((Map<String, dynamic> userMap) =>
            new model.DailyReport.fromJson(userMap)));
  }

  Future<model.DailySummary> dailySummary(DateTime day) async {
    Uri url = resource.User.dailySummary(host, day);
    url = _appendToken(url, this.token);

    final Map<String,Object> response = _json.decode(await _backend.get(url));
    return new model.DailySummary.fromJson(response);
  }
}
