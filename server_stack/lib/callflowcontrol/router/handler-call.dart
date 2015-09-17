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

part of openreception.call_flow_control_server.router;

/// Reply templates.
Map _orignateOK(channelUUID) => {
  'status': 'ok',
  'call': {
    'id': channelUUID
  },
  'description': 'Connecting...'
};

Map _parkOK(ORModel.Call call) => {
  'status': 'ok',
  'message': 'call parked',
  'call': call
};


Map pickupOK(ORModel.Call call) => call.toJson();

Map<int, ORModel.UserState> userMap = {};

abstract class Call {
  /**
   * Retrieves a single call from the call list.
   */
  static shelf.Response get(shelf.Request request) {
    String callID = shelf_route.getPathParameter(request, 'callid');

    try {
      ORModel.Call call = Model.CallList.instance.get(callID);
      return new shelf.Response.ok(JSON.encode(call));
    } catch (error, stackTrace) {
      if (error is ORStorage.NotFound) {
        return new shelf.Response.notFound('{}');
      } else {
        log.severe(error, stackTrace);
        return new shelf.Response.internalServerError();
      }
    }
  }

  /**
   * Hangup the current call of the agent.
   */
  static Future<shelf.Response> hangup(shelf.Request request) {

    return AuthService.userOf(_tokenFrom(request)).then((ORModel.User user) {

      ORModel.Call call = Model.CallList.instance
          .firstWhere((ORModel.Call call) => call.assignedTo == user.ID,
          orElse: () => ORModel.Call.noCall);

      if (call == ORModel.Call.noCall) {
        return new shelf.Response.notFound('{}');
      }

      Model.UserStatusList.instance.update
        (user.ID, ORModel.UserState.HangingUp);

      return Controller.PBX.hangup(call)
        .then((_) =>
          Model.UserStatusList.instance.update
            (user.ID, ORModel.UserState.HandlingOffHook)
        )
        .catchError((error, stackTrace) {
          Model.UserStatusList.instance.update
            (user.ID, ORModel.UserState.Unknown);

          log.severe(error, stackTrace);
          return new shelf.Response.internalServerError();

        });

    })
    .catchError((error, stackTrace) {
      log.severe(error, stackTrace);
      return new shelf.Response.internalServerError();

    });
  }

  /**
   * Hangup a specific call identified by the supplied call id.
   */
  static Future<shelf.Response> hangupSpecific(shelf.Request request) {

    final String callID = shelf_route.getPathParameter(request, 'callid');

    List<String> hangupGroups = ['Administrator'];

    bool aclCheck(ORModel.User user) =>
        user.groups.any(hangupGroups.contains) ||
            Model.CallList.instance.get(callID).assignedTo == user.ID;

    if (callID == null || callID == "") {
      return new Future.value
          (new shelf.Response(400, body : 'Empty call_id in path.'));
    }

    return AuthService.userOf(_tokenFrom(request))
      .then((ORModel.User user) {
        if (!aclCheck(user)) {
          return new shelf.Response.forbidden ('Insufficient privileges.');
        }

        /// Verify existence of call targeted for hangup.
        ORModel.Call targetCall = null;
        try {
          targetCall = Model.CallList.instance.get(callID);
        } on ORStorage.NotFound catch (_) {
          return new shelf.Response.notFound
            (JSON.encode({'call_id': callID}));
        }

        /// Update user state.
        Model.UserStatusList.instance.update
          (user.ID, ORModel.UserState.HangingUp);

        Completer<ORModel.Call> completer = new Completer<ORModel.Call>();

        Model.CallList.instance.onEvent.
          firstWhere((OREvent.CallEvent event) =>
              event is OREvent.CallHangup && event.call.ID == callID)
            .then ((OREvent.CallHangup hangupEvent) =>
                  completer.complete(hangupEvent.call));

        return Controller.PBX.hangup(targetCall)
          .then((_) {

            return completer.future.then((ORModel.Call hungupCall) {
              /// Update user state.
              Model.UserStatusList.instance.update
                (user.ID, ORModel.UserState.WrappingUp);

              return new shelf.Response.ok(JSON.encode(hungupCall));
            }).timeout(new Duration(seconds : 3));


          })
          .catchError((error, stackTrace) {
            /// Update user state.
            Model.UserStatusList.instance.update
              (user.ID, ORModel.UserState.Unknown);

            log.severe(error, stackTrace);
            return new shelf.Response.internalServerError();
          });
      })
      .catchError((error, stackTrace) {
        log.severe(error, stackTrace);
        return new shelf.Response.internalServerError();
      });
  }

