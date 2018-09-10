/*                  This file is part of OpenReception
                   Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.model.dialplan;

/// Sends a channel to the voicemail application if one of [digits] are
/// pressed.
class IvrVoicemail implements IvrEntry {
  /// Create a new [IvrVoicemail] ivr menu entry object.
  IvrVoicemail(this.digits, this.voicemail);

  @override
  final String digits;

  /// The voicemail account to send to.
  final Voicemail voicemail;

  @override
  String toJson() => '$digits: ${voicemail.toJson()}';
}
