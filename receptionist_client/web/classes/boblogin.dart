library BobLogin;

import 'dart:async';
import 'dart:html';

import '../components.dart';
import 'configuration.dart';
import 'events.dart' as event;
import 'logger.dart';
import 'notification.dart';
import 'protocol.dart' as protocol;
import 'state.dart';

class BobLogin {
  DivElement element;
  Box box;
  SpanElement header;
  UListElement list = new UListElement();

  BobLogin(DivElement this.element) {
    assert(element != null);
    header = new SpanElement()
      ..text = 'Log ind';

    StreamSubscription subscription;
    subscription = event.bus.on(event.stateUpdated).listen((State value) {
      element.classes.toggle('hidden', !value.isUnknown);
      if(value.isConfigurationOK) {
        protocol.userslist().then((protocol.Response response) {
          if(response.status == protocol.Response.OK) {
            List users = response.data['users'];
            list.children.addAll(users.map(makeUserNode));
            box = new Box.withHeader(element, header, list);
          } else {
            ParagraphElement message = new ParagraphElement()..text = 'The list of users was unaccessable';
            box = new Box.withHeader(element, header, message);
          }
        });
        subscription.cancel();
      }
    });

    configuration.initialize();
  }

  makeUserNode(Map user) => new LIElement()
    ..text = user['name']
    ..onClick.listen((_) {
      log.debug('BobLogin. Websocket is starting.');
      notification.initialize();
      element.classes.add('hidden');

      //TODO read from user map.
      int userId = 1;
      protocol.login(userId).then((protocol.Response<Map> value) {
        if(value.status == protocol.Response.OK) {
          log.debug('Bob.dart ------- Success Logged in---------');
        } else {
          log.error('Bob.dart Did not log in.');
        }
      }).catchError((e) {
        log.error('Bob.dart: CatchError $e');
      });
    });
}