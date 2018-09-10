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

class Sequencer {
  /// Internal logger
  final Logger _log = Logger('$_libraryName.GitEngine');
  final String path;

  File _sequencerFile;

  /// Create sequencer file from [path].
  ///
  /// If [explicitId] is set _and_ the [path] contains no sequencer file, the id
  /// of the sequencer file will be set to [explicitId].
  Sequencer(this.path, {int explicitId: 0}) {
    if (path.isEmpty) {
      throw ArgumentError.value('', 'path', 'Path must not be empty');
    }

    _sequencerFile = File('$path/.or_filestore-sequencer');
    if (!_sequencerFile.existsSync()) {
      _log.info('Creating sequencer file ${_sequencerFile.path}');
      _currentId = _findHighestId();
    } else if (explicitId > 0) {
      _currentId = explicitId;
    } else {
      _checkForInconsistencies();
    }
    _log.fine('Sequencer ID: $currentId');
  }

  /// The path of the sequencerfile
  String get sequencerFilePath => _sequencerFile.path;

  set _currentId(int id) => _sequencerFile.writeAsStringSync('$id');

  int get _currentId => int.parse(_sequencerFile.readAsStringSync());
  int get currentId => _currentId;

  int nextInt() {
    final int newId = _currentId + 1;

    _currentId = newId;

    return newId;
  }

  void _checkForInconsistencies() {
    final int highestId = _findHighestId();
    if (highestId > _currentId) {
      _log.shout('Index sequence out of sync - resyncing!');
      _currentId = highestId;
    }
  }

  int _findHighestId() {
    int fseToId(FileSystemEntity fse) {
      try {
        return int.parse(basenameWithoutExtension(fse.path));
      } on FormatException {
        return -1;
      }
    }

    Iterable<int> listing = Directory(path).listSync().map(fseToId);

    int maximum = 0;

    listing.forEach((int n) {
      if (n > maximum) {
        maximum = n;
      }
    });

    return maximum;
  }
}
