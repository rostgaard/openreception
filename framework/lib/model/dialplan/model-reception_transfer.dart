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

/// [ReceptionTransfer] action.
///
/// Performs an internal transfer on the channel to an internal
/// reception [extension].
class ReceptionTransfer implements Action {
  /// The internal extension to transfer to.
  final String extension;

  /// Descriptive note for this [ReceptionTransfer] action.
  final String note;

  /// Default constructor.
  const ReceptionTransfer(this.extension, {this.note: ''});

  /// Parses and creates a new [ReceptionTransfer] action from
  /// a [String] [buffer].
  static ReceptionTransfer parse(String buffer) {
    // Remove leading spaces.
    buffer = buffer.trimLeft();

    String extension;
    String note = '';

    buffer = _consumeKey(buffer, key.reception).trimLeft();

    int openBracket = buffer.indexOf('(');

    if (openBracket == -1) {
      extension = buffer.trim();
    } else {
      extension = buffer.substring(0, openBracket).trimRight();

      int closeBracket =
          buffer.indexOf(')') > 0 ? buffer.indexOf(')') : buffer.length;
      note = buffer.substring(openBracket + 1, closeBracket);
    }

    return new ReceptionTransfer(extension, note: note);
  }

  /// Returns a string representaion of the object.
  @override
  String toString() => 'Transfer to reception $extension ($note)';

  /// JSON serialization function.
  @override
  String toJson() => '${key.reception} $extension'
      '${note.isNotEmpty ? ' ($note)' : ''}';

  @override
  int get hashCode => toString().hashCode;

  /// Equals ignore [note].
  @override
  bool operator ==(Object other) =>
      other is ReceptionTransfer && extension == other.extension;
}
