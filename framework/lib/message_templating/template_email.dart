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

class TemplateEmail extends Template {
  final User _sender;

  /// Default constructor.
  TemplateEmail(Message message, User this._sender) : super(message);

  /// Return the activated boolean message fields as HTML.
  String get _booleanFieldsHtml =>
      '${_message.flag.called ? '<strong>(X)</strong> Har ringet<br>' : ''}'
      '${_message.flag.pleaseCall ? '<strong>(X)</strong> Ring venligst<br>' : ''}'
      '${_message.flag.willCallBack ? '<strong>(X)</strong> Kunden ringer selv igen<br>' : ''}'
      '${_message.flag.urgent ? '<strong>(X)</strong> Haster<br>' : ''}';

  /// Return the [Message] body as HTML.
  String get bodyHtml {
    final StringBuffer sb = new StringBuffer();
    final String booleanFields = _booleanFieldsHtml;
    final String company = _message.callerInfo.company;
    final String extension = _message.callerInfo.localExtension;

    sb.write(
        'Til ${_message.context.contactName} (${_message.context.receptionName}).<br><br>');
    sb.write(
        'Der er besked fra ${_message.callerInfo.name}${company.isEmpty ? '' : ', $company'}<br><br>');
    sb.write(
        'Tlf. ${_message.callerInfo.phone} ${extension.isEmpty ? '' : 'ext: $extension'}<br>');
    sb.write('Mob. ${_message.callerInfo.cellPhone}<br><br>');
    if (booleanFields.isNotEmpty) {
      sb.write('$_booleanFieldsHtml<br>');
    }
    sb.write('Vedr.:<br>');
    sb.write('${_message.body.trim().replaceAll('\n', '<br>')}<br><br>');
    sb.write(
        'Modtaget den ${_dateFormat.format(_message.createdAt.toLocal())}<br><br>');
    sb.write('Med venlig hilsen<br>');
    sb.write('${_sender.name}<br>');
    sb.write('Responsum K/S<br><br>');
    sb.write(
        'Besøg os på <a href="https://plus.google.com/+responsum/posts">Google+</a> | <a href="https://www.facebook.com/responsumks">Facebook</a> | <a href="https://twitter.com/responsumks">Twitter</a> | <a href="http://responsum.dk">responsum.dk</a><br><br>');

    return sb.toString();
  }

  /// Return the [Message] body as text.
  @override
  String get bodyText {
    final StringBuffer sb = new StringBuffer();
    final String booleanFields = _booleanFieldsText;
    final String company = _message.callerInfo.company;
    final String extension = _message.callerInfo.localExtension;

    sb.write('Til ${_message.context.contactName}.\n\n');
    sb.write(
        'Der er besked fra ${_message.callerInfo.name}${company.isEmpty ? '' : ', $company'}\n\n');
    sb.write(
        'Tlf. ${_message.callerInfo.phone} ${extension.isEmpty ? '' : 'ext: $extension'}\n');
    sb.write('Mob. ${_message.callerInfo.cellPhone}\n\n');
    if (booleanFields.isNotEmpty) {
      sb.write('$booleanFields\n');
    }
    sb.write('Vedr.:\n');
    sb.write('${_message.body}\n\n');
    sb.write(
        'Modtaget den ${_dateFormat.format(_message.createdAt.toLocal())}\n\n');
    sb.write('Med venlig hilsen\n');
    sb.write('${_sender.name}\n');
    sb.write('Responsum K/S\n\n');

    return sb.toString();
  }

  /// Return the [Message] subject line.
  String get subject =>
      '${_message.flag.urgent ? '[${urgent.toUpperCase()}]' : ''} '
      'Besked fra ${_message.callerInfo.name}'
      '${_message.callerInfo.company.isEmpty ? '' : ', ${_message.callerInfo.company}'}'
      '${_message.callerInfo.phone.isEmpty ? '' : ', ${_message.callerInfo.phone}'}'
      '${_message.callerInfo.phone.isEmpty && _message.callerInfo.cellPhone.isNotEmpty ? ', ${_message.callerInfo.cellPhone}' : ''}'
      ' (id:${_message.id.toString()})';
}
