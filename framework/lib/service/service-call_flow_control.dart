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

/// Call-flow-control service client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
class CallFlowControl {
  CallFlowControl(Uri host, String token, dynamic backend)
      : _client = api.CallApi(api.ApiClient(basePath: host.toString())) {
    _client.apiClient.getAuthentication<api.ApiKeyAuth>('ApiKeyAuth').apiKey =
        token;
  }

  final api.CallApi _client;

  /// Retrieves the currently active recordings
  Future<List<model.ActiveRecording>> activeRecordings() async {
    try {
      return _client.listActiveRecordings();
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Retrieves the currently active recordings
  Future<model.ActiveRecording> activeRecording(String channel) async {
    try {
      return _client.getActiveRecording(channel);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Retrives the stats of all agents.
  Future<List<model.AgentStatistics>> agentStats() async {
    try {
      return _client.listAgentStatistics();
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Retrives the stats of a single agent.
  Future<model.AgentStatistics> agentStat(int uid) async {
    try {
      return _client.getAgentStatistics(uid);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Retrives the current Call list.
  Future<List<model.Call>> callList() async {
    try {
      return _client.listCalls();
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Returns a single call resource.
  Future<model.Call> get(String callId) async {
    try {
      return _client.getCall(callId);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Hangs up the call identified by [callID].
  Future<Null> hangup(String callID) async {
    try {
      return _client.hangupCall(callID);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Originate a call via the server.
  Future<model.Call> originate(
      String extension, model.OriginationContext context) async {
    try {
      return _client.originateCall(model.OriginationRequest()
        ..extension_
        ..context = context);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Parks the call identified by [callID].
  Future<model.Call> park(String callID) async {
    try {
      return _client.parkCall(callID);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Retrieves the current Peer list.
  Future<List<model.Peer>> peerList() async {
    try {
      return _client.listPeers();
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Picks up the call identified by [callID].
  Future<model.Call> pickup(String callID) async {
    try {
      return _client.pickupCall(callID);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Asks the server to perform a reload.
  Future<Null> stateReload() async {
    try {
      return _client.reloadCallState();
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// Transfers the call identified by [callID] to active call [destination].
  Future<api.Call> transfer(String callID, String destination) async {
    try {
      return _client.transferCall(
          callID, api.CallTransferRequest()..destination = destination);
    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }
}
