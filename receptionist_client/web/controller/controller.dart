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

library controller;

import 'dart:async';
import 'dart:html' as html;

import '../model/model.dart' as ui_model;

import 'package:okeyee/okeyee.dart';
import 'package:logging/logging.dart';
import 'package:openreception.framework/bus.dart';
import 'package:openreception.framework/event.dart' as event;
import 'package:openreception.framework/model.dart' as model;
import 'package:openreception.framework/service.dart' as service;
import 'package:openreception.framework/storage.dart' as storage;

part 'controller-calendar.dart';
part 'controller-call.dart';
part 'controller-contact.dart';
part 'controller-hotkeys.dart';
part 'controller-message.dart';
part 'controller-navigation.dart';
part 'controller-notification.dart';
part 'controller-popup.dart';
part 'controller-reception.dart';
part 'controller-sound.dart';
part 'controller-user.dart';

const String libraryName = 'controller';

enum Cmd { edit, create, save, focusMessageArea }

class ControllerError implements Exception {
  final String message;
  const ControllerError([this.message = ""]);

  @override
  String toString() => "ControllerError: $message";
}
