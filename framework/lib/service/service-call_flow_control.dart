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
  final WebService _backend;

  /// The uri of the connected backend.
  final Uri host;

  /// The token used for authenticating with the backed.
  final String token;

  CallFlowControl(this.host, this.token, this._backend);

  /// Retrives the currently active recordings
  Future<Iterable<model.ActiveRecording>> activeRecordings() {
    Uri uri = resource.CallFlowControl.activeRecordings(host);
    uri = _appendToken(uri, token);

    Iterable<model.ActiveRecording> decodeMaps(
            Iterable<Map<String, dynamic>> maps) =>
        maps.map((Map<String, dynamic> map) =>
            new model.ActiveRecording.fromJson(map));

    return _backend.get(uri).then(_json.decode).then(decodeMaps);
  }

  /// Retrives the currently active recordings
  Future<model.ActiveRecording> activeRecording(String channel) {
    Uri uri = resource.CallFlowControl.activeRecording(host, channel);
    uri = _appendToken(uri, token);

    return _backend.get(uri).then(_json.decode).then(
        (Map<String, dynamic> map) => new model.ActiveRecording.fromJson(map));
  }

  /// Retrives the stats of all agents.
  Future<Iterable<model.AgentStatistics>> agentStats() {
    Uri uri = resource.CallFlowControl.agentStatistics(host);
    uri = _appendToken(uri, token);

    Iterable<model.AgentStatistics> decodeMaps(
            Iterable<Map<String, dynamic>> maps) =>
        maps.map((Map<String, dynamic> map) =>
            new model.AgentStatistics.fromJson(map));

    return _backend.get(uri).then(_json.decode).then(decodeMaps);
  }

  /// Retrives the stats of a single agent.
  Future<model.AgentStatistics> agentStat(int userId) {
    Uri uri = resource.CallFlowControl.agentStatistic(host, userId);
    uri = _appendToken(uri, token);

    return _backend.get(uri).then(_json.decode).then(
        (Map<String, dynamic> map) => new model.AgentStatistics.fromJson(map));
  }

  /// Retrives the current Call list.
  Future<Iterable<model.Call>> callList() {
    Uri uri = resource.CallFlowControl.list(host);
    uri = _appendToken(uri, token);

    return _backend.get(uri).then(_json.decode).then(
        (Iterable<Map<String, dynamic>> callMaps) => callMaps
            .map((Map<String, dynamic> map) => new model.Call.fromJson(map)));
  }

  /// Retrives the a specific channel as a Map.
  Future<Map<String, dynamic>> channelMap(String uuid) {
    Uri uri = resource.CallFlowControl.channel(host, uuid);
    uri = _appendToken(uri, token);

    return _backend.get(uri).then(
        (String response) => (_json.decode(response) as Map<String, dynamic>));
  }

  /// Returns a single call resource.
  Future<model.Call> get(String callID) {
    Uri uri = resource.CallFlowControl.single(host, callID);
    uri = _appendToken(uri, token);

    return _backend
        .get(uri)
        .then(_json.decode)
        .then((Map<String, dynamic> map) => new model.Call.fromJson(map));
  }

  /// Hangs up the call identified by [callID].
  Future<Null> hangup(String callID) async {
    Uri uri = resource.CallFlowControl.hangup(host, callID);
    uri = _appendToken(uri, token);

    await _backend.post(uri, '');
  }

  /// Originate a new call via the server.
  Future<model.Call> originate(
      String extension, model.OriginationContext context) {
    Uri uri = resource.CallFlowControl.originate(host, extension, context);
    uri = _appendToken(uri, token);

    return _backend.post(uri, '').then(_json.decode).then(
        (Map<String, dynamic> callMap) => new model.Call.fromJson(callMap));
  }

  /// Parks the call identified by [callID].
  Future<model.Call> park(String callID) {
    Uri uri = resource.CallFlowControl.park(host, callID);
    uri = _appendToken(uri, token);

    return _backend
        .post(uri, '')
        .then(_json.decode)
        .then((Map<String, dynamic> map) => new model.Call.fromJson(map));
  }

  /// Retrives the current Peer list.
  Future<Iterable<model.Peer>> peerList() {
    Uri uri = resource.CallFlowControl.peerList(host);
    uri = _appendToken(uri, token);

    return _backend
        .get(uri)
        .then((String response) => (_json.decode(response)))
        .then((Iterable<Map<String, dynamic>> maps) => maps
            .map((Map<String, dynamic> map) => new model.Peer.fromJson(map)));
  }

  /// Picks up the call identified by [callID].
  Future<model.Call> pickup(String callID) {
    Uri uri = resource.CallFlowControl.pickup(host, callID);
    uri = _appendToken(uri, token);

    return _backend.post(uri, '').then(_json.decode).then(
        (Map<String, dynamic> callMap) => new model.Call.fromJson(callMap));
  }

  /// Asks the server to perform a reload.
  Future<Null> stateReload() async {
    Uri uri = resource.CallFlowControl.stateReload(host);
    uri = _appendToken(uri, token);

    await _backend.post(uri, '');
  }

  /// Transfers the call identified by [callID] to active call [destination].
  Future<Null> transfer(String callID, String destination) async {
    Uri uri = resource.CallFlowControl.transfer(host, callID, destination);
    uri = _appendToken(uri, token);

    await _backend.post(uri, '');
  }
}
