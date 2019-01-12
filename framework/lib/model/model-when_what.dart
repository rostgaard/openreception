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

part of orf.model;

// NOTE: First day of the week in Dart DateTime is Monday.
const List<String> _validDays = const <String>[
  'mon',
  'tue',
  'wed',
  'thur',
  'fri',
  'sat',
  'sun'
];

class _WhenBlock {
  Iterable<int> _beginHourMinuteParts;
  Iterable<String> _dayParts;
  Iterable<int> _endHourMinuteParts;
  String _hourMinutePart;
  Iterable<String> _hourMinuteParts;
  List<String> _parts;
  final String _when;

  _WhenBlock(String this._when) {
    _parts = _when.split(' ');
    _dayParts = _parts.first
        .split('-')
        .where((String dp) => dp.trim().isNotEmpty)
        .map((String dp) => dp.trim());
    _hourMinutePart = _parts.last;
    _hourMinuteParts = _hourMinutePart
        .split('-')
        .where((String hmp) => hmp.trim().isNotEmpty)
        .map((String hmp) => hmp.trim());
    _beginHourMinuteParts = _hourMinuteParts.first
        .split(':')
        .where((String s) => s.trim().isNotEmpty)
        .map(_stringToInt);
    _endHourMinuteParts = _hourMinuteParts.last
        .split(':')
        .where((String s) => s.trim().isNotEmpty)
        .map(_stringToInt);
  }

  int get beginHour => _beginHourMinuteParts.first;
  int get beginMinute => _beginHourMinuteParts.last;
  int get endHour => _endHourMinuteParts.first;
  int get endMinute => _endHourMinuteParts.last;

  List<String> get check {
    final List<String> errors = <String>[];

    if (!_when.contains(':')) {
      errors.add('"when" is missing hour:minute range: $_when');
    }

    if (_parts.length != 2) {
      errors.add('Invalid "when": $_when');
    }

    if (_dayParts.length > 2 ||
        _dayParts.isEmpty ||
        _validDays.indexOf(_dayParts.first) >
            _validDays.indexOf(_dayParts.last) ||
        !_dayParts
            .every((String dp) => _validDays.any((String d) => d == dp))) {
      errors.add('Invalid day part: $_when');
    }

    if (_hourMinuteParts.length != 2 ||
        _beginHourMinuteParts.length != 2 ||
        _endHourMinuteParts.length != 2 ||
        beginHour < 0 ||
        beginHour > 23 ||
        beginMinute < 0 ||
        beginMinute > 59 ||
        endHour < 0 ||
        endHour > 23 ||
        endMinute < 0 ||
        endMinute > 59 ||
        (new DateTime(0, 1, 1, beginHour, beginMinute)
            .isAfter(new DateTime(0, 1, 1, endHour, endMinute)))) {
      errors.add('Invalid hour:minute part: $_when');
    }

    return errors;
  }

  bool match(DateTime timestamp) {
    bool matches = true;
    final int weekDay = timestamp.weekday - 1;
    final DateTime normalizedTimestamp =
        new DateTime(0, 1, 1, timestamp.hour, timestamp.minute);

    if (weekDay < _validDays.indexOf(_dayParts.first) ||
        weekDay > _validDays.indexOf(_dayParts.last)) {
      matches = false;
    }

    if (normalizedTimestamp
            .isBefore(new DateTime(0, 1, 1, beginHour, beginMinute)) ||
        normalizedTimestamp
            .isAfter(new DateTime(0, 1, 1, endHour, endMinute))) {
      matches = false;
    }

    return matches;
  }

  int _stringToInt(String s) => int.tryParse(s) ?? -1;
}

class WhenWhat {
  final List<_WhenBlock> _blocks = <_WhenBlock>[];
  final List<String> _errors = <String>[];
  String _what = '';
  String _when = '';

  /// Define "when" the "what" is relevant.
  ///
  /// Allowed "when" syntax:
  ///
  ///   man-fri 12:00-1300
  ///   tue 10:00-15:00
  ///   man 12:00-12:30, thur 12:00-12:30
  ///
  /// All "when" blocks MUST contain a day/day-range and a hour:minute range.
  /// Valid days: mon, tue, wed, thur, fri, sat, sun.
  ///
  /// "what" must simply be a non-empty string.
  WhenWhat(String when, String what) {
    _what = what.trim();
    _when = when.trim();
    _blockSplit();
  }

  WhenWhat.fromJson(Map<String, dynamic> map) {
    if (map.containsKey(key.what)) {
      _what = map[key.what].toString().trim();
    }

    if (map.containsKey(key.when)) {
      _when = map[key.when].toString().trim();
    }
    _blockSplit();
  }

  @override
  bool operator ==(Object other) =>
      other is WhenWhat && toString() == other.toString();

  void _blockSplit() {
    _blocks.addAll(_when
        .split(',')
        .where((String b) => b.trim().isNotEmpty)
        .map((String b) => new _WhenBlock(b.trim()))
        .toList());
  }

  /// Returns empty list if the [WhenWhat] checks out OK.
  /// Returns a list of errors if the [WhenWhat] does not check out OK.
  List<String> get check {
    if (_when.trim().isEmpty) {
      _errors.add('"when" is empty"');
    }

    if (_what.trim().isEmpty) {
      _errors.add('"what" is empty"');
    }

    for (_WhenBlock whenBlock in _blocks) {
      _errors.addAll(whenBlock.check);
    }

    return _errors;
  }

  List<WhenWhatMatch> matches(DateTime timestamp) {
    final List<WhenWhatMatch> hits = <WhenWhatMatch>[];

    for (_WhenBlock block in _blocks) {
      if (block.match(timestamp)) {
        hits.add(new WhenWhatMatch(
            new DateTime(timestamp.year, timestamp.month, timestamp.day,
                block.beginHour, block.beginMinute),
            new DateTime(timestamp.year, timestamp.month, timestamp.day,
                block.endHour, block.endMinute),
            _what));
      }
    }

    return hits;
  }

  @override
  int get hashCode => toString().hashCode;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{key.when: _when, key.what: _what};

  @deprecated
  Map<String, dynamic> get asMap => toJson();

  @override
  String toString() => '$_when |  $_what';

  String get what => _what;
}

class WhenWhatMatch {
  final DateTime begin;
  final DateTime end;
  final String what;

  WhenWhatMatch(DateTime this.begin, DateTime this.end, String this.what);

  @override
  String toString() => '$begin - $end $what';
}
