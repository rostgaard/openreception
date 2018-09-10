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

void _testModelEnqueue() {
  group('Model.Enqueue', () {
    test('serializationDeserialization',
        _ModelEnqueue.serializationDeserialization);

    test('serialization', _ModelEnqueue.serialization);

    test('buildObject', _ModelEnqueue.buildObject);
    test('parse', _ModelEnqueue.parse);
  });
}

abstract class _ModelEnqueue {
  static void serialization() {
    model.Enqueue builtObject = buildObject();
    String serializedObject = _json.encode(builtObject);

    expect(serializedObject, isNotNull);
    expect(serializedObject, isNotEmpty);
  }

  static void serializationDeserialization() {
    model.Enqueue builtObject = buildObject();

    model.Enqueue deserializedObject =
        model.Enqueue.parse(_json.decode(_json.encode(builtObject)));

    expect(builtObject.queueName, equals(deserializedObject.queueName));
    expect(builtObject.holdMusic, equals(deserializedObject.holdMusic));
    expect(builtObject.toString(), isNotEmpty);
  }

  static model.Enqueue buildObject() {
    final String queueName = 'queue_1';
    final String music = 'playlist_1';
    //final String note = 'Nice music';

    model.Enqueue builtObject = new model.Enqueue(queueName, holdMusic: music);

    expect(builtObject.queueName, equals(queueName));
    expect(builtObject.holdMusic, equals(music));
    expect(builtObject.toString(), isNotEmpty);

    return builtObject;
  }

  static void parse() {
    final String queueName = 'queue_1';
    final String music = 'playlist_1';
    final String note = 'Nice music';

    model.Enqueue builtObject =
        model.Enqueue.parse('enqueue $queueName music $music');

    expect(builtObject.queueName, equals(queueName));
    expect(builtObject.holdMusic, equals(music));
    expect(builtObject.toString(), isNotEmpty);

    /// Simple object parsing.
    builtObject = model.Enqueue.parse('enqueue');

    expect(builtObject.queueName, equals(''));
    expect(builtObject.holdMusic, equals('default'));
    expect(builtObject.toString(), isNotEmpty);

    /// Adding lots of spaces.
    builtObject =
        model.Enqueue.parse('   enqueue     $queueName   music $music');

    expect(builtObject.queueName, equals(queueName));
    expect(builtObject.holdMusic, equals(music));
    expect(builtObject.toString(), isNotEmpty);

    builtObject = model.Enqueue.parse('enqueue $queueName ($note)');

    expect(builtObject.queueName, equals(queueName));
    expect(builtObject.holdMusic, equals('default'));
    expect(builtObject.toString(), isNotEmpty);

    builtObject = model.Enqueue.parse('  enqueue   $queueName   ($note)   ');

    expect(builtObject.queueName, equals(queueName));
    expect(builtObject.holdMusic, equals('default'));
    expect(builtObject.toString(), isNotEmpty);

    expect(() => model.Enqueue.parse('equeue $queueName music $music'),
        throwsA(const TypeMatcher<FormatException>()));
  }
}
