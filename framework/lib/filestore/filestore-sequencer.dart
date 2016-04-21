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

part of openreception.filestore;

class Sequencer {
  final Logger _log = new Logger('$libraryName.GitEngine');
  final String path;

  File _sequencerFile;

  void set _currentId(int id) => _sequencerFile.writeAsStringSync('$id');

  int get _currentId => int.parse(_sequencerFile.readAsStringSync());

  int nextInt() {
    final int newId = _currentId + 1;

    _currentId = newId;

    return newId;
  }

  Sequencer(String this.path) {
    _sequencerFile = new File('${path}/.or_filestore-sequencer');
    if (!_sequencerFile.existsSync()) {
      _log.info('Creating new sequencer file ${_sequencerFile.path}');
      _currentId = _findHighestId();
    } else {
      _checkForInconsistencies();
    }
  }

  /**
   *
   */
  _checkForInconsistencies() {
    final int highestId = _findHighestId();
    if (highestId > _currentId) {
      _log.shout('Index sequence out of sync - resyncing!');
      _currentId = highestId;
    }
  }

  /**
   *
   */
  int _findHighestId() {
    int fseToId(FileSystemEntity fse) {
      try {
        return int.parse(basenameWithoutExtension(fse.path));
      } on FormatException {
        return -1;
      }
    }

    Iterable<int> listing =
        new Directory(path).listSync().where((fse) => fse is File).map(fseToId);

    int maximum = 0;

    listing.forEach((n) {
      if (n > maximum) {
        maximum = n;
      }
    });

    return maximum;
  }
}