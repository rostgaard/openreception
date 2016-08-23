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

part of openreception.call_flow_control_server.model;

class CallList extends IterableBase<ORModel.Call> {
  static final Logger log = new Logger('${libraryName}.CallList');

  Map<String, ORModel.Call> _map = new Map<String, ORModel.Call>();

  Iterator<ORModel.Call> get iterator => this._map.values.iterator;

  Bus<OREvent.Event> _callEvent = new Bus<OREvent.Event>();
  Stream<OREvent.Event> get onEvent => this._callEvent.stream;

  static CallList instance = new CallList();

  List toJson() => this.toList(growable: false);

  bool containsID(String callID) => this._map.containsKey(callID);

  void subscribe(Stream<ESL.Event> eventStream) {
    eventStream.listen(_handleEvent);
  }

  /**
   * WIP. The main idea of this was that call list was merely a reflection of
   * the current channel list (which could be reloaded at arbitrary times).
   * The gain of this would be that no pseudo-state would be present in the
   * call-flow-control service.
   */
  void subscribeChannelEvents(Stream<ChannelEvent> eventStream) {
    //eventStream.listen(_handleChannelsEvent);
  }

  /**
   * Reload the call list from an Iterable of channels.
   */
  void reloadFromChannels(Iterable<ESL.Channel> channels) {
    Map<String, ORModel.Call> calls = {};

    channels.forEach((ESL.Channel channel) {
      final int assignedTo = channel.variables.containsKey(ORPbxKey.userId)
          ? int.parse(channel.variables[ORPbxKey.userId])
          : ORModel.User.noId;

      if (!channel.variables.containsKey(ORPbxKey.agentChannel)) {
        calls[channel.uuid] = new ORModel.Call.empty(channel.uuid)
          ..arrived = new DateTime.fromMillisecondsSinceEpoch(
              int.parse(channel.fields['Caller-Channel-Created-Time']) ~/ 1000)
          ..assignedTo = assignedTo
          ..bLeg = channel.fields['Other-Leg-Unique-ID']
          ..greetingPlayed =
              channel.variables.containsKey(ORPbxKey.greetingPlayed)
                  ? channel.variables[ORPbxKey.greetingPlayed] == 'true'
                  : false
          ..locked = false
          ..inbound =
              (channel.fields['Call-Direction'] == 'inbound' ? true : false)
          ..callerId =
              channel.fields.containsKey('Caller-Orig-Caller-ID-Number')
                  ? channel.fields['Caller-Orig-Caller-ID-Number']
                  : channel.fields['Caller-Caller-ID-Number']
          ..destination = channel.variables[ORPbxKey.destination]
          ..rid = channel.variables.containsKey(ORPbxKey.receptionId)
              ? int.parse(channel.variables[ORPbxKey.receptionId])
              : ORModel.Reception.noId
          ..cid = channel.variables.containsKey(ORPbxKey.contactId)
              ? int.parse(channel.variables[ORPbxKey.contactId])
              : ORModel.BaseContact.noId
          ..event.listen(this._callEvent.fire);
      } else {
        log.info('Ignoring local channel ${channel.uuid}');
      }
    });

    ///Extract the call state.
    calls.values.forEach((ORModel.Call call) {
      if (call.bLeg != null) {
        log.info('$call is bridged.');
        final ESL.Channel aLeg = ChannelList.instance.get(call.channel);
        final ESL.Channel bLeg = ChannelList.instance.get(call.bLeg);

        if (isCall(aLeg) && isCall(bLeg)) {
          call.state = ORModel.CallState.transferred;
        } else {
          call.state = aLeg.fields['Answer-State'] == 'ringing'
              ? ORModel.CallState.ringing
              : ORModel.CallState.speaking;
        }
      } else {
        log.info('$call is not bridged.');
        final String orState =
            ChannelList.instance.get(call.channel).variables[ORPbxKey.state];

        if (orState == 'queued') {
          call.state = ORModel.CallState.queued;
        } else if (orState == 'parked') {
          call.state = ORModel.CallState.parked;
        } else if (orState == 'ringing') {
          call.state = ORModel.CallState.ringing;
        } else {
          log.severe('state of $call not updated!');
        }
      }
    });

    this._map = calls;

    this._callEvent.fire(new OREvent.CallStateReload());
  }

  List<ORModel.Call> callsOf(int userID) =>
      this.where((ORModel.Call call) => call.assignedTo == userID).toList();

  ORModel.Call get(String callID) {
    if (this._map.containsKey(callID)) {
      return this._map[callID];
    } else {
      throw new NotFound(callID);
    }
  }

  void update(String callID, ORModel.Call call) {
    if (call.id != callID) {
      throw new ArgumentError('call.ID and callID must match!');
    }

    if (_map.containsKey(callID)) {
      _map[callID] = call;
    } else {
      throw new NotFound(callID);
    }
  }