  /**
   * Lists every active call in system.
   */
  static shelf.Response list(shelf.Request request) =>
    new shelf.Response.ok(JSON.encode(Model.CallList.instance));

  /**
   * Originate a new call to the supplied extension.
   */
  static Future<shelf.Response> originate(shelf.Request request) {

    final int receptionID = int.parse(shelf_route.getPathParameter(request, 'rid'));
    final int contactID = int.parse(shelf_route.getPathParameter(request, 'cid'));
    String extension = shelf_route.getPathParameter(request, 'extension');
    final String host = shelf_route.getPathParameter(request, 'host');
    final String port = shelf_route.getPathParameter(request, 'port');

    if (host != null) {
      extension = '$extension@$host:$port';
    }

    log.finest('Originating to ${extension} in context '
               '${contactID}@${receptionID}');

    /// Any authenticated user is allowed to originate new calls.
    bool aclCheck(ORModel.User user) => true;

    bool validExtension(String extension) =>
        extension != null && extension.length > 1;

    return AuthService.userOf(_tokenFrom(request)).then((ORModel.User user) {
      if (!aclCheck(user)) {
        return new shelf.Response.forbidden ('Insufficient privileges.');
      }

      if (!validExtension(extension)) {
        return new shelf.Response(400, body : 'Invalid extension: $extension');
      }

      /// Check user state. If the user is currently performing an action - or
      /// has an active channel - deny the request.
      String userState =
          Model.UserStatusList.instance.getOrCreate(user.ID).state;

      bool inTransition =
        ORModel.UserState.TransitionStates.contains(userState);
      bool hasChannels =
        Model.ChannelList.instance.hasActiveChannels(user.peer);

      if (inTransition || hasChannels) {
        return new shelf.Response(400, body : 'Phone is not ready. '
          'state:{$userState}, hasChannels:{$hasChannels}');
      }

      /// Park all the users calls.
      return Future.forEach
        (Model.CallList.instance.callsOf(user.ID).where((ORModel.Call call) =>
          call.state == ORModel.CallState.Speaking), (ORModel.Call call) =>
            Controller.PBX.park(call, user))
        .then((_) {

          /// Update the user state
          Model.UserStatusList.instance.update
            (user.ID, ORModel.UserState.Dialing);

          /// Perform the origination via the PBX.
          return Controller.PBX.originate (extension, contactID, receptionID, user)
            .then((String channelUUID) {

              /// Update the user state
              Model.UserStatusList.instance.update
                (user.ID, ORModel.UserState.Speaking);

              return new shelf.Response.ok(JSON.encode(_orignateOK(channelUUID)));

            })
            .catchError((error, stackTrace) {
              Model.UserStatusList.instance.update
                (user.ID, ORModel.UserState.Unknown);

              log.severe(error, stackTrace);
              return new shelf.Response.internalServerError();
            });

        })
        .catchError((error, stackTrace) {
          Model.UserStatusList.instance.update
            (user.ID, ORModel.UserState.Unknown);

          log.severe(error, stackTrace);
          return new shelf.Response.internalServerError();
      });
    })
    .catchError(
        (error, stackTrace) {
      log.severe(error, stackTrace);
      return new shelf.Response.internalServerError();
    });
  }

