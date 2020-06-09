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

part of ors.model;

class CallList extends IterableBase<model.Call> {
  CallList(this._pbxController, this._channelList);

  final controller.PBX _pbxController;
  final ChannelList _channelList;

  static final Logger _log = Logger('ors.model.CallList');

  Map<String, model.Call> _map = Map<String, model.Call>();

  @override
  Iterator<model.Call> get iterator => _map.values.iterator;

  Bus<event.Event> _callEvent = Bus<event.Event>();
  Stream<event.Event> get onEvent => _callEvent.stream;

  List toJson() => toList(growable: false);

  bool containsID(String callID) => _map.containsKey(callID);

  void subscribe(Stream<esl.Event> eventStream) {
    eventStream.listen(_handleEvent);
  }

  /// WIP. The main idea of this was that call list was merely a reflection of
  /// the current channel list (which could be reloaded at arbitrary times).
  /// The gain of this would be that no pseudo-state would be present in the
  /// call-flow-control service.
  void subscribeChannelEvents(Stream<ChannelEvent> eventStream) {
    //eventStream.listen(_handleChannelsEvent);
  }

  /// Replaces call list with calls from supplied [Iterable].
  void replaceAllWith(Iterable<model.Call> calls) {
    _map.clear();

    for (model.Call call in calls) {
      _map[call.id] = call;
    }
    _callEvent.fire(event.CallStateReload());
  }