  void remove(String callID) {
    if (this._map.containsKey(callID)) {
      this._map.remove(callID);
    } else {
      throw new NotFound(callID);
    }
  }

  ORModel.Call requestCall(user) =>
      //TODO: Implement a real algorithm for selecting calls.
      this.firstWhere(
          (ORModel.Call call) =>
              call.assignedTo == ORModel.User.noId && !call.locked,
          orElse: () => throw new NotFound("No calls available"));

  ORModel.Call requestSpecificCall(String callID, ORModel.User user) {
    ORModel.Call call = this.get(callID);

    if (![user.id, ORModel.User.noId].contains(call.assignedTo)) {
      log.fine('Call ${callID} already assigned to uid: ${call.assignedTo}');
      throw new Forbidden(callID);
    } else if (call.locked) {
      if (call.assignedTo == user.id) {
        log.fine('Call $callID locked, but assigned. Unlocking.');
        call.locked = false;
      } else {
        log.fine('Uid ${user.id} requested locked call $callID');
        throw new Conflict(callID);
      }
    }

    return call;
  }

  /**
   * Determine if a channel ID is a call-channel and not an agent channel.
   */
  bool isCall(ESL.Channel channel) => this.containsID(channel.uuid);

  /**
   * Handle CHANNEL_BRIDGE event packets.
   */
  void _handleBridge(ESL.Event event) {
    final ESL.Channel uuid =
        ChannelList.instance.get(event.fields['Unique-ID']);
    final ESL.Channel otherLeg =
        ChannelList.instance.get(event.fields['Other-Leg-Unique-ID']);

    log.finest('Bridging channel ${uuid.uuid} and channel ${otherLeg.uuid}');

    if (isCall(uuid) && isCall(otherLeg)) {
      log.finest(
          'Channel ${uuid.uuid} and channel ${otherLeg.uuid} are both calls');
      CallList.instance.get(uuid.uuid)..bLeg = otherLeg.uuid;
      CallList.instance.get(otherLeg.uuid)..bLeg = uuid.uuid;

      CallList.instance
          .get(uuid.uuid)
          .changeState(ORModel.CallState.transferred);
      CallList.instance
          .get(otherLeg.uuid)
          .changeState(ORModel.CallState.transferred);
    } else if (isCall(uuid)) {
      ORModel.Call call = CallList.instance.get(uuid.uuid);
      log.finest('Channel ${uuid.uuid} is a call');

      call
        ..bLeg = otherLeg.uuid
        ..changeState(ORModel.CallState.speaking);

      _startRecording(call);
    } else if (isCall(otherLeg)) {
      ORModel.Call call = CallList.instance.get(otherLeg.uuid);
      log.finest('Channel ${otherLeg.uuid} is a call');
      call
        ..bLeg = uuid.uuid
        ..changeState(ORModel.CallState.speaking);

      _startRecording(call);
    }

    // Local calls??
    else {
      log.severe('Local calls are not supported!');
    }
  }

  void _handleChannelDestroy(ESL.Event event) {
    if (this.containsID(event.uniqueID)) {
      final ORModel.Call call = this.get(event.uniqueID);
      call.hangupCause = event.fields['Hangup-Cause'] != null
          ? event.fields['Hangup-Cause']
          : '';
      call.changeState(ORModel.CallState.hungup);
      log.finest('Hanging up ${event.uniqueID}');
      this.remove(event.uniqueID);
    }
  }

  void _handleCustom(ESL.Event event) {
    switch (event.eventSubclass) {

      /// Call is created
      case (ORPbxKey.callNotify):
        this._createCall(event);

        this.get(event.uniqueID)
          ..rid = event.fields.containsKey('variable_${ORPbxKey.receptionId}')
              ? int.parse(event.fields['variable_${ORPbxKey.receptionId}'])
              : 0
          ..changeState(ORModel.CallState.created);

        break;

      case (ORPbxKey.ringingStart):
        this.get(event.uniqueID).changeState(ORModel.CallState.ringing);
        break;

      case (ORPbxKey.ringingStop):
        this.get(event.uniqueID).changeState(ORModel.CallState.transferring);
        break;

      case (ORPbxKey.callLock):
        if (_map.containsKey(event.uniqueID)) {
          //ESL.Channel channel = new ESL.Channel.fromPacket(event);
          final int assignedTo = get(event.uniqueID).assignedTo;

          if (assignedTo == ORModel.User.noId) {
            log.finest('Locking ${event.uniqueID}');
            CallList.instance.get(event.uniqueID).locked = true;
          } else {
            log.finest('Skipping locking of assigned call ${event.uniqueID}');
          }
        } else {
          log.severe('Locked non-announced call ${event.uniqueID}');
        }
        break;

      case (ORPbxKey.callUnlock):
        if (this._map.containsKey(event.uniqueID)) {
          log.finest('Unlocking ${event.uniqueID}');
          CallList.instance.get(event.uniqueID).locked = false;
        } else {
          log.severe('Locked non-announced call ${event.uniqueID}');
        }
        break;

      /// Entering the wait queue (Playing queue music)
      case (ORPbxKey.waitQueueEnter):
        CallList.instance.get(event.uniqueID)
          ..greetingPlayed =
              true //TODO: Change this into a packet.variable.get ('greetingPlayed')
          ..changeState(ORModel.CallState.queued);
        break;

      /// Call is parked
      case (ORPbxKey.parkingLotEnter):
        CallList.instance.get(event.uniqueID)
          ..bLeg = null
          ..changeState(ORModel.CallState.parked);
        break;

      /// Call is unparked
      case (ORPbxKey.parkingLotLeave):
        CallList.instance.get(event.uniqueID)
          ..changeState(ORModel.CallState.transferring);
        break;
    }
  }

