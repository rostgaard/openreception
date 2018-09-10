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

library ors.controller.pbx;

import 'dart:async';
import 'dart:convert';

import 'package:esl/esl.dart' as esl;
import 'package:logging/logging.dart';
import 'package:orf/model.dart' as model;
import 'package:orf/pbx-keys.dart';
import 'package:ors/configuration.dart';
import 'package:ors/model.dart' as _model;

class PBXException implements Exception {
  const PBXException([this.message = ""]);

  final String message;

  @override
  String toString() => "PBXException: $message";
}

class NoAnswer extends PBXException {
  const NoAnswer([message = ""]);

  @override
  String toString() => "NoAnswer: $message";
}

class CallRejected extends PBXException {
  const CallRejected([message = ""]);

  @override
  String toString() => "CallRejected: $message";
}

class PBX {
  PBX(this.eslClient, this._channelList);

  final Logger _log = Logger('ors.controller.pbx');
  final String _dialplan = 'xml receptions';

  final esl.Connection eslClient;
  final _model.ChannelList _channelList;


  Future<esl.Response> api(String command) async {
    final esl.Response response = await eslClient.api(command);

    final int maxLen = 200;
    final truncated = response.content.length > maxLen
        ? '${response.content.substring(0, maxLen)}...'
        : response.content;

    _log.finest('api $command => $truncated');
    return response;
  }

  Future<esl.Reply> bgapi(String command, {String jobUuid: ''}) async {
    final esl.Reply reply = await eslClient.bgapi(command, jobUuid: jobUuid);
    _log.finest('bgapi $command => ${reply.replyRaw}');
    return reply;
  }

  /// Starts an origination in the PBX.
  ///
  /// By first dialing the agent and then the outbound extension.
  ///
  /// Returns the UUID of the call.
  Future<String> originate(
      String extension, int contactID, int receptionID, model.User user) async {
    /// Tag the A-leg as a primitive origination channel.
    List<String> aLegvariables = ['${ORPbxKey.agentChannel}=true'];

    List<String> bLegvariables = [
      '${ORPbxKey.receptionId}=$receptionID',
      '${ORPbxKey.userId}=${user.id}',
      '${ORPbxKey.contactId}=$contactID'
    ];

    final String callerIdName = config.callFlowControl.callerIdName;
    final String callerIdNumber = config.callFlowControl.callerIdNumber;
    final int timeout = config.callFlowControl.originateTimeout;

    esl.Response response = await api(
        'originate {${aLegvariables.join(',')}}user/${user.extension} '
        '&bridge([${bLegvariables.join(',')}]sofia/external/$extension) '
        '$_dialplan $callerIdName $callerIdNumber $timeout');

    if (!response.isOk) {
      throw StateError('ESL returned ${response.content}');
    }

    return response.channelUUID;
  }

  Future _cleanupChannel(String uuid) =>
      killChannel(uuid).catchError((error, stackTrace) =>
          _log.finest('Failed to close agent channel', error, stackTrace));

  /// Spawns a channel to an agent.
  ///
  /// By first dialing the agent, and parking him/her.
  ///
  /// Returns the UUID of the new channel.
  Future<String> createAgentChannel(model.User user,
      {Map<String, String> extravars: const {}}) async {
    final int msecs = DateTime.now().millisecondsSinceEpoch;
    final String newCallUuid = 'agent-${user.id}-$msecs';
    final String destination = 'user/${user.extension}';

    _log.finest('New uuid: $newCallUuid');
    _log.finest('Dialing receptionist at user/${user.extension}');

    final String callerIdNumber = config.callFlowControl.callerIdNumber;

    Map<String, dynamic> variables = {
      'ignore_early_media': true,
      ORPbxKey.agentChannel: true,
      'park_timeout': config.callFlowControl.agentChantimeOut,
      'hangup_after_bridge': true,
      'origination_uuid': newCallUuid,
      'originate_timeout': config.callFlowControl.agentChantimeOut,
      'origination_caller_id_name': 'Connecting...',
      'origination_caller_id_number': callerIdNumber
    }..addAll(extravars);

    final String variableString =
        variables.keys.map((String key) => '$key=${variables[key]}').join(',');

    /// Create a subscription
    bool jobUuidMatches(esl.Event event) =>
        event.eventName == _model.PBXEvent.backgroundJob &&
        event.fields['Job-UUID'] == newCallUuid;

    final Future<esl.Event> subscription = eslClient.eventStream
        .firstWhere(jobUuidMatches)
        .timeout(
            Duration(seconds: config.callFlowControl.agentChantimeOut + 1));

    await bgapi('originate {$variableString}$destination &park()',
        jobUuid: newCallUuid);

    final esl.Response response = esl.Response.fromPacketBody(
        (await subscription).fields['_body'].trim());

    if (response.isOk) {
      return newCallUuid;
    } else {
      _log.warning('Bad reply from PBX: ${response.status}');

      /// Call is rejected by peer
      if (response.content.contains('CALL_REJECTED')) {
        throw CallRejected('destination: $destination');

        /// Call is not answered by peer.
      } else if (response.content.contains('NO_ANSWER')) {
        throw NoAnswer('destination: $destination');

        /// Call did not succeed for reasons beyond our comprehension.
      } else {
        throw PBXException('Creation of agent channel for '
            'uid:${user.id} failed. Destination:$destination. '
            'PBX responded: ${response.content}');
      }
    }
  }

