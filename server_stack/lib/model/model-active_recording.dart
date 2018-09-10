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

/// Holds a list of currently active recordings based on events from FreeSWITCH.
class ActiveRecordings extends IterableBase<model.ActiveRecording> {
  ///Internal logger.
  Logger _log = new Logger('ors.model.ActiveRecordings');

  /// Active recordings are, internally, stored as maps to enable easy lookup.
  final Map<String, model.ActiveRecording> _recordings = {};

  /// Interator simply forwards the values of the map in no particular order.
  @override
  Iterator<model.ActiveRecording> get iterator => _recordings.values.iterator;

  /// Retrive a specific recording identified by its channel [uuid].
  Future<model.ActiveRecording> get(String uuid) async => _recordings.containsKey(uuid)
      ? _recordings[uuid]
      : throw new NotFound('No active recordings on uuid');

  /// Handle an incoming [esl.Event] packet
  void handleEvent(esl.Event event) {
    void dispatch() {
      switch (event.eventName) {
        case (PBXEvent.recordStart):
          final String uuid = event.uniqueID;
          final String path = event.fields['Record-File-Path'];

          _log.finest('Starting recording of channel $uuid at path $path');
          _recordings[uuid] = new model.ActiveRecording(uuid, path);

          break;

        case (PBXEvent.recordStop):
          final String uuid = event.uniqueID;
          final String path = event.fields['Record-File-Path'];

          _log.finest('Stopping recording of channel $uuid at path $path');
          _recordings.remove(uuid);

          break;
      }
    }

    try {
      dispatch();
    } catch (error, stackTrace) {
      _log.severe('Failed to dispatch ${event.eventName}');
      _log.severe(error, stackTrace);
    }
  }

  /// JSON serialization function.
  List toJson() => this.toList(growable: false);
}
