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

/// Broadcast bus subsystem.
library orf.bus;

import 'dart:async';

/// Type "safe" event bus, using the Dart Stream API.
///
/// This is basically just a thin wrapper around [StreamController] that
/// provides a broadcast stream.
class Bus<Type> {
  Bus() {
    _streamController = new StreamController<Type>.broadcast();
  }
  StreamController<Type> _streamController;

  /// Default constructor. Creates and initializes a new broadcast stream
  /// that emits objects of [Type].


  /// The stream of the [Bus] that emits objects of [Type].
  Stream<Type> get stream => _streamController.stream;

  /// Inject an [event] of [Type] into the stream of [Bus].
  ///
  /// Only listeners subscribed to the [stream] of [Bus] prior to the
  /// calling of this function will receive [event].
  void fire(Type event) {
    _streamController.add(event);
  }

  /// Close the [Bus].
  Future<Null> close() async {
    await _streamController.close();
  }
}