  /**
   * Spawns a channel to an agent.
   *
   * By first dialing the agent, and parking him/her.
   *
   * Returns the UUID of the channel.
   */
  Future<String> createAgentChannelBg(model.User user) async {
    final int msecs = DateTime.now().millisecondsSinceEpoch;
    final String newCallUuid = 'agent-${user.id}-$msecs';
    final String destination = 'user/${user.extension}';

    _log.finest('New uuid: $newCallUuid');
    _log.finest('Dialing receptionist at user/${user.extension}');

    final String callerIdNumber = config.callFlowControl.callerIdNumber;

    Map<String, dynamic> variables = {
      'ignore_early_media': true,
      ORPbxKey.agentChannel: true,
      'park_timeout': config.callFlowControl.agentChantimeOut,
      'hangup_after_bridge': true,
      'origination_uuid': newCallUuid,
      'originate_timeout': config.callFlowControl.agentChantimeOut,
      'origination_caller_id_name': 'Connecting...',
      'origination_caller_id_number': callerIdNumber
    };

    String variableString =
        variables.keys.map((String key) => '$key=${variables[key]}').join(',');

    esl.Reply reply = await bgapi(
        'originate {$variableString}$destination &park()',
        jobUuid: newCallUuid);

    if (!reply.isOk) {
      throw PBXException('Creation of agent channel for '
          'uid:${user.id} failed. Destination:$destination. '
          'PBX responded: ${reply.replyRaw}');
    }

    /// Create a subscription that looks for the outbound channel.
    bool outboundCallWithUuid(esl.Event event) =>
        event.eventName == 'CHANNEL_ORIGINATE' &&
        event.channel.fields['Unique-ID'] == newCallUuid;

    await eslClient.eventStream
        .firstWhere(outboundCallWithUuid, orElse: () => null);

    bool inviteClosed(esl.Event event) =>
        event.channel.fields['Unique-ID'] == newCallUuid &&
        (event.eventName == 'CHANNEL_ANSWER' ||
            event.eventName == 'CHANNEL_HANGUP');

    esl.Event event;
    try {
      event = await eslClient.eventStream
          .firstWhere(inviteClosed, orElse: () => null)
          .timeout(
              Duration(seconds: config.callFlowControl.agentChantimeOut));
    } on TimeoutException {
      await _cleanupChannel(ORPbxKey.agentChannel);

      throw NoAnswer('destination: $destination');
    }

    if (event.eventName == 'CHANNEL_HANGUP') {
      throw CallRejected('destination: $destination');
    } else if (event.eventName == 'CHANNEL_ANSWER') {
      return newCallUuid;
    } else {
      throw PBXException('Creation of agent channel for '
          'uid:${user.id} failed. Destination:$destination. '
          'Got event type: ${event.eventName}');
    }
  }

  Future transferUUIDToExtension(
      String uuid, String extension, model.User user, String context) async {
    await api('uuid_setvar $uuid effective_caller_id_number ${user.extension}');
    await api('uuid_setvar $uuid effective_caller_id_name ${user.address}');
    final esl.Reply reply = await bgapi(
        'uuid_transfer $uuid external_transfer_$extension xml reception-$context');

    if (!reply.isOk) {
      throw PBXException(reply.replyRaw);
    }
  }

  /// Starts an origination in the PBX.
  ///
  /// By first dialing the agent and then the recordingsmenu.
  Future recordChannel(String uuid, String filename) {
    final String command = 'uuid_record $uuid start $filename';
    return _runAndCheck(command).then((esl.Response response) => filename);
  }

  /// Starts an origination in the PBX.
  ///
  /// By first dialing the agent and then the recordingsmenu.
  Future originateRecording(int receptionID, String recordExtension,
      String soundFilePath, model.User user) {
    List<String> variables = [
      '${ORPbxKey.receptionId}=$receptionID',
      '${ORPbxKey.userId}=${user.id}',
      'recordpath=$soundFilePath'
    ];
    final String callerIdName = config.callFlowControl.callerIdName;
    final String callerIdNumber = config.callFlowControl.callerIdNumber;
    final int timeout = config.callFlowControl.originateTimeout;

    final String command =
        'originate {${variables.join(',')}}user/${user.extension} $recordExtension $_dialplan $callerIdName $callerIdNumber $timeout';
    return api(command).then((esl.Response response) {
      if (!response.isOk) {
        throw StateError('ESL returned ${response.content}');
      }

      return response.channelUUID;
    });
  }

  /// Bridges two active calls.
  Future bridge(model.Call source, model.Call destination) {
    return api('uuid_bridge ${source.id} ${destination.id}')
        .then((esl.Response response) {
      if (!response.isOk) {
        throw StateError('ESL returned ${response.content}');
      }

      return response;
    });
  }

