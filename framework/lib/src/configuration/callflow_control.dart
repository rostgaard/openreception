/*                  This file is part of OpenReception
                   Copyright (C) 2016-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.config;

/// Call-flow-control server configuration values.
class CallFlowControl {
  /// Enable or disable recordings globally.
  final bool enableRecordings;

  /// The directory where FreeSWITCH will store its recordings.
  ///
  /// The verbatim string `${RECORDINGS_DIR}` is a FreeSWITCH variable that
  /// unfolds into its default configured recordings directory.
  /// Any other full path may be specified here.
  final String recordingsDir;

  /// Outbound caller-ID number
  final String callerIdNumber;

  /// Outbound caller-ID name
  final String callerIdName;

  /// Timeout (in seconds) of an origination.
  final int originateTimeout;

  /// Timeout (in seconds) of waiting for an agent channel to establish.
  final int agentChantimeOut;

  /// The user contexts to load peers from. All other contexts will be ignored.
  final Iterable<String> peerContexts;

  /// The port to listen for requests on.
  final int port;

  const CallFlowControl(
      {this.port: 4242,
      this.peerContexts: const ['default', 'receptions', 'test-receptions'],
      this.agentChantimeOut: 30,
      this.originateTimeout: 120,
      this.callerIdName: 'Unknown',
      this.callerIdNumber: '00000000',
      this.recordingsDir: r'${RECORDINGS_DIR}',
      this.enableRecordings: false});

  factory CallFlowControl.fromJson(Map map) {
    final int port = map[key.port];
    final bool enableRecordings = map[key.enableRecordings];
    final String recordingsDir = map[key.recordingsDir];
    final String callerIdNumber = map[key.callerIdNumber];
    final String callerIdName = map[key.callerIdName];
    final int originateTimeout = map[key.originateTimeout];
    final int agentChantimeOut = map[key.agentChantimeOut];
    final List<String> peerContexts = map[key.peerContexts] as List<String>;

    return new CallFlowControl(
        port: port,
        peerContexts: peerContexts,
        agentChantimeOut: agentChantimeOut,
        originateTimeout: originateTimeout,
        callerIdName: callerIdName,
        callerIdNumber: callerIdNumber,
        recordingsDir: recordingsDir,
        enableRecordings: enableRecordings);
  }

  Map toJson() => {
        key.port: port,
        key.peerContexts: peerContexts,
        key.agentChantimeOut: agentChantimeOut,
        key.originateTimeout: originateTimeout,
        key.callerIdName: callerIdName,
        key.callerIdNumber: callerIdNumber,
        key.recordingsDir: recordingsDir,
        key.enableRecordings: enableRecordings
      };
}
