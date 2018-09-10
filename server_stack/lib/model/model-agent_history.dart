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

/// The [AgentHistory] model maintains [model.AgentStatistics] associated with
/// the agents currently signed in to the system.
/// The class logs recent activities, which represent handled calls. Whenever an
/// inbound call is hung up -- while assigned to an agent -- this agent will get
/// a call (represented by a timestamp) added to its uid in the map internally.
///
/// This class maintains an internal housekeeping task to clear out old
/// statistics from the day before and bump activities that are no longer
/// considered recent to a total.
class AgentHistory {
  /// Default constructor. Sets up the internal maps and starts the housekeeping
  /// task internally.
  AgentHistory() {
    new Timer.periodic(_period, _housekeeping);
  }

  /// Internal logger.
  Logger _log = new Logger('$_libraryName.AgentHistory');

  /// Recent activity for agents. Stores timestamps of when the call activity
  /// occured so it is possible later on to move it to the total counter for
  /// that user.
  /// The total counters for each user is stored in [_callsHandledToday].
  Map<int, List<DateTime>> _recentCalls = {};

  /// The number of calls
  Map<int, int> _callsHandledToday = {};

  /// The frequency of the housekeeping.
  final Duration _period = new Duration(minutes: 1);

  /// Call activities are considered recent, when they are younger than this.
  final Duration _recent = new Duration(hours: 1);

  /// Stores the absolute time of when the housekeeping was last run.
  DateTime _lastRun = new DateTime.now();

  /// Housekeeping task. Runs every [_period].
  void _housekeeping(Timer timer) {
    // Snapshot the time, as we need it multiple times later on.
    final DateTime now = new DateTime.now();

    // Every day the totals are emptied.
    if (_lastRun.day != now.day) {
      _log.info('Day changed - emptying totals');
      _callsHandledToday = {};
    }

    // Check for timestamps older than [_recent].
    _recentCalls.forEach((int key, List<DateTime> times) {
      Iterable<DateTime> expired =
          times.where((DateTime time) => now.isAfter(time.add(_recent)));

      _callsHandledToday.containsKey(key)
          ? _callsHandledToday[key] = _callsHandledToday[key] + expired.length
          : _callsHandledToday[key] = expired.length;

      times.removeWhere((DateTime time) => now.isAfter(time.add(_recent)));
    });

    // Update the class-wide last-run timestamp.
    _lastRun = now;
  }

  /// Sums up agent statistics and returns an iterable of [model.AgentStatistics].
  Iterable<model.AgentStatistics> sumUpAll() => _recentCalls.keys.map(sumUp);

  /// Sum up the statistics of a single user and return an [model.AgentStatistics]
  /// object. Throws [NotFound] if the agent has no statistics associated.
  model.AgentStatistics sumUp(int uid) => !_recentCalls.containsKey(uid)
      ? throw new NotFound()
      : new model.AgentStatistics(
          uid,
          _recentCalls[uid].length,
          _recentCalls[uid].length +
              (_callsHandledToday.containsKey(uid)
                  ? _callsHandledToday[uid]
                  : 0));

  /// Signal that a call has been handled by an agent.
  void callHandledByAgent(int userId) => _recentCalls.containsKey(userId)
      ? _recentCalls[userId].add(new DateTime.now())
      : _recentCalls[userId] = <DateTime>[new DateTime.now()];

  /// JSON serialization function.
  List toJson() => sumUpAll().toList(growable: false);
}
