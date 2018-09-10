/*                  This file is part of OpenReception
                   Copyright (C) 2014-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.service.io;

class WebSocketClient extends service.WebSocket {
  io.WebSocket _websocket;

  @override
  Future<service.WebSocket> connect(Uri path) async {
    if (_websocket != null && _websocket.closeCode != null) {
      throw StateError('WebSocket is already open. '
          'Close it before opening.');
    }
    _websocket = await io.WebSocket.connect(path.toString());
    _websocket.listen((dynamic msg) => onMessage(msg),
        onError: this.onError, onDone: () => this.onClose);
    return this;
  }

  @override
  Future<void> close() => _websocket.close().then((_) => null);
}
