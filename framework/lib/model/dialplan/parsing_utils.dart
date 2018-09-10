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

///'Tuple' class for returning an identifier consumed from a buffer and
/// the remaining buffer.
class _ConsumedIdenBuf {
  const _ConsumedIdenBuf(this.iden, this.buffer);

  final String buffer;
  final String iden;
}

/// 'Tuple' class for returning a comment consumed from a buffer and the
/// remaining buffer.
class _ConsumedCommentBuf {
  const _ConsumedCommentBuf(this.comment, this.buffer);

  final String buffer;
  final String comment;
}

/// Consume the next word up until next space from [buffer].
_ConsumedIdenBuf consumeWord(String buffer) {
  buffer = buffer.trimLeft();

  // Locate the next terminating character.
  final int nextTerm =
      buffer.indexOf(' ') > 0 ? buffer.indexOf(' ') : buffer.length;

  return _ConsumedIdenBuf(
      buffer.substring(0, nextTerm), buffer.substring(nextTerm, buffer.length));
}

/// Consume the next comment from [buffer] up until ')' or [buffer] ends.
_ConsumedCommentBuf consumeComment(String buffer) {
  buffer = buffer.trimLeft();

  if (buffer.isEmpty) return _ConsumedCommentBuf('', '');

  if (!buffer.startsWith('(')) {
    throw FormatException('Buffer expected to start with a (', '"$buffer"');
  } else if (buffer.length < 2) {
    return _ConsumedCommentBuf('', '');
  }
  final int parRight =
      buffer.indexOf(')') > 0 ? buffer.indexOf(')') : buffer.length;

  return _ConsumedCommentBuf(
      buffer.substring(1, parRight), buffer.substring(parRight, buffer.length));
}

/// Consumes the occurence of [key] from the start of [buffer] and returns
/// the buffer again with the [key] removed.
///
/// Throws [FormatException] if the buffer does not contain the key in
/// the beginning.
String _consumeKey(String buffer, String key) => (!buffer
        .trimLeft()
        .substring(0, key.length)
        .toLowerCase()
        .startsWith(key.toLowerCase())
    ? throw FormatException(
        'Tried to parse a non-$key '
        'action as a $key',
        buffer)
    : buffer.substring(key.length));
