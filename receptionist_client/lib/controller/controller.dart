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

library orc.controller;

import 'dart:async';
import 'dart:html' as html;

import 'package:logging/logging.dart';
import 'package:okeyee2/okeyee.dart';
import 'package:orf/bus.dart';
import 'package:orf/event.dart' as or_event;
import 'package:orf/exceptions.dart';
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;

import 'package:orc/model/model.dart' as ui_model;

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
