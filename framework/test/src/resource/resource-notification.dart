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

part of orf.test;

void _testResourceNotification() {
  group('Resource.Notification', () {
    test('socket', _ResourceNotification.notifications);
    test('socket (bad schema)', _ResourceNotification.notificationsBadSchema);
    test('send', _ResourceNotification.send);
    test('broadcast', _ResourceNotification.broadcast);
    test('clientConnection', _ResourceNotification.clientConnection);
    test('clientConnections', _ResourceNotification.clientConnections);
  });
}

abstract class _ResourceNotification {
  static final Uri _notificationService = Uri.parse('http://localhost:4242');
  static final Uri _notificationSocket = Uri.parse('ws://localhost:4242');

  static void notifications() => expect(
      resource.Notification.notifications(_notificationSocket),
      equals(Uri.parse('$_notificationSocket/notifications')));

  static void notificationsBadSchema() => expect(
      () => resource.Notification.notifications(_notificationService),
      throwsA(const TypeMatcher<ArgumentError>()));

  static void send() => expect(resource.Notification.send(_notificationService),
      equals(Uri.parse('$_notificationService/send')));

  static void clientConnection() => expect(
      resource.Notification.clientConnection(_notificationService, 123),
      equals(Uri.parse('$_notificationService/connection/123')));

  static void clientConnections() => expect(
      resource.Notification.clientConnections(_notificationService),
      equals(Uri.parse('$_notificationService/connection')));

  static void broadcast() => expect(
      resource.Notification.broadcast(_notificationService),
      equals(Uri.parse('$_notificationService/broadcast')));
}