  /**
   * Originate a new call by first creating a parked phone channel to the
   * agent and then perform the orgination in the background.
   */
  static Future<shelf.Response> originateViaPark(shelf.Request request) {

    final int receptionID = int.parse(shelf_route.getPathParameter(request, 'rid'));
    final int contactID = int.parse(shelf_route.getPathParameter(request, 'cid'));
    String extension = shelf_route.getPathParameter(request, 'extension');
    final String host = shelf_route.getPathParameter(request, 'host');
    final String port = shelf_route.getPathParameter(request, 'port');

    if (host != null) {
      extension = '$extension@$host:$port';
    }

    log.finest('Originating to ${extension} in context '
               '${contactID}@${receptionID}');

    /// Any authenticated user is allowed to originate new calls.
    bool aclCheck(ORModel.User user) => true;

    bool validExtension(String extension) =>
        extension != null && extension.length > 1;

    return AuthService.userOf(_tokenFrom(request)).then((ORModel.User user) {
      if (!aclCheck(user)) {
        return new shelf.Response.forbidden ('Insufficient privileges.');
      }

      if (!validExtension(extension)) {
        return new shelf.Response(400, body : 'Invalid extension: $extension');
      }

      String userState = Model.UserStatusList.instance.getOrCreate(user.ID).state;

      bool inTransition =
          ORModel.UserState.TransitionStates.contains(userState);
      bool hasChannels =
          Model.ChannelList.instance.hasActiveChannels(user.peer);

      if (inTransition || hasChannels) {
        return new shelf.Response(400, body : 'Phone is not ready. '
          'state:{$userState}, hasChannels:{$hasChannels}');
      }

      /// Update the user state
      Model.UserStatusList.instance.update
        (user.ID, ORModel.UserState.Dialing);

      bool isSpeaking (ORModel.Call call) =>
          call.state == ORModel.CallState.Speaking;

      Future parkIt (ORModel.Call call) => Controller.PBX.park(call, user);

      /// Park all the users calls.
      return Future.forEach
        (Model.CallList.instance.callsOf(user.ID).where(isSpeaking), parkIt)
        .then((_) {

        /// Check user state. If the user is currently performing an action - or
        /// has an active channel - deny the request.
        Future<ORModel.Call> outboundCall;

        return Controller.PBX.createAgentChannel(user)
          .then((String uuid) {
          bool outboundCallWithUuid (ESL.Event event) {
            return event.eventName == 'CHANNEL_ORIGINATE' &&
                event.channel.fields['Other-Leg-Unique-ID'] == uuid;
          }

          outboundCall =
              Model.PBXClient.instance.eventStream.firstWhere
              (outboundCallWithUuid, defaultValue : () => null)
              .then((ESL.Event event) =>
                Model.CallList.instance.get(event.uniqueID));

          /// Perform the origination via the PBX.
          return Controller.PBX.transferUUIDToExtension(uuid, extension, user)
            .then((_) {
              /// Update the user state
              Model.UserStatusList.instance.update(
                user.ID,
                ORModel.UserState.Speaking);

              return outboundCall
                .then((ORModel.Call call) {
                call.assignedTo = user.ID;
                call.receptionID = receptionID;
                call.contactID = contactID;
                call.b_Leg = uuid;

                call.changeState(ORModel.CallState.Ringing);

                return
                    Controller.PBX.setVariable
                    (call.channel, Controller.PBX.ownerUid, user.ID.toString())
                    .then((_) =>
                      Controller.PBX.setVariable
                        (call.channel, 'reception_id', receptionID.toString()))
                    .then((_) =>
                      Controller.PBX.setVariable
                         (call.channel, 'contact_id', contactID.toString()))
                    .then((_) => new shelf.Response.ok(JSON.encode(call)));
              })
              .timeout(new Duration (seconds : 3));
            });
          });
        })
        .catchError((error, stackTrace) {
          shelf.Response response;

          Model.UserStatusList.instance.update
            (user.ID, ORModel.UserState.Unknown);

          if (error is Controller.NoAnswer) {
            response = new shelf.Response(400, body : 'Phone is not reachable'
              ' (no answer). Check autoanswer.');
          }

          else if (error is TimeoutException) {
            int channelCount =
              Model.ChannelList.instance.activeChannelCount(user.peer);

            if (channelCount > 0) {
              log.shout('Phone has lingering channels and '
                         'CallFlow state may be inconsistent');
            }

            response = new shelf.Response.internalServerError
              (body : 'Failed to originate to'
                ' $extension. Check PBX configuration.');
          }

          else if (error is Controller.CallRejected) {
            response =  new shelf.Response(400, body : 'Phone is not reachable'
            ' (call rejected). Check configuration.');
          }

          else {
            log.severe(error, stackTrace);
            response = new shelf.Response.internalServerError();
          }

          return response;
        });
      });
  }

