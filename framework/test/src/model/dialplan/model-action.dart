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

void _testModelAction() {
  group('Model.Action', () {
    test('parseUndefined', _ModelAction.parseUndefined);
    test('parseTransfer', _ModelAction.parseTransfer);

    test('parseVoicemail', _ModelAction.parseVoicemail);
    test('parseEnqueue', _ModelAction.parseEnqueue);

    test('parseNotify', _ModelAction.parseNotify);
    test('parseRingtone', _ModelAction.parseRingtone);
    test('parsePlayback', _ModelAction.parsePlayback);
    test('parseReceptionTransfer', _ModelAction.parseReceptionTransfer);
    test('parseIvr', _ModelAction.parseIvr);
  });
}

abstract class _ModelAction {
  static void parsePlayback() {
    final String file = 'sub_1';
    final String note = 'a note';

    model.Playback builtObject = model.Action.parse('playback $file ($note)');

    expect(builtObject.filename, equals(file));
    expect(builtObject.note, equals(note));
  }

  static void parseTransfer() {
    final String extension = 'sub_1';
    final String note = 'a note';

    model.Transfer builtObject =
        model.Action.parse('transfer $extension ($note)');

    expect(builtObject.extension, equals(extension));
    expect(builtObject.note, equals(note));
  }

  static void parseReceptionTransfer() {
    final String extension = 'sub_1';
    final String note = 'a note';

    model.ReceptionTransfer builtObject =
        model.Action.parse('reception $extension ($note)');

    expect(builtObject.extension, equals(extension));
    expect(builtObject.note, equals(note));
  }

  static void parseVoicemail() {
    final String vmBox = 'box1';
    final String note = 'a note';
    final String recipient = 'someone@somewhere.org';

    model.Voicemail builtObject =
        model.Action.parse('voicemail $vmBox $recipient ($note)');

    expect(builtObject.vmBox, equals(vmBox));
    expect(builtObject.note, equals(note));
    expect(builtObject.recipient, equals(recipient));
  }

  static void parseEnqueue() {
    final String queue = 'box1';
    final String note = 'a note';
    final String music = 'nice_tunes';

    model.Enqueue builtObject =
        model.Action.parse('enqueue $queue music $music ($note)');

    expect(builtObject.queueName, equals(queue));
    expect(builtObject.note, equals(note));
    expect(builtObject.holdMusic, equals(music));
  }

  static void parseRingtone() {
    final int count = 3;

    model.Ringtone builtObject = model.Action.parse('ringtone $count');

    expect(builtObject.count, equals(count));
  }

  static void parseNotify() {
    final String target = 'receptionists';

    model.Notify builtObject = model.Action.parse('notify $target');

    expect(builtObject.eventName, equals(target));
  }

  static void parseIvr() {
    final String menu = 'ivr_1';
    final String note = 'a note';

    model.Ivr builtObject = model.Action.parse('ivr $menu ($note)');

    expect(builtObject.menuName, equals(menu));
    expect(builtObject.note, equals(note));
  }

  static void parseUndefined() {
    expect(() => model.Action.parse('wrong wrong (just wrong)'),
        throwsA(const TypeMatcher<FormatException>()));
  }
}
