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

part of orf.test;

void _testModelPlayback() {
  group('Model.Playback', () {
    test('serializationDeserialization',
        _ModelPlayback.serializationDeserialization);

    test('serialization', _ModelPlayback.serialization);

    test('buildObject', _ModelPlayback.buildObject);
    test('parse', _ModelPlayback.parse);
  });
}

abstract class _ModelPlayback {
  static void serialization() {
    model.Playback builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void serializationDeserialization() {
    model.Playback builtObject = buildObject();

    model.Playback deserializedObject =
        model.Playback.parse(_json.decode(_json.encode(builtObject)));

    expect(builtObject.toJson(), equals(deserializedObject.toJson()));

    expect(builtObject.filename, equals(deserializedObject.filename));
    expect(builtObject.note, equals(deserializedObject.note));
    expect(builtObject.toJson(), equals(deserializedObject.toJson()));

    expect(builtObject.toJson(), equals(deserializedObject.toJson()));
  }

  static model.Playback buildObject() {
    final String filename = 'somefile.wav';
    final String note = 'Just a test';
    final model.Playback builtObject = new model.Playback(filename, note: note);

    expect(builtObject.filename, equals(filename));
    expect(builtObject.note, equals(note));

    return builtObject;
  }

  static void parse() {
    final String filename = 'somefile.wav';
    final String note = 'Just a test';

    model.Playback builtObject = model.Playback.parse('playback $filename');

    expect(builtObject.filename, equals(filename));

    builtObject = model.Playback.parse('playback locked $filename');

    expect(builtObject.filename, equals(filename));

    expect(builtObject.note, isEmpty);

    builtObject = model.Playback.parse('playback locked $filename repeat:2');

    expect(builtObject.filename, equals(filename));
    expect(builtObject.note, isEmpty);
    expect(builtObject.repeat, 2);

    /// Adding lots of spaces.
    builtObject = model.Playback.parse('   playback       $filename');

    expect(builtObject.filename, equals(filename));
    expect(builtObject.note, isEmpty);

    builtObject = model.Playback.parse('playback $filename ($note)');

    expect(builtObject.filename, equals(filename));
    expect(builtObject.note, equals(note));

    builtObject =
        model.Playback.parse('  playback   locked   $filename   ($note)   ');

    expect(builtObject.filename, equals(filename));
    expect(builtObject.note, equals(note));

    expect(() => model.Playback.parse('layback locked $filename ($note) '),
        throwsA(const TypeMatcher<FormatException>()));
  }
}