  void _handleEvent(ESL.Event event) {
    void dispatch() {
      switch (event.eventName) {
        case (PBXEvent.channelBridge):
          this._handleBridge(event);
          break;

        case (PBXEvent.channelDestroy):
          this._handleChannelDestroy(event);
          break;

        case (PBXEvent.custom):
          this._handleCustom(event);
          break;
      }
    }

    try {
      dispatch();
    } catch (error, stackTrace) {
      log.severe('Failed to dispatch event ${event.eventName}');
      log.severe(error, stackTrace);
    }
  }

  ORModel.Call createCall(ESL.Event event) {
    _createCall(event);
    return get(event.uniqueID);
  }

  /**
   * Some notes on call creation;
   *
   * We are using the PBX to spawn (originate channels) to the user phones
   * to establish a connection which we can then use to dial out or transfer
   * uuid's to.
   * These will, in their good right, spawn CHANNEL_ORIGINATE events which we
   * manually need to filter :-\
   * For now, the filter for origination is done by tagging the channels with a
   * variable ([agentChan]) by the origination request.
   * This is picked up by this function which then filters the channels from the
   * call list.
   * Upon call transfer, we also create a channel, but cannot (easily) tag the
   * channels, so we merely filter based upon whether or not they have a
   * [Other-Leg-Username] key in the map. This is probably over-simplifying things
   * and may be troublesome when throwing around local calls. This has yet to be
   * tested, however.
   */
  void _createCall(ESL.Event event) {
    /// Skip local channels
    if (event.fields.containsKey('variable_${ORPbxKey.agentChannel}')) {
      log.finest('Skipping origination channel ${event.uniqueID}');
      return;
    }

    if (event.fields.containsKey('Other-Leg-Username')) {
      log.finest('Skipping transfer channel ${event.uniqueID}');
      return;
    }

    log.finest('Creating new call ${event.uniqueID}');

    int contactID = event.fields.containsKey('variable_${ORPbxKey.contactId}')
        ? int.parse(event.fields['variable_${ORPbxKey.contactId}'])
        : ORModel.BaseContact.noId;

    int receptionID =
        event.fields.containsKey('variable_${ORPbxKey.receptionId}')
            ? int.parse(event.fields['variable_${ORPbxKey.receptionId}'])
            : ORModel.Reception.noId;

    int userID = event.fields.containsKey('variable_${ORPbxKey.userId}')
        ? int.parse(event.fields['variable_${ORPbxKey.userId}'])
        : ORModel.User.noId;

    final ESL.Channel channel = new ESL.Channel.fromEvent(event);

    ORModel.Call createdCall = new ORModel.Call.empty(event.uniqueID)
      ..arrived = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(event.fields['Caller-Channel-Created-Time']) ~/ 1000)
      ..inbound = (event.fields['Call-Direction'] == 'inbound' ? true : false)
      ..callerId = event.fields['Caller-Caller-ID-Number']
      ..destination = channel.variables[ORPbxKey.destination]
      ..rid = receptionID
      ..cid = contactID
      ..assignedTo = userID
      ..event.listen(this._callEvent.fire);

    this._map[event.uniqueID] = createdCall;
  }
}

Future _startRecording(ORModel.Call call) async {
  if (!config.callFlowControl.enableRecordings) {
    return 0;
  }

  final Iterable parts = [
    call.bLeg,
    call.id,
    call.rid,
    call.inbound ? 'in_${call.callerId}' : 'out_${call.destination}'
  ];

  final filename = '${config.callFlowControl.recordingsDir}/'
      '${parts.join('_')}.wav';

  return Controller.PBX
      .recordChannel(call.bLeg, filename)
      .then((_) => log.fine('Started recording call ${call.id} '
          '(agent channel: ${call.bLeg})  to file $filename'))
      .catchError((error, stackTrace) => log.severe(
          'Could not start recording of '
          'call ${call.id} to file $filename',
          error,
          stackTrace));
}
