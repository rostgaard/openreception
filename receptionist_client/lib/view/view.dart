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

library orc.view;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:orc/controller/controller.dart' as controller;
import 'package:orc/lang.dart';
import 'package:orc/model/model.dart' as ui_model;
import 'package:orf/event.dart' as or_event;
import 'package:orf/model.dart' as model;
import 'package:orf/util.dart' as util;

part 'view-agent-info.dart';
part 'view-calendar.dart';
part 'view-calendar-editor.dart';
part 'view-contact-data.dart';
part 'view-contact-selector.dart';
part 'view-contexts.dart';
part 'view-global-call-queue.dart';
part 'view-hint.dart';
part 'view-message-archive.dart';
part 'view-message-compose.dart';
part 'view-my-call-queue.dart';
part 'view-orc-disaster.dart';
part 'view-orc-loading.dart';
part 'view-orc-ready.dart';
part 'view-reception-addresses.dart';
part 'view-reception-alt-names.dart';
part 'view-reception-bank-info.dart';
part 'view-reception-commands.dart';
part 'view-reception-email.dart';
part 'view-reception-mini-wiki.dart';
part 'view-reception-opening-hours.dart';
part 'view-reception-product.dart';
part 'view-reception-salesmen.dart';
part 'view-reception-selector.dart';
part 'view-reception-telephone-numbers.dart';
part 'view-reception-type.dart';
part 'view-reception-vat-numbers.dart';
part 'view-reception-websites.dart';
part 'view-welcome-message.dart';

const String libraryName = "view";

final controller.HotKeys _hotKeys = new controller.HotKeys();
final controller.Navigate _navigate = new controller.Navigate();

/**
 * Common methods for all view widgets.
 */
abstract class ViewWidget {
  /**
   * SHOULD return the widgets [Destination]. MAY return null if the widget has
   * no [Destination] associated with it.
   */
  controller.Destination get _destination;

  /**
   * What to do when the widget blurs.
   */
  void _onBlur(controller.Destination destination);

  /**
   * What to do when the widget is focused.
   */
  void _onFocus(controller.Destination destination);

  /**
   * MUST return the widgets [UIModel].
   */
  ui_model.UIModel get _ui;

  /**
   * Navigate to [_destination] if widget is not already in focus.
   */
  void _navigateToMyDestination() {
    if (!_ui.isFocused) {
      _navigate.go(_destination);
    }
  }

  /**
   * If [destination] is here:
   *  call ui.focus()
   *  call onFocus()
   *
   * if [destination] is not here:
   *  call ui.blur()
   *  call onBlur();
   */
  void _setWidgetState(controller.Destination destination) {
    if (_destination == destination) {
      _ui.focus();
      _onFocus(destination);
    } else {
      _ui.blur();
      _onBlur(destination);
    }
  }
}