  /**
   * Park a specific call.
   */
  static Future<shelf.Response> park(shelf.Request request) {

    final String callID = shelf_route.getPathParameter(request, "callid");

    List<String> parkGroups = [
        'Administrator',
        'Service_Agent',
        'Receptionist'];

    bool aclCheck(ORModel.User user) =>
        user.groups.any((group) => parkGroups.contains(group)) ||
            Model.CallList.instance.get(callID).assignedTo == user.ID;

    return AuthService.userOf(_tokenFrom(request)).then((ORModel.User user) {
      if (callID == null || callID == "") {
        return new Future.value(
            new shelf.Response(400, body : 'Empty call_id in path.'));
      }

      ORModel.Call call = Model.CallList.instance.get(callID);

      if (!aclCheck(user)) {
        return new Future.value(
            new shelf.Response.forbidden('Insufficient privileges.'));
      }

      Model.UserStatusList.instance.update(user.ID, ORModel.UserState.Parking);

      return Controller.PBX.park(call, user).then((_) {
        Model.UserStatusList.instance.update(
            user.ID,
            ORModel.UserState.HandlingOffHook);


        String reply = JSON.encode(_parkOK(call));

        log.finest('Parked call ${reply}');

        return new shelf.Response.ok(reply);

      }).catchError((error, stackTrace) {
        Model.UserStatusList.instance.update(
            user.ID,
            ORModel.UserState.Unknown);
        log.severe(error, stackTrace);
        return new shelf.Response.internalServerError();
      });

    }).catchError((error, stackTrace) {
      if (error is ORStorage.NotFound) {
        return new shelf.Response.notFound
            (JSON.encode({'description': 'callID : $callID'}));
      } else {
        log.severe(error, stackTrace);
        return new shelf.Response.internalServerError();
      }
    }).catchError(
        (error, stackTrace) {

      log.severe(error, stackTrace);
      return new shelf.Response.internalServerError();
    });
  }

