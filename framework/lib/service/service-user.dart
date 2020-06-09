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
  RESTUserStore(Uri host, String token, dynamic backend)
      : _client = api.UserApi(api.ApiClient(basePath: host.toString())),
        _groupsClient = api.GroupApi(api.ApiClient(basePath: host.toString())) {
    _client.apiClient.getAuthentication<api.ApiKeyAuth>('ApiKeyAuth').apiKey =
        token;
    _groupsClient.apiClient
        .getAuthentication<api.ApiKeyAuth>('ApiKeyAuth')
        .apiKey = token;
  }

  final api.UserApi _client;
  final api.GroupApi _groupsClient;

  @override
  Future<List<model.UserReference>> list() async {
    try {
      return await _client.list();
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  @override
  Future<model.User> get(int userId) async {
    try {
      return model.User.fromJson((await _client.user(userId)).toJson());
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  @override
  Future<model.User> getByIdentity(String identity) async {
    try {
      return model.User.fromJson(
          (await _client.userByIdentity(identity)).toJson());
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  @override
  Future<List<String>> groups() async => _groupsClient.groups();

  @override
  Future<model.UserReference> create(
      model.User user, model.User creator) async {
    try {
      return  await _client.addUser(user);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  @override
  Future<model.UserReference> update(
      model.User user, model.User creator) async {
    try {
      return await _client.updateUser(user.id, user);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  @override
  Future<Null> remove(int userId, model.User creator) async {
    try {
      await _client.deleteUser(userId);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "DELETE", null, e.message);
      throw e;
    }
  }

  /// Returns the [model.UserStatus] object associated with [uid].
  Future<model.UserStatus> userStatus(int uid) async {
    try {
      return await _client.userState(uid);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Updates the [model.UserStatus] object associated with [uid] to
  /// state ready.
  ///
  /// The update is conditioned by the server and phone state and may throw
  /// [ClientError] exeptions.
  Future<model.UserStatus> userStateReady(int uid) async {
    try {
      final model.UserStatus pausedState = model.UserStatus()..paused = false ..userId=  uid;

      return await _client.updateUserStatus(uid, pausedState);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "POST", null, e.message);
      throw e;
    }
  }

  /// Returns an List representation of the all the [model.UserStatus]
  /// objects currently known to the CallFlowControl server.
  Future<List<model.UserStatus>> userStatusList() async {
    try {
      final List<api.UserStatus> users = (await _client.userStates());
      return users;
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Updates the [model.UserStatus] object associated with [uid] to
  /// state paused.
  ///
  /// The update is conditioned by the server and phone state and may throw
  /// [ClientError] exceptions.
  Future<model.UserStatus> userStatePaused(int uid) async {
    try {
      final model.UserStatus pausedState = model.UserStatus()..paused = true..userId= uid;

      return await _client.updateUserStatus(uid, pausedState);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "POST", null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.Commit>> changes([int uid]) async {
    try {
      final List<api.Commit> changes = uid != null
          ? (await _client.userHistories())
          : (await _client.userHistory(uid));
      return changes;
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  Future<String> changelog(int uid) async {
    try {
      return await _client.userChangelog(uid);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

//  Future<model.DailyReport> dailyReport(DateTime day) {
//    throw new UnsupportedError("Currently unsupported");
//  }
//
//  Future<model.DailySummary> dailySummary(DateTime day) async {
//    throw new UnsupportedError("Currently unsupported");
//  }
}
