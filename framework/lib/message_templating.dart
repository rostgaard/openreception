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

library orf.message_templating;

import 'package:intl/intl.dart';
import 'package:orf/api.dart';


part 'message_templating/template_email.dart';
part 'message_templating/template_sms.dart';

abstract class Template {
  final String called = 'Har ringet';
  final String pleaseCall = 'Ring venligst';
  final String urgent = 'Haster';
  final String willCallBack = 'Kunden ringer selv igen';
  final DateFormat _dateFormat = new DateFormat("dd-MM-yyyy' kl. 'HH:mm:ss");
  final Message _message;

  Template(this._message);

  /// Return the [Message] body as text suited for an SMS or older email clients.
  String get bodyText;

  /// Return the activated boolean [Message] fields as text.
  String get _booleanFieldsText =>
      '${_message.flag.called ? '(X) Har ringet\n' : ''}'
      '${_message.flag.pleaseCall ? '(X) Ring venligst\n' : ''}'
      '${_message.flag.willCallBack ? '(X) Kunden ringer selv igen\n' : ''}'
      '${_message.flag.urgent ? '(X) Haster\n' : ''}';
}