  /**
   * Pickup a specific call.
   * TODO: Wait with parking until the channelchek is done
   */
  static Future<shelf.Response> pickup(shelf.Request request) {

    final String callID = shelf_route.getPathParameter(request, 'callid');

    if (callID == null || callID == "") {
      return new Future.value
          (new shelf.Response(400, body : 'Empty call_id in path.'));
    }

    return AuthService.userOf(_tokenFrom(request)).then((ORModel.User user) {
      try {
        if (!Model.PeerList.get(user.peer).registered) {
          return new shelf.Response(400, body : 'User with ${user.ID} has no peer available');
        }
      } catch (error) {
        log.severe
          ('Failed to lookup peer for user with ID ${user.ID}. Error : $error');
        return new shelf.Response(400, body : 'User with ${user.ID} has no peer available');
      }

      /// Check user state. If the user is currently performing an action - or
      /// has an active channel - deny the request.
      String userState = Model.UserStatusList.instance.getOrCreate(user.ID).state;

      bool inTransition =
          ORModel.UserState.TransitionStates.contains(userState);
      bool hasChannels =
          Model.ChannelList.instance.hasActiveChannels(user.peer);

      if (inTransition || hasChannels) {
        return new shelf.Response
            (400, body : 'Phone is not ready. '
              'state:{$userState}, hasChannels:{$hasChannels}');
      }

      /// Park all the users calls.
      return Future.forEach(
          Model.UserStatusList.instance.activeCallsAt(user.ID),
          (ORModel.Call call) => Controller.PBX.park(call, user)).then((_) {

        /// Request the specified call.
        ORModel.Call assignedCall =
            Model.CallList.instance.requestSpecificCall(callID, user);
        assignedCall.assignedTo = user.ID;

        log.finest('Assigned call ${assignedCall.ID} to user with '
                   'ID ${user.ID}');

        /// Update the user state
        Model.UserStatusList.instance.update
          (user.ID, ORModel.UserState.Receiving);

        return Controller.PBX.transfer(assignedCall, user.peer).then((_) {
          Model.UserStatusList.instance.update(
              user.ID,
              ORModel.UserState.Speaking);

          return new shelf.Response.ok(JSON.encode(pickupOK(assignedCall)));

        }).catchError((error, stackTrace) {
          Model.UserStatusList.instance.update(
              user.ID,
              ORModel.UserState.Unknown);

          log.severe(error, stackTrace);
          return new shelf.Response.internalServerError();
        });

      }).catchError((error, stackTrace) {
        if (error is ORStorage.Conflict) {
          return new shelf.Response(409, body : JSON.encode({
            'error': 'Call not currently available.'
          }));
        }
        else if (error is ORStorage.NotFound) {
            return new shelf.Response.notFound(JSON.encode({
              'error': 'No calls available.'
            }));
        }
        else if (error is ORStorage.Forbidden) {
          return new shelf.Response.forbidden(JSON.encode({
              'error': 'Call already assigned.'
            }));
        } else {
          Model.UserStatusList.instance.update(
              user.ID,
              ORModel.UserState.Unknown);
          log.severe(error, stackTrace);
          return new shelf.Response.internalServerError();
        }
      });
    }).catchError((error, stackTrace) {
      if (error is ORStorage.NotFound) {
        return new shelf.Response.notFound(JSON.encode({
          'reason': 'No calls available.'
        }));
      } else {

        log.severe(error, stackTrace);
        return new shelf.Response.internalServerError(body : error.toString());
      }
    })
    .catchError((error, stackTrace) {
      log.severe(error, stackTrace);
      return new shelf.Response.internalServerError(body : error.toString());
    });
  }

  /**
   * Pickup a specific call.
   * TODO: Wait with parking until the channelchek is done
   */
  static Future<shelf.Response> pickupViaPark(shelf.Request request) {

    final String callID = shelf_route.getPathParameter(request, 'callid');

    if (callID == null || callID == "") {
      return new Future.value
          (new shelf.Response(400, body : 'Empty call_id in path.'));
    }

    return AuthService.userOf(_tokenFrom(request)).then((ORModel.User user) {
      try {
        if (!Model.PeerList.get(user.peer).registered) {
          return new shelf.Response(400, body : 'User with ${user.ID} has no peer available');
        }
      } catch (error) {
        log.severe
          ('Failed to lookup peer for user with ID ${user.ID}. Error : $error');
        return new shelf.Response(400, body : 'User with ${user.ID} has no peer available');
      }

      /// Check user state. If the user is currently performing an action - or
      /// has an active channel - deny the request.
      String userState = Model.UserStatusList.instance.getOrCreate(user.ID).state;

      bool inTransition =
          ORModel.UserState.TransitionStates.contains(userState);
      bool hasChannels =
          Model.ChannelList.instance.hasActiveChannels(user.peer);

      if (inTransition || hasChannels) {
        return new shelf.Response
            (400, body : 'Phone is not ready. '
              'state:{$userState}, hasChannels:{$hasChannels}');
      }

      /// Park all the users calls.
      return Future.forEach(
          Model.UserStatusList.instance.activeCallsAt(user.ID),
          (ORModel.Call call) => Controller.PBX.park(call, user)).then((_) {

        /// Request the specified call.
        ORModel.Call assignedCall =
            Model.CallList.instance.requestSpecificCall(callID, user);
        assignedCall.assignedTo = user.ID;

        log.finest('Assigned call ${assignedCall.ID} to user with '
                   'ID ${user.ID}');

        /// Update the user state
        Model.UserStatusList.instance.update
          (user.ID, ORModel.UserState.Receiving);

        return Controller.PBX.createAgentChannel(user)
          .then((String uuid) {
            /// Channel bridging
            return Controller.PBX.bridgeChannel(uuid, assignedCall)
              .then((_) =>Controller.PBX.setVariable (assignedCall.channel,
                  Controller.PBX.ownerUid, user.ID.toString()))
              .then((_) {
                /// Update the user state
                Model.UserStatusList.instance.update
                  (user.ID, ORModel.UserState.Speaking);

                return new shelf.Response.ok(JSON.encode(assignedCall));
              })
              .catchError((error, stackTrace) {
                log.severe(error, stackTrace);
                Model.UserStatusList.instance.update
                  (user.ID, ORModel.UserState.Unknown);
              });
          })
          .catchError((error, stackTrace) {
            log.severe(error, stackTrace);
            Model.UserStatusList.instance.update(
            user.ID,
            ORModel.UserState.Unknown);
            });

      }).catchError((error, stackTrace) {
        if (error is ORStorage.Conflict) {
          return new shelf.Response(409, body : JSON.encode({
            'error': 'Call not currently available.'
          }));
        }
        else if (error is ORStorage.NotFound) {
            return new shelf.Response.notFound(JSON.encode({
              'error': 'No calls available.'
            }));
        }
        else if (error is ORStorage.Forbidden) {
          return new shelf.Response.forbidden(JSON.encode({
              'error': 'Call already assigned.'
            }));
        } else {
          Model.UserStatusList.instance.update(
              user.ID,
              ORModel.UserState.Unknown);
          log.severe(error, stackTrace);
          return new shelf.Response.internalServerError();
        }
      });
    }).catchError((error, stackTrace) {
      if (error is ORStorage.NotFound) {
        return new shelf.Response.notFound(JSON.encode({
          'reason': 'No calls available.'
        }));
      } else {

        log.severe(error, stackTrace);
        return new shelf.Response.internalServerError(body : error.toString());
      }
    })
    .catchError((error, stackTrace) {
      log.severe(error, stackTrace);
      return new shelf.Response.internalServerError(body : error.toString());
    });
  }

  /**
   * Originate a call to record-sound extension in the PBX.
   */
  static Future<shelf.Response> recordSound(shelf.Request request) {

    const String recordExtension = 'slowrecordmenu';

    int receptionID;
    String recordPath;
    String token;

    try {
      receptionID = shelf_route.getPathParameter(request, 'rid');
      recordPath = request.requestedUri.queryParameters['recordpath'];
      token = request.requestedUri.queryParameters['token'];
    } catch (error, stack) {
      return new Future.value
        (new shelf.Response(400, body : 'Parameter error. ${error} ${stack}'));
    }

    if (recordPath == null) {
      return new Future.value
        (new shelf.Response(400, body : 'Missing parameter "recordpath".'));
    }

    log.finest('Originating to ${recordExtension} with path '
               '${recordPath} for reception ${receptionID}');

    /// Any authenticated user is allowed to originate new calls.
    bool aclCheck(ORModel.User user) => true;

    return AuthService.userOf(token).then((ORModel.User user) {
      if (!aclCheck(user)) {
        return new shelf.Response.forbidden('Insufficient privileges.');

      }


      /// Park all the users calls.
      return Future.forEach(
          Model.CallList.instance.callsOf(
              user.ID).where((ORModel.Call call) => call.state == ORModel.CallState.Speaking),
          (ORModel.Call call) => Controller.PBX.park(call, user)).then((_) {

        /// Check user state. If the user is currently performing an action - or
        /// has an active channel - deny the request.
        String userState = Model.UserStatusList.instance.getOrCreate(user.ID).state;

        bool inTransition =
            ORModel.UserState.TransitionStates.contains(userState);
        bool hasChannels =
            Model.ChannelList.instance.hasActiveChannels(user.peer);

        if (inTransition || hasChannels) {
          return new shelf.Response(400, body : 'Phone is not ready. '
            'state:{$userState}, hasChannels:{$hasChannels}');
        }

        /// Update the user state
        Model.UserStatusList.instance.update(
            user.ID,
            ORModel.UserState.Receiving);

        return Controller.PBX.originateRecording(
            receptionID,
            recordExtension,
            recordPath,
            user).then((String channelUUID) {

          Model.UserStatusList.instance.update(
              user.ID,
              ORModel.UserState.Speaking);

          return new shelf.Response.ok(JSON.encode(_orignateOK(channelUUID)));

        }).catchError((error, stackTrace) {
          Model.UserStatusList.instance.update(
              user.ID,
              ORModel.UserState.Unknown);

          log.severe(error, stackTrace);
          return new shelf.Response.internalServerError();
        });

      }).catchError((error, stackTrace) {
        Model.UserStatusList.instance.update(
            user.ID,
            ORModel.UserState.Unknown);

        log.severe(error, stackTrace);
        return new shelf.Response.internalServerError();
      });

    })
    .catchError((error, stackTrace) {

      log.severe(error, stackTrace);
      return new shelf.Response.internalServerError();
    });
  }

