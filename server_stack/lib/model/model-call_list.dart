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

  static final Logger log = new Logger('ors.model.CallList');

  Map<String, model.Call> _map = new Map<String, model.Call>();

  @override
  Iterator<model.Call> get iterator => this._map.values.iterator;

  Bus<event.Event> _callEvent = new Bus<event.Event>();
  Stream<event.Event> get onEvent => this._callEvent.stream;

  List toJson() => this.toList(growable: false);

  bool containsID(String callID) => this._map.containsKey(callID);

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
    _callEvent.fire(new event.CallStateReload());
  }

  /// Reload the call list from an Iterable of channels.
  void reloadFromChannels() {
    Map<String, model.Call> calls = {};

    for (esl.Channel channel in _channelList) {
      final int assignedTo = channel.variables.containsKey(ORPbxKey.userId)
          ? int.parse(channel.variables[ORPbxKey.userId])
          : model.User.noId;

      if (!channel.variables.containsKey(ORPbxKey.agentChannel)) {
        calls[channel.uuid] = new model.Call.empty(channel.uuid)
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
              : model.Reception.noId
          ..cid = channel.variables.containsKey(ORPbxKey.contactId)
              ? int.parse(channel.variables[ORPbxKey.contactId])
              : model.BaseContact.noId
          ..event.listen(this._callEvent.fire);
      } else {
        log.info('Ignoring local channel ${channel.uuid}');
      }
    }

    ///Extract the call state.
    calls.values.forEach((model.Call call) {
      if (call.bLeg != null) {
        log.info('$call is bridged.');
        final esl.Channel aLeg = _channelList.get(call.channel);
        final esl.Channel bLeg = _channelList.get(call.bLeg);

        if (isCall(aLeg) && isCall(bLeg)) {
          call.state = model.CallState.transferred;
        } else {
          call.state = aLeg.fields['Answer-State'] == 'ringing'
              ? model.CallState.ringing
              : model.CallState.speaking;
        }
      } else {
        log.info('$call is not bridged.');
        final String orState =
            _channelList.get(call.channel).variables[ORPbxKey.state];

        if (orState == 'queued') {
          call.state = model.CallState.queued;
        } else if (orState == 'parked') {
          call.state = model.CallState.parked;
        } else if (orState == 'ringing') {
          call.state = model.CallState.ringing;
        } else {
          log.severe('state of $call not updated!');
        }
      }
    });

    this._map = calls;

    this._callEvent.fire(new event.CallStateReload());
  }

  List<model.Call> callsOf(int userID) =>
      this.where((model.Call call) => call.assignedTo == userID).toList();

  model.Call get(String callID) {
    if (this._map.containsKey(callID)) {
      return this._map[callID];
    } else {
      throw new NotFound(callID);
    }
  }

  void update(String callID, model.Call call) {
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

  model.Call requestCall(model.User user) => this.firstWhere(
      (model.Call call) => call.assignedTo == model.User.noId && !call.locked,
      orElse: () => throw new NotFound("No calls available"));

  model.Call requestSpecificCall(String callID, model.User user) {
    model.Call call = this.get(callID);

    if (![user.id, model.User.noId].contains(call.assignedTo)) {
      log.fine('Call $callID already assigned to uid: ${call.assignedTo}');
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

  /// Determine if a channel ID is a call-channel and not an agent channel.
  bool isCall(esl.Channel channel) => this.containsID(channel.uuid);

  /// Handle CHANNEL_BRIDGE event packets.
  void _handleBridge(esl.Event e) {
    final esl.Channel uuid = _channelList.get(e.fields['Unique-ID']);
    final esl.Channel otherLeg =
        _channelList.get(e.fields['Other-Leg-Unique-ID']);

    log.finest('Bridging channel ${uuid.uuid} and channel ${otherLeg.uuid}');

    if (isCall(uuid) && isCall(otherLeg)) {
      log.finest(
          'Channel ${uuid.uuid} and channel ${otherLeg.uuid} are both calls');
      get(uuid.uuid)..bLeg = otherLeg.uuid;
      get(otherLeg.uuid)..bLeg = uuid.uuid;

      get(uuid.uuid).changeState(model.CallState.transferred);
      get(otherLeg.uuid).changeState(model.CallState.transferred);
    } else if (isCall(uuid)) {
      model.Call call = get(uuid.uuid);
      log.finest('Channel ${uuid.uuid} is a call');

      call
        ..bLeg = otherLeg.uuid
        ..changeState(model.CallState.speaking);

      _startRecording(call);
    } else if (isCall(otherLeg)) {
      model.Call call = get(otherLeg.uuid);
      log.finest('Channel ${otherLeg.uuid} is a call');
      call
        ..bLeg = uuid.uuid
        ..changeState(model.CallState.speaking);

      _startRecording(call);
    }

    // Local calls??
    else {
      log.severe('Local calls are not supported!');
    }
  }

  void _handleChannelDestroy(esl.Event e) {
    if (this.containsID(e.uniqueID)) {
      final model.Call call = this.get(e.uniqueID);
      call.hangupCause =
          e.fields['Hangup-Cause'] != null ? e.fields['Hangup-Cause'] : '';
      call.changeState(model.CallState.hungup);
      log.finest('Hanging up ${e.uniqueID}');
      this.remove(e.uniqueID);
    }
  }

  void _handleCustom(esl.Event e) {
    switch (e.eventSubclass) {

      /// Call is created
      case (ORPbxKey.callNotify):
        this._createCall(e);

        this.get(e.uniqueID)
          ..rid = e.fields.containsKey('variable_${ORPbxKey.receptionId}')
              ? int.parse(e.fields['variable_${ORPbxKey.receptionId}'])
              : 0
          ..changeState(model.CallState.created);

        break;

      case (ORPbxKey.ringingStart):
        this.get(e.uniqueID).changeState(model.CallState.ringing);
        break;

      case (ORPbxKey.ringingStop):
        this.get(e.uniqueID).changeState(model.CallState.transferring);
        break;

      case (ORPbxKey.callLock):
        if (_map.containsKey(e.uniqueID)) {
          //ESL.Channel channel = new ESL.Channel.fromPacket(event);
          final int assignedTo = get(e.uniqueID).assignedTo;

          if (assignedTo == model.User.noId) {
            log.finest('Locking ${e.uniqueID}');
            get(e.uniqueID).locked = true;
          } else {
            log.finest('Skipping locking of assigned call ${e.uniqueID}');
          }
        } else {
          log.severe('Locked non-announced call ${e.uniqueID}');
        }
        break;

      case (ORPbxKey.callUnlock):
        if (this._map.containsKey(e.uniqueID)) {
          log.finest('Unlocking ${e.uniqueID}');
          get(e.uniqueID).locked = false;
        } else {
          log.severe('Locked non-announced call ${e.uniqueID}');
        }
        break;

      /// Entering the wait queue (Playing queue music)
      case (ORPbxKey.waitQueueEnter):
        get(e.uniqueID)
          ..greetingPlayed = true
          ..changeState(model.CallState.queued);
        break;

      /// Call is parked
      case (ORPbxKey.parkingLotEnter):
        get(e.uniqueID)
          ..bLeg = null
          ..changeState(model.CallState.parked);
        break;

      /// Call is unparked
      case (ORPbxKey.parkingLotLeave):
        get(e.uniqueID)..changeState(model.CallState.transferring);
        break;
    }
  }

  void _handleEvent(esl.Event e) {
    void dispatch() {
      switch (e.eventName) {
        case (PBXEvent.channelBridge):
          this._handleBridge(e);
          break;

        case (PBXEvent.channelDestroy):
          this._handleChannelDestroy(e);
          break;

        case (PBXEvent.custom):
          this._handleCustom(e);
          break;
      }
    }

    try {
      dispatch();
    } catch (error, stackTrace) {
      log.severe('Failed to dispatch event ${e.eventName}');
      log.severe(error, stackTrace);
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
      log.finest('Skipping origination channel ${e.uniqueID}');
      return;
    }

    if (e.fields.containsKey('Other-Leg-Username')) {
      log.finest('Skipping transfer channel ${e.uniqueID}');
      return;
    }

    log.finest('Creating new call ${e.uniqueID}');

    int contactID = e.fields.containsKey('variable_${ORPbxKey.contactId}')
        ? int.parse(e.fields['variable_${ORPbxKey.contactId}'])
        : model.BaseContact.noId;

    int receptionID = e.fields.containsKey('variable_${ORPbxKey.receptionId}')
        ? int.parse(e.fields['variable_${ORPbxKey.receptionId}'])
        : model.Reception.noId;

    int userID = e.fields.containsKey('variable_${ORPbxKey.userId}')
        ? int.parse(e.fields['variable_${ORPbxKey.userId}'])
        : model.User.noId;

    final esl.Channel channel = new esl.Channel.fromEvent(e);

    model.Call createdCall = new model.Call.empty(e.uniqueID)
      ..arrived = new DateTime.fromMillisecondsSinceEpoch(
          int.parse(e.fields['Caller-Channel-Created-Time']) ~/ 1000)
      ..inbound = (e.fields['Call-Direction'] == 'inbound' ? true : false)
      ..callerId = e.fields['Caller-Caller-ID-Number']
      ..destination = channel.variables[ORPbxKey.destination]
      ..rid = receptionID
      ..cid = contactID
      ..assignedTo = userID
      ..event.listen(this._callEvent.fire);

    this._map[e.uniqueID] = createdCall;
  }

  Future _startRecording(model.Call call) async {
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

    return _pbxController
        .recordChannel(call.bLeg, filename)
        .then((_) => log.fine('Started recording call ${call.id} '
            '(agent channel: ${call.bLeg})  to file $filename'))
        .catchError((error, stackTrace) => log.severe(
            'Could not start recording of '
            'call ${call.id} to file $filename',
            error,
            stackTrace));
  }
}
