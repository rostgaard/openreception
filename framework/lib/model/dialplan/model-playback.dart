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

/// Playback a sound file to a channel.
class Playback implements Action {
  /// The path of the sound file to play back.
  final String filename;

  /// The amount of times to repeat the sound file.
  ///
  /// Note: This seems broken at the moment in the dialplan compiler.
  final int repeat;

  /// Descriptive note for this [Playback] action.
  final String note;

  /// No playback file.
  static const Playback none = const Playback('');

  /// Create a new [Playback] action that plays back file with [filename].
  ///
  /// Will [repeat] the supplied number of times
  const Playback(String this.filename, {this.repeat: 1, String this.note: ''});

  /// Parses and creates a new [Playback] action from a [String] [buffer].
  static Playback parse(String buffer) {
    // Remove leading spaces.
    buffer = buffer.trimLeft();

    String filename;
    String note = '';
    int repeat = 1;

    buffer = _consumeKey(buffer, key.playback).trimLeft();

    // Legacy. Ignore playbacks with 'locked' keywords.
    if (buffer
        .substring(0, key.lock.length)
        .toLowerCase()
        .startsWith(key.lock.toLowerCase())) {
      buffer = buffer.substring(key.lock.length).trimLeft();
    }

    if (!buffer.startsWith('(')) {
      _ConsumedIdenBuf consumed = consumeWord(buffer);

      buffer = consumed.buffer.trimLeft();
      filename = consumed.iden;
    }

    if (!buffer.startsWith('(')) {
      _ConsumedIdenBuf consumed = consumeWord(buffer);

      List<String> split = consumed.iden.split(':');

      if (split.length > 1 && split.first == key.repeat) {
        repeat = int.parse(split[1]);
      }

      buffer = consumed.buffer.trimLeft();
    }

    int openBracket = buffer.indexOf('(');

    if (openBracket != -1) {
      int closeBracket =
          buffer.indexOf(')') > 0 ? buffer.indexOf(')') : buffer.length;
      note = buffer.substring(openBracket + 1, closeBracket);
    }

    return new Playback(filename, note: note, repeat: repeat);
  }

  @override
  bool operator ==(Object other) =>
      other is Playback && this.filename == other.filename;

  @override
  String toString() => '${key.playback}'
      ' $filename'
      '${repeat != 1 ? ' ${key.repeat}:$repeat' : ''}'
      '${note.isNotEmpty ? ' ($note)' : ''}';

  @override
  String toJson() => toString();

  @override
  int get hashCode => toString().hashCode;
}