  /// Writes [msg] to log and throws a [PBXException].
  void _logAndFail(String msg) {
    _log.severe(msg);
    throw PBXException(msg);
  }

  /// Run a [command] checked. This implies that the return values is checked
  /// for errors and throw a [PBXException] if that is the case. The command
  /// failure will be logged prior.
  Future<esl.Response> _runAndCheck(String command) async {
    esl.Response response;
    try {
      response = await api(command);
    } catch (error, stackTrace) {
      _log.shout('Failed to send command $command', error, stackTrace);
    }

    if (!response.isOk) {
      _logAndFail('"$command" failed with response ${response.content}');
    }
    return response;
  }

  /**
   *
   */
  Future pickupCall(String agentChannel, String uuid) =>
      api('uuid_transfer $agentChannel pickup-call-$uuid $_dialplan');

  /// Bridges two active calls.
  Future bridgeChannel(String uuid, model.Call destination) async {
    await _runAndCheck('uuid_answer ${destination.channel}');

    try {
      await setVariable(uuid, 'hangup_after_bridge', 'true');
    } catch (e) {
      final String msg = 'Failed to set variable on channel';
      _log.severe(msg);

      throw PBXException(msg);
    }

    final bridgeUuid =
        'uuid_transfer $uuid pickup-call-${destination.channel} $_dialplan';
    esl.Response response = await _runAndCheck(bridgeUuid);

    await api('uuid_break ${destination.channel}');

    return response;
  }

  /// Transfers an active call to a user.
  Future transfer(model.Call source, String extension) async {
    final command = 'uuid_transfer ${source.channel} $extension';

    esl.Response xfrResponse = await api(command);

    await api('uuid_break ${source.channel}');

    if (!xfrResponse.isOk) {
      final String msg =
          '"$command" failed with reponse ${xfrResponse.content}';
      _log.severe(msg);
      throw PBXException(msg);
    }

    return xfrResponse;
  }

  /// Check if the agent channel is still active and if it is, kill it.
  Future _checkAgentChannel(String uuid) =>
      Future.delayed(Duration(milliseconds: 100)).then((_) =>
          _channelList.containsChannel(uuid) ? _cleanupChannel(uuid) : null);

  /// Kills the active channel for a call.
  Future hangup(model.Call call) =>
      killChannel(call.channel).then((_) => _checkAgentChannel(call.bLeg));

  /// Kills the active channel for a call.
  Future killChannel(String uuid) =>
      api('uuid_kill $uuid').then((esl.Response response) {
        if (!response.isOk) {
          throw StateError('ESL returned ${response.content}');
        }
      });

  /// Parks a call in the parking lot for the user.
  Future park(model.Call call, model.User user) {
    return transfer(call, 'park XML receptions');
  }

  /// Loads the peer list from an [esl.Response].
  void _loadPeerListFromPacket(
      esl.Response response, _model.PeerList peerList) {
    final esl.PeerList loadedList =
        esl.PeerList.fromMultilineBuffer(response.content);

    peerList.clear();

    final acceptedPeers = loadedList.where(_model.peerIsInAcceptedContext);

    for (esl.Peer eslPeer in acceptedPeers) {
      final model.Peer peer = model.Peer(eslPeer.id)
        ..registered = eslPeer.registered;
      peerList.add(peer);
    }

    _log.info('Loaded ${peerList.length} of ${loadedList.length} '
        'peers from FreeSWITCH');
  }

  /// Request a reload of peers.
  Future loadPeers(_model.PeerList peerList) async {
    esl.Response response = await api('list_users');

    _loadPeerListFromPacket(response, peerList);
  }

  /// Request a reload of 'channels
  Future loadChannels() =>
      api('show channels as json').then(_loadChannelListFromPacket);

  /// Loads the channel list from an [esl.Response].
  Future _loadChannelListFromPacket(esl.Response response) {
    Map responseBody = json.decode(response.content);
    Iterable<String> channelUUIDs = responseBody.containsKey('rows')
        ? List.from(
            json.decode(response.content)['rows'].map((Map m) => m['uuid']))
        : [];

    return Future.forEach(channelUUIDs, (String channelUUID) {
      return api('uuid_dump $channelUUID json').then((esl.Response response) {
        if (!response.isError) {
          Map<String, dynamic> value =
              json.decode(response.content) as Map<String, dynamic>;

          Map<String, String> fields = {};
          Map<String, dynamic> variables = {};

          value.keys.forEach((String key) {
            if (key.startsWith("variable_")) {
              String keyNoPrefix = (key.split("variable_")[1]);
              variables[keyNoPrefix] = value[key];
            }
            fields[key] = value[key];
          });

          _channelList.update(esl.Channel.assemble(fields, variables));
        } else {
          _log.info('Skipping channel loading. Reason: ${response.content}');
        }
      });
    }).then((_) {
      _log.info('Loaded information about '
          '${_channelList.length} active channels into channel list');
    });
  }

  /// Attach a variable to a channel.
  Future setVariable(String uuid, String identifier, String value) =>
      api('uuid_setvar $uuid $identifier $value');
}