  /// Reload the call list from an Iterable of channels.
  void reloadFromChannels() {
    Map<String, model.Call> calls = {};

    for (esl.Channel channel in _channelList) {
      final int assignedTo = channel.variables.containsKey(ORPbxKey.userId)
          ? int.parse(channel.variables[ORPbxKey.userId])
          : model.noId;

      if (!channel.variables.containsKey(ORPbxKey.agentChannel)) {
        calls[channel.uuid] = model.Call()
          ..channel = channel.uuid
          ..arrivalTime = DateTime.fromMillisecondsSinceEpoch(
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
          ..orRid = channel.variables.containsKey(ORPbxKey.receptionId)
              ? int.parse(channel.variables[ORPbxKey.receptionId])
              : model.noId
          ..orCid = channel.variables.containsKey(ORPbxKey.contactId)
              ? int.parse(channel.variables[ORPbxKey.contactId])
              : model.noId;
      } else {
        _log.info('Ignoring local channel ${channel.uuid}');
      }
    }

    ///Extract the call state.
    calls.values.forEach((model.Call call) {
      if (call.bLeg != null) {
        _log.info('$call is bridged.');
        final esl.Channel aLeg = _channelList.get(call.channel);
        final esl.Channel bLeg = _channelList.get(call.bLeg);

        if (isCall(aLeg) && isCall(bLeg)) {
          call.state = model.CallState.transferred_;
        } else {
          call.state = aLeg.fields['Answer-State'] == 'ringing'
              ? model.CallState.ringing_
              : model.CallState.speaking_;
        }
      } else {
        _log.info('$call is not bridged.');
        final String orState =
            _channelList.get(call.channel).variables[ORPbxKey.state];

        if (orState == 'queued') {
          call.state = model.CallState.queued_;
        } else if (orState == 'parked') {
          call.state = model.CallState.parked_;
        } else if (orState == 'ringing') {
          call.state = model.CallState.ringing_;
        } else {
          _log.severe('state of $call not updated!');
        }
      }
    });

    _map = calls;

    _callEvent.fire(event.CallStateReload());
  }

  List<model.Call> callsOf(int userID) =>
      where((model.Call call) => call.assignedTo == userID).toList();

  model.Call get(String callID) {
    if (_map.containsKey(callID)) {
      return _map[callID];
    } else {
      throw NotFound(callID);
    }
  }

  void update(String callID, model.Call call) {
    if (call.id != callID) {
      throw ArgumentError('call.ID and callID must match!');
    }

    if (_map.containsKey(callID)) {
      _map[callID] = call;
    } else {
      throw NotFound(callID);
    }
  }

  void remove(String callID) {
    if (_map.containsKey(callID)) {
      _map.remove(callID);
    } else {
      throw NotFound(callID);
    }
  }

  model.Call requestCall(model.User user) => firstWhere(
      (model.Call call) => call.assignedTo == model.noId && !call.locked,
      orElse: () => throw NotFound("No calls available"));

  model.Call requestSpecificCall(String callID, model.User user) {
    model.Call call = get(callID);

    if (![user.id, model.noId].contains(call.assignedTo)) {
      _log.fine('Call $callID already assigned to uid: ${call.assignedTo}');
      throw Forbidden(callID);
    } else if (call.locked) {
      if (call.assignedTo == user.id) {
        _log.fine('Call $callID locked, but assigned. Unlocking.');
        call.locked = false;
      } else {
        _log.fine('Uid ${user.id} requested locked call $callID');
        throw Conflict(callID);
      }
    }

    return call;
  }

  /// Determine if a channel ID is a call-channel and not an agent channel.
  bool isCall(esl.Channel channel) => containsID(channel.uuid);

  /// Handle CHANNEL_BRIDGE event packets.
  void _handleBridge(esl.Event e) {
    final esl.Channel uuid = _channelList.get(e.fields['Unique-ID']);
    final esl.Channel otherLeg =
        _channelList.get(e.fields['Other-Leg-Unique-ID']);

    _log.finest('Bridging channel ${uuid.uuid} and channel ${otherLeg.uuid}');

    if (isCall(uuid) && isCall(otherLeg)) {
      _log.finest(
          'Channel ${uuid.uuid} and channel ${otherLeg.uuid} are both calls');
      get(uuid.uuid)..bLeg = otherLeg.uuid;
      get(otherLeg.uuid)..bLeg = uuid.uuid;

      changeState(get(uuid.uuid), model.CallState.transferred_);
      changeState(get(otherLeg.uuid), model.CallState.transferred_);
    } else if (isCall(uuid)) {
      model.Call call = get(uuid.uuid);
      _log.finest('Channel ${uuid.uuid} is a call');

      changeState(call..bLeg = otherLeg.uuid, model.CallState.speaking_);

      _startRecording(call);
    } else if (isCall(otherLeg)) {
      model.Call call = get(otherLeg.uuid);
      _log.finest('Channel ${otherLeg.uuid} is a call');
      changeState(call..bLeg = uuid.uuid, model.CallState.speaking_);

      _startRecording(call);
    }

    // Local calls??
    else {
      _log.severe('Local calls are not supported!');
    }
  }

  void _handleChannelDestroy(esl.Event e) {
    if (containsID(e.uniqueID)) {
      final model.Call call = get(e.uniqueID);
      final hangupCause =
          e.fields['Hangup-Cause'] != null ? e.fields['Hangup-Cause'] : '';
      _callEvent.fire(event.CallHangup(call, hangupCause: hangupCause));

      _log.finest('Hanging up ${e.uniqueID}');
      remove(e.uniqueID);
    }
  }

  void _handleCustom(esl.Event e) {
    switch (e.eventSubclass) {

      /// Call is created
      case (ORPbxKey.callNotify):
        _createCall(e);

        changeState(
            get(e.uniqueID)
              ..orRid = e.fields.containsKey('variable_${ORPbxKey.receptionId}')
                  ? int.parse(e.fields['variable_${ORPbxKey.receptionId}'])
                  : 0,
            model.CallState.created_);

        break;

      case (ORPbxKey.ringingStart):
        changeState(get(e.uniqueID),model.CallState.ringing_);
        break;

      case (ORPbxKey.ringingStop):
        changeState(get(e.uniqueID),model.CallState.transferring_);
        break;

      case (ORPbxKey.callLock):
        if (_map.containsKey(e.uniqueID)) {
          //ESL.Channel channel = ESL.Channel.fromPacket(event);
          final int assignedTo = get(e.uniqueID).assignedTo;

          if (assignedTo == model.noId) {
            _log.finest('Locking ${e.uniqueID}');
            get(e.uniqueID).locked = true;
          } else {
            _log.finest('Skipping locking of assigned call ${e.uniqueID}');
          }
        } else {
          _log.severe('Locked non-announced call ${e.uniqueID}');
        }
        break;

      case (ORPbxKey.callUnlock):
        if (_map.containsKey(e.uniqueID)) {
          _log.finest('Unlocking ${e.uniqueID}');
          get(e.uniqueID).locked = false;
        } else {
          _log.severe('Locked non-announced call ${e.uniqueID}');
        }
        break;

      /// Entering the wait queue (Playing queue music)
      case (ORPbxKey.waitQueueEnter):
        changeState(get(e.uniqueID)
          ..greetingPlayed = true,model.CallState.queued_);
        break;

      /// Call is parked
      case (ORPbxKey.parkingLotEnter):
        changeState(get(e.uniqueID)
          ..bLeg = null,model.CallState.parked_);
        break;

      /// Call is unparked
      case (ORPbxKey.parkingLotLeave):
        changeState(get(e.uniqueID),model.CallState.transferring_);
        break;
    }
  }

  void _handleEvent(esl.Event e) {
    void dispatch() {
      switch (e.eventName) {
        case (PBXEvent.channelBridge):
          _handleBridge(e);
          break;

        case (PBXEvent.channelDestroy):
          _handleChannelDestroy(e);
          break;

        case (PBXEvent.custom):
          _handleCustom(e);
          break;
      }
    }

    try {
      dispatch();
    } catch (error, stackTrace) {
      _log.severe('Failed to dispatch event ${e.eventName}');
      _log.severe(error, stackTrace);
    }
  }

  model.Call createCall(esl.Event e) {
    _createCall(e);
    return get(e.uniqueID);
  }

  /// Some notes on call creation;
  ///
  /// We are using the PBX to spawn (originate channels) to the user phones
  /// to establish a connection which we can then use to dial out or transfer
  /// uuid's to.
  /// These will, in their good right, spawn CHANNEL_ORIGINATE events which we
  /// manually need to filter :-\
  /// For now, the filter for origination is done by tagging the channels with a
  /// variable (`agentChan`) by the origination request.
  /// This is picked up by this function which then filters the channels from the
  /// call list.
  /// Upon call transfer, we also create a channel, but cannot (easily) tag the
  /// channels, so we merely filter based upon whether or not they have a
  /// [Other-Leg-Username] key in the map. This is probably over-simplifying things
  /// and may be troublesome when throwing around local calls. This has yet to be
  /// tested, however.
  void _createCall(esl.Event e) {
    /// Skip local channels
    if (e.fields.containsKey('variable_${ORPbxKey.agentChannel}')) {
      _log.finest('Skipping origination channel ${e.uniqueID}');
      return;
    }

    if (e.fields.containsKey('Other-Leg-Username')) {
      _log.finest('Skipping transfer channel ${e.uniqueID}');
      return;
    }

    _log.finest('Creating new call ${e.uniqueID}');

    int contactID = e.fields.containsKey('variable_${ORPbxKey.contactId}')
        ? int.parse(e.fields['variable_${ORPbxKey.contactId}'])
        : model.noId;

    int receptionID = e.fields.containsKey('variable_${ORPbxKey.receptionId}')
        ? int.parse(e.fields['variable_${ORPbxKey.receptionId}'])
        : model.noId;

    int userID = e.fields.containsKey('variable_${ORPbxKey.userId}')
        ? int.parse(e.fields['variable_${ORPbxKey.userId}'])
        : model.noId;

    final esl.Channel channel = esl.Channel.fromEvent(e);

    model.Call createdCall = model.Call()
      ..id = e.uniqueID
      ..arrivalTime = DateTime.fromMillisecondsSinceEpoch(
          int.parse(e.fields['Caller-Channel-Created-Time']) ~/ 1000)
      ..inbound = (e.fields['Call-Direction'] == 'inbound' ? true : false)
      ..callerId = e.fields['Caller-Caller-ID-Number']
      ..destination = channel.variables[ORPbxKey.destination]
      ..orRid = receptionID
      ..orCid = contactID
      ..assignedTo = userID;

    _map[e.uniqueID] = createdCall;
  }

  Future _startRecording(model.Call call) async {
    if (!config.callFlowControl.enableRecordings) {
      return 0;
    }

    final Iterable parts = [
      call.bLeg,
      call.id,
      call.orRid,
      call.inbound ? 'in_${call.callerId}' : 'out_${call.destination}'
    ];

    final filename = '${config.callFlowControl.recordingsDir}/'
        '${parts.join('_')}.wav';

    return _pbxController
        .recordChannel(call.bLeg, filename)
        .then((_) => _log.fine('Started recording call ${call.id} '
            '(agent channel: ${call.bLeg})  to file $filename'))
        .catchError((error, stackTrace) => _log.severe(
            'Could not start recording of '
            'call ${call.id} to file $filename',
            error,
            stackTrace));
  }

  /// Change the state of the [model.Call] object to [newState].
  void changeState(model.Call call, model.CallState newState) {
    final model.CallState lastState = call.state;

    call.state = newState;

    _log.finest('UUID: ${call.id}: $lastState => $newState');

    if (lastState == model.CallState.queued_) {
      _callEvent.fire(event.QueueLeave(call));
    } else if (lastState == model.CallState.parked_) {
      _callEvent.fire(event.CallUnpark(call));
    }

    switch (newState) {
      case (model.CallState.created_):
        _callEvent.fire(event.CallOffer(call));
        break;

      case (model.CallState.parked_):
        _callEvent.fire(event.CallPark(call));
        break;

      case (model.CallState.unparked_):
        _callEvent.fire(event.CallUnpark(call));
        break;

      case (model.CallState.queued_):
        _callEvent.fire(event.QueueJoin(call));
        break;

      case (model.CallState.speaking_):
        _callEvent.fire(event.CallPickup(call));
        break;

      case (model.CallState.transferred_):
        _callEvent.fire(event.CallTransfer(call));
        break;

      case (model.CallState.ringing_):
        _callEvent.fire(event.CallStateChanged(call));
        break;

      case (model.CallState.transferring_):
        break;

      default:
        _log.severe('Changing call ${call} to Unkown state!');
        break;
    }
  }
}