  /**
   * Transfer (bridge) two calls in the PBX.
   */
  static Future<shelf.Response> transfer(shelf.Request request) {

    String sourceCallID = shelf_route.getPathParameter(request, "aleg");
    String destinationCallID = shelf_route.getPathParameter(request, 'bleg');
    ORModel.Call sourceCall = null;
    ORModel.Call destinationCall = null;

    if (sourceCallID == null || sourceCallID == "") {
      return new Future.value
          (new shelf.Response(400, body : 'Empty call_id in path.'));
    }

    ///Check valitity of the call. (Will raise exception on invalid).
    try {
      [sourceCallID, destinationCallID].forEach(ORModel.Call.validateID);
    } on FormatException catch (_) {
      return new Future.value
       (new shelf.Response
           (400, body : 'Error in call id format (empty, null, nullID)'));
    }

    try {
      sourceCall = Model.CallList.instance.get(sourceCallID);
      destinationCall = Model.CallList.instance.get(destinationCallID);
    } on ORStorage.NotFound catch (_) {
      return new Future.value(new shelf.Response.notFound(JSON.encode({
        'description': 'At least one of the calls are ' 'no longer available'
      })));
    }

    log.finest('Transferring $sourceCall -> $destinationCall');

    /// Sanity check - are any of the calls already bridged?
    if ([
        sourceCall,
        destinationCall].every(
            (ORModel.Call call) => call.state != ORModel.CallState.Parked)) {
      log.warning(
          'Potential invalid state detected; trying to bridge a '
              'non-parked call in an attended transfer. uuids:'
              '($sourceCall => $destinationCall)');
    }

    log.finest('Transferring $sourceCall -> $destinationCall');

    return AuthService.userOf(_tokenFrom(request)).then((ORModel.User user) {
      /// Update user state.
      Model.UserStatusList.instance.update(
          user.ID,
          ORModel.UserState.Transferring);

      return Controller.PBX.bridge(sourceCall, destinationCall).then((_) {
        /// Update user state.
        Model.UserStatusList.instance.update(
            user.ID,
            ORModel.UserState.WrappingUp);
        return new shelf.Response.ok('{"status" : "ok"}');

      }).catchError((error, stackTrace) {
        /// Update user state.
        Model.UserStatusList.instance.update(
            user.ID,
            ORModel.UserState.Unknown);
        log.severe(error, stackTrace);
        return new shelf.Response.internalServerError();
      });

    })
    .catchError((error, stackTrace) {
      log.severe(error, stackTrace);
      return new shelf.Response.internalServerError();
    });

  }

}
