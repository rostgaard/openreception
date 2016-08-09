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

library openreception.framework.test.validation;

import 'dart:async';
import 'dart:convert';

import 'package:openreception.framework/bus.dart';
import 'package:openreception.framework/event.dart' as Event;
import 'package:openreception.framework/model.dart' as Model;
import 'package:openreception.framework/resource.dart' as Resource;
import 'package:openreception.framework/dialplan_tools.dart' as dpTools;
import 'package:openreception.framework/validation.dart';
import 'package:test/test.dart';

part 'src/validation/ivr_menu.dart';

void main() {
  ivrMenuTests();
}
