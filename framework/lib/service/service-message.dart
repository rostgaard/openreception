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

/// Message store client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
class RESTMessageStore implements storage.Message {
  RESTMessageStore(Uri host, String token, dynamic backend)
      : _client = api.MessageApi(api.ApiClient(basePath: host.toString())) {
    _client.apiClient.getAuthentication<api.ApiKeyAuth>('ApiKeyAuth').apiKey =
        token;
  }

  final api.MessageApi _client;

  @override
  Future<model.Message> get(int mid) {
    try {
      return _client.getMessage(mid);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.Message>> getByIds(List<int> ids) async {
    try {
      return _client.getByIds(ids);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  Future<model.MessageQueueEntry> enqueue(model.Message message) {
    try {
      return _client.enqueueMessage(message.id);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  @override
  Future<model.Message> create(
      model.Message message, model.User modifier) async {
    try {
      return _client.createMessage(message);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  @override
  Future<Null> remove(int mid, model.User modifier) async {
    try {
      return _client.deleteMessage(mid);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  @override
  Future<model.Message> update(
      model.Message message, model.User modifier) async {
    try {
      return _client.updateMessage(message.id, message);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  Future<List<model.Message>> list({model.MessageFilter filter}) async {
    try {
      return _client.listByDay(DateTime.now().toIso8601String(), filter);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.Message>> listDay(DateTime day,
      {model.MessageFilter filter}) async {
    try {
      return _client.listByDay(day.toIso8601String(), filter);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.Message>> listDrafts({model.MessageFilter filter}) async {
    try {
      return _client.listDrafts(filter);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.Commit>> changes([int mid]) async {
    try {
      final List<api.Commit> changes = mid != null
          ? (await _client.messageHistories())
          : (await _client.messageHistory(mid));
      return changes;
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }
}
