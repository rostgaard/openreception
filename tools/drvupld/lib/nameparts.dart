/*                 Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of drvupld;

/// Structure for the various properties needed to store a file.
class NameParts {
  int agentId;
  String agentName;
  String callDirection;
  DateTime callStart;
  String channelId;
  String receptionExten;
  String receptionId;
  String receptionName;
  String remoteNumber;
  String uuid;

  /// Return a title.
  ///
  /// Does not throw.
  String title() => '${saneTimeStamp(callStart)}_'
      '${agentName}_'
      '${receptionName}_'
      '${callDirection}_'
      '${remoteNumber}_'
      '${uuid}';

  /// Return an ASCII-only title.
  ///
  /// Does not throw.
  String titleASCIIOnly() => '${saneTimeStamp(callStart)}_'
      '${agentId}_'
      '${receptionExten}_'
      '${callDirection}_'
      '${remoteNumber}_'
      '${uuid}';
}

/// Returns [time] as an ISO8601 String without the milliseconds and with the T
/// replaced with one whitespace. toLocal() is called on [time] before building
/// the string.
///
/// Does not throw.
String saneTimeStamp(DateTime time) =>
    time.toLocal().toIso8601String().split('.').first.replaceAll('T', ' ');
