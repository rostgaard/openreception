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

library orf.test.validation;

import 'package:orf/model.dart' as model;
import 'package:orf/validation.dart';
import 'package:orf/exceptions.dart';
import 'package:test/test.dart';

part 'src/validation/ivr_menu.dart';
part 'src/validation/origination_context.dart';

void main() {
  _ivrMenuTests();
  _originationContextTests();
}
