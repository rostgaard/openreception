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

part of orf.filestore;

/// RFC3339-style (yyyy-MM-dd) [DateFormat]
final DateFormat _rfc3339 = new DateFormat('yyyy-MM-dd');

/// JSON-file based storage backed for agent call and message history.
///
/// May load and process event-dump files upon startup in order to recover
/// state.
///
/// Still work-in-progress.
class AgentHistory {
  /// Internal logger
  final Logger _log = new Logger('$_libraryName.AgentHistory');

  /// Directory path to where the serialized [model.BaseContact] objects
  /// are stored on disk.
  final String path;

  /// Userstore used internally for looking up user names.
  final storage.User _userStore;

  /// Local cache of UID/username mappings.
  final Map<int, String> _uidNameCache = <int, String>{};

  /// File containing persistent cache of UID/username mappings.
  final File _uidMapFile;

  /// Directory that contains event dump files that processed and purged
  /// upon object initialization.
  final Directory _eventDumpDir;
  final Map<String, model.ActiveCall> _eventHistory =
      <String, model.ActiveCall>{};
  final Map<String, model.DailyReport> _reports = <String, model.DailyReport>{};

  Completer<Null> _initialized = new Completer<Null>();

  /// Create a new [AgentHistory] in directory [path].
  ///
  /// Requires a [userStore] to be able to map user ID's to names, and the
  /// stream of system [notifications].
  /// Will create a `uidmappings.json` file in [path] and look for a folder
  /// called `eventdumps`. The latter will be scanned for event dump files
  /// and any file found, will be processed and deleted subsequently.
  factory AgentHistory(
      String path, storage.User userStore, Stream<event.Event> notifications) {
    if (path.isEmpty) {
      throw new ArgumentError.value('', 'path', 'Path must not be empty');
    }

    return new AgentHistory._internal(
        path,
        userStore,
        new File(path + '/uidmappings.json'),
        new Directory(path + '/eventdumps'),
        notifications);
  }

  /// Internal constructor that creates missing directories and finalizes
  /// fields.
  AgentHistory._internal(this.path, this._userStore, this._uidMapFile,
      this._eventDumpDir, Stream<event.Event> notifications) {
    if (!new Directory(path).existsSync()) {
      _log.info('Creating directory $path');
      new Directory(path).createSync();
    }

    if (!_eventDumpDir.existsSync()) {
      _log.info('Creating directory ${_eventDumpDir.path}');
      _eventDumpDir.createSync();
    }

    if (!new Directory(path + '/reports').existsSync()) {
      _log.info('Creating directory $path/reports');
      new Directory(path + '/reports').createSync();
    }

    if (!_uidMapFile.existsSync()) {
      _uidMapFile.writeAsStringSync('{}');
    }

    notifications.listen((event.Event e) {
      _dispatchEvent(e, _reports);
    });

    new Timer.periodic(new Duration(seconds: 10), (_) => _cleanup());

    _initialize();
  }

  /// Returns when the store is fully initialized.
  Future<Null> get initialized => _initialized.future;

  /// Loads a full [model.DailyReport] for a given [day].
  Future<model.DailyReport> get(DateTime day) async => _loadReport(day);

  /// Loads a full report for a given [day] without deserializing it.
  Stream<List<int>> getRaw(DateTime day) {
    final File f = new File('$path/reports/${_dateKey(day)}.json.gz');
    if (f.existsSync()) {
      return f.readAsBytes().asStream();
    } else {
      throw new NotFound('No report for day ${_dateKey(day)}');
    }
  }

  /// Initilizes the store.
  Future<Null> _initialize() async {
    await _loadUidCacheFile();
    await _updateUidCache();
    await _saveUidCacheFile();
    await _loadEventDumps();

    _initialized.complete();
  }

  /// Update the uid/username mapping file.
  ///
  /// The mapping file is a way of maintaining a knowledged of which name an
  /// agent (with a given uid) has, prior to user deletion.
  Future<Null> _updateUidCache() async {
    Iterable<model.UserReference> uRefs = await _userStore.list();

    uRefs.forEach((model.UserReference uref) {
      _uidNameCache[uref.id] = uref.name;
    });
  }

  /// Process and dispatch events from notification stream.
  void _dispatchEvent(event.Event e, Map<String, model.DailyReport> reports) {
    final String dateKey = _rfc3339.format(e.timestamp);

    if (!reports.containsKey(dateKey)) {
      reports[dateKey] = _loadReport(e.timestamp);
    }

    if (e is event.CallEvent) {
      if (!_eventHistory.containsKey(e.call.id)) {
        _eventHistory[e.call.id] = new model.ActiveCall.empty();
      }
      _eventHistory[e.call.id].addEvent(e);

      if (_eventHistory[e.call.id].isDone) {
        reports[dateKey].addCallHistory(_eventHistory[e.call.id]);
      }
    } else if (e is event.MessageChange && e.isCreate) {
      reports[dateKey].addMessageHistory(
          new model.MessageHistory(e.mid, e.modifierUid, e.timestamp));
    } else if (e is event.UserState) {
      reports[dateKey].addUserStateChange(new model.UserStateHistory(
          e.status.userId, e.timestamp, e.status.paused));
    } else {
      return;
    }
  }

