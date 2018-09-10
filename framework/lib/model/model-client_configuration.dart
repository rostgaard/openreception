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

part of orf.model;

List<String> _stringList(final List<dynamic> list) {
  return list.map((dynamic element) {
    if (element is String) {
      return element;
    }
    throw ArgumentError.value(element, "Element in list is not String");
  }).toList();
}

/// Configuration for clients. Is provided by the config server and contains
/// information about where to locate the various services provided by the
/// server stack.
class ClientConfiguration {


  /// Build an uninitialized object
  ClientConfiguration.empty();

  /// Build an object from a serialized map.
  ClientConfiguration.fromJson(Map<String, dynamic> map)
      : authServerUri = Uri.parse(map[key.authServerURI]),
        calendarServerUri = Uri.parse(map[key.calendarServerUri]),
        callFlowServerUri = Uri.parse(map[key.callFlowServerURI]),
        cdrServerUri = Uri.parse(map[key.cdrServerUri]),
        contactServerUri = Uri.parse(map[key.contactServerURI]),
        dialplanServerUri = Uri.parse(map[key.dialplanServerURI]),
        hideInboundCallerId = map[key.hideInboundCallerId],
        messageServerUri = Uri.parse(map[key.messageServerURI]),
        myIdentifiers = _stringList(map[key.myIdentifiers]),
        notificationServerUri = Uri.parse(map[key.notificationServerUri]),
        notificationSocketUri = Uri.parse(map[key.notificationSocket]),
        receptionServerUri = Uri.parse(map[key.receptionServerURI]),
        systemLanguage = map[key.systemLanguage],
        userServerUri = Uri.parse(map[key.userServerURI]);

  Uri authServerUri;
  Uri calendarServerUri;
  Uri callFlowServerUri;
  Uri cdrServerUri;
  Uri contactServerUri;
  Uri dialplanServerUri;
  bool hideInboundCallerId;
  Uri messageServerUri;
  List<String> myIdentifiers;
  Uri notificationServerUri;
  Uri notificationSocketUri;
  Uri receptionServerUri;
  String systemLanguage;
  Uri userServerUri;

  ///Returns a map reflection of the object suitable for data transfer.
  Map<String, dynamic> toJson() => <String, dynamic>{
        key.authServerURI: authServerUri.toString(),
        key.calendarServerUri: calendarServerUri.toString(),
        key.callFlowServerURI: callFlowServerUri.toString(),
        key.cdrServerUri: cdrServerUri.toString(),
        key.contactServerURI: contactServerUri.toString(),
        key.dialplanServerURI: dialplanServerUri.toString(),
        key.hideInboundCallerId: hideInboundCallerId,
        key.messageServerURI: messageServerUri.toString(),
        key.myIdentifiers: myIdentifiers,
        key.notificationServerUri: notificationServerUri.toString(),
        key.notificationSocket: notificationSocketUri.toString(),
        key.receptionServerURI: receptionServerUri.toString(),
        key.systemLanguage: systemLanguage,
        key.userServerURI: userServerUri.toString(),
      };
}
