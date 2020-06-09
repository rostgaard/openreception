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

/// Library that provides gzip cached overlays on top of the storage layer.
///
/// The contained classes are stream-oriented and meant to be self-contained in
/// the sense that no explicit action should be required to keep them up-to-date
/// with the backing datastore.
library orf.gzip_cache;

import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/model.dart' as model;

const String _libraryName = 'orf.gzip_cache';

final GZipEncoder _gzipEnc = new GZipEncoder();
final GZipDecoder _gzipDec = new GZipDecoder();

const Utf8Codec _utf8 = const Utf8Codec();
const JsonCodec _json = const JsonCodec();

/// Convenience method that converts a previously gzip encoded object back into
/// an object.
dynamic unpackAndDeserializeObject(List<int> data) =>
    _json.decode(_utf8.decode(_gzipDec.decodeBytes(data)));

/// Convenience method that converts an object into a  gzip encoded object.
List<int> serializeAndCompressObject(Object obj) =>
    _gzipEnc.encode(_utf8.encode(_json.encode(obj)));

/// Returns true if [list] is actually a empty (gzipped) list.
bool isEmptyGzipList(List<int> list) {
  if (list.length != emptyGzipList.length) {
    return false;
  }

  for (int i = 0; i < emptyGzipList.length; i++) {
    if (list[i] != emptyGzipList[i]) return false;
  }

  return true;
}

/// The empty list, pre-serialized and compressed for convenience.
final List<int> emptyGzipList = serializeAndCompressObject(<int>[]);
