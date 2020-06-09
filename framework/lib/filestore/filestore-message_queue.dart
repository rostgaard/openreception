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

part of orf.filestore;

/// File-based storage backed for [model.MessageQueueEntry] objects.
class MessageQueue implements storage.MessageQueue {
  /// Internal logger
  final Logger _log = Logger('$_libraryName.MessageQueue');

  /// Directory path to where the serialized [model.MessageQueueEntry]
  /// objects are stored.
  final String path;

  Sequencer _sequencer;

  /// Create a [MessageQueue] store in [path].
  MessageQueue(String this.path) {
    if (path.isEmpty) {
      throw ArgumentError.value('', 'path', 'Path must not be empty');
    }

    if (!Directory(path).existsSync()) {
      Directory(path).createSync();
    }

    _sequencer = Sequencer(path);
  }

  /// Returns the next available ID from the sequencer. Notice that every
  /// call to this function will increase the counter in the
  /// sequencer object.
  int get _nextId => _sequencer.nextInt();

  @override
  Future<model.MessageQueueEntry> enqueue(model.Message message) async {
    final int mqId = _nextId;

    final model.MessageQueueEntry queueEntry =
        model.MessageQueueEntry()
          ..id = mqId
          ..unhandledRecipients = message.recipients
          ..message = message;

    final File file = File('$path/$mqId.json');

    if (file.existsSync()) {
      throw ClientError('File already exists, please update instead');
    }

    file.writeAsStringSync(_jsonpp.convert(queueEntry));

    return queueEntry;
  }

  @override
  Future<Null> update(model.MessageQueueEntry queueEntry) async {
    final File file = File('$path/${queueEntry.id}.json');

    if (!file.existsSync()) {
      throw NotFound();
    }

    file.writeAsStringSync(_jsonpp.convert(queueEntry));
  }

  @override
  Future<Null> remove(int mqid) async {
    final File file = File('$path/$mqid.json');

    if (!file.existsSync()) {
      throw NotFound();
    }

    await file.delete();
  }

  @override
  Future<List<model.MessageQueueEntry>> list() async => Directory(path)
      .listSync()
      .where(
          (FileSystemEntity fse) => fse is File && fse.path.endsWith('.json'))
      .map((FileSystemEntity fse) => model.MessageQueueEntry.fromJson(_json
          .decode((fse as File).readAsStringSync()) as Map<String, dynamic>));
}