  /// Load historic event dump files and inject them into the agent history.
  Future<Null> _loadEventDumps() async {
    _log.finest('Loading event dumps from ${_eventDumpDir.path}');
    final Map<String, model.DailyReport> _dateLog =
        <String, model.DailyReport>{};

    final Iterable<File> files =
        _eventDumpDir.listSync().where((FileSystemEntity fse) => fse is File);

    files.forEach((File file) {
      _log.info('Reading event dump from ${file.path}');
      try {
        List<String> lines = file.readAsLinesSync();

        for (String line in lines) {
          Map<String, dynamic> json =
              _json.decode(line) as Map<String, dynamic>;
          event.Event e = new event.Event.parse(json);
          try {
            if (e != null) _dispatchEvent(e, _dateLog);
          } catch (e, s) {
            _log.shout(
                'Failed to load line "$line" in file ${file.path}', e, s);
          }
        }

        file.delete();
      } catch (e, s) {
        _log.warning('Could not read event dump from file ${file.path} ', e, s);
      }
    });

    await Future.forEach(_dateLog.values, (model.DailyReport report) async {
      await _saveReport(report);
    });

    _log.finest('Read event dumps from ${files.length} files');
  }

  /// Load a [model.DailyReport] for a given [day].
  model.DailyReport _loadReport(DateTime day) {
    final File f = new File('$path/reports/${_dateKey(day)}.json.gz');
    if (f.existsSync()) {
      _log.finest('Loading existing report for ${_dateKey(day)}');
      return new model.DailyReport.fromJson(
          unpackAndDeserializeObject(f.readAsBytesSync())
              as Map<String, dynamic>);
    } else {
      _log.finest('Creating new daily report for ${_dateKey(day)}');
      return new model.DailyReport.empty();
    }
  }

  /// Save a [model.DailyReport] to file.
  ///
  /// Will not save the report if it is empty.
  Future<Null> _saveReport(model.DailyReport report) async {
    if (report.isEmpty) {
      _log.fine('Refusing to write empty report');
      return;
    }

    final File f = new File('$path/reports/${_dateKey(report.day)}.json.gz');
    _log.finest('Writing report for ${_dateKey(report.day)} to file ${f.path}');
    await f.writeAsBytes(serializeAndCompressObject(report));
  }

  // Iterable<model.AgentStatisticsSummary> summaries(DateTime day) {
  //   return [];
  // }

  /// Cleanup reports on a daily basis.
  Future<Null> _cleanup() async {
    if (_reports.length > 1) {
      _log.info('Day changed. Rerolling stats');

      final List<String> keysToRemove = _reports.keys
          .where((String key) => key != _dateKey(new DateTime.now()))
          .toList(growable: false);

      for (String key in keysToRemove) {
        _log.finest('Removing memory cache for day $key');
        await _saveReport(_reports.remove(key));
      }
    } else {
      _log.finest('Updating daily report');
      final DateTime day = new DateTime.now();
      if (!_reports.containsKey(_dateKey(day))) {
        _reports[_dateKey(day)] = _loadReport(day);
      }

      await _saveReport(_reports[_dateKey(day)]);
    }
  }

  /// Lookup a the username of a user with [uid].
  Future<String> lookupUsername(int uid) async {
    await initialized;

    if (!_uidNameCache.containsKey(uid)) {
      try {
        final model.User user = await _userStore.get(uid);
        _uidNameCache[uid] = user.name;

        await _saveUidCacheFile();
      } on NotFound {
        _log.warning('Failed to located name of uid:$uid. '
            'Consider adding name to cache manually'
            ' (file ${_uidMapFile.path})');
        return '?';
      }
    }
    return _uidNameCache[uid];
  }

  /// Load the persistent uid/username mappings from file.
  Future<Null> _loadUidCacheFile() async {
    Map<String, String> deserialized;
    try {
      deserialized =
          _json.decode(await _uidMapFile.readAsString()) as Map<String, String>;
    } on FormatException {
      _log.shout('Corrupt format for uid -> name mappings in '
          'file ${_uidMapFile.path}');
      return;
    }

    _uidNameCache.clear();
    deserialized.forEach((String uidString, String userName) {
      try {
        final int uid = int.parse(uidString);
        _uidNameCache[uid] = userName;
      } on FormatException {
        _log.warning('Bad key value $uidString');
      }
    });

    _log.finest('Loaded ${_uidNameCache.length} uid -> name mappings from '
        'file ${_uidMapFile.path}');
  }

  /// Save the persistent uid/username mappings to file.
  Future<Null> _saveUidCacheFile() async {
    final Map<String, String> serializable = <String, String>{};

    _uidNameCache.forEach((int uid, String username) {
      serializable[uid.toString()] = username;
    });

    await _uidMapFile.writeAsString(_json.encode(serializable));
    _log.finest('Saved ${_uidNameCache.length} uid -> name mappings to '
        'file ${_uidMapFile.path}');
  }

  /// Convenience function for generating the map key for a date.
  String _dateKey(DateTime day) => _rfc3339.format(day);

  /// Retrieve the [model.DailySummary] for [day].
  Future<model.DailySummary> agentSummay(DateTime day) async =>
      new model.DailySummary(await get(day));
}
