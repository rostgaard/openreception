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

part of orf.message_templating;

class TemplateSMS extends Template {
  /// Default constructor.
  TemplateSMS(Message _message) : super(_message);

  /// Return the [Message] body as text suited for an SMS or older email
  /// clients.
  @override
  String get bodyText =>
      'Fra ${_message.callerInfo.name}${_message.callerInfo.company.isEmpty ? '' : ', ${_message.callerInfo.company}'}\n'
      '${_message.callerInfo.phone.isEmpty ? '' : 'Tlf. ${_message.callerInfo.phone}  ${_message.callerInfo.localExtension.isEmpty ? '' : '(${_message.callerInfo.localExtension})'}'}\n'
      '${_message.callerInfo.cellPhone.isEmpty ? '' : 'Mob. ${_message.callerInfo.cellPhone}'}\n'
      '${_message.body}\n'
      '$_booleanFieldsText';
}
