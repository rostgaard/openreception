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

library openreceptionclient;

import 'dart:async';
import 'dart:html';

import 'controller/controller.dart' as Controller;
import 'lang.dart' as Lang;
import 'model/model.dart' as Model;
import 'view/view.dart' as View;

import 'package:logging/logging.dart';
import 'package:openreception_framework/model.dart' as ORModel;
import 'package:openreception_framework/service.dart' as ORService;
import 'package:openreception_framework/service-html.dart' as ORTransport;

part 'configuration_url.dart';

const String libraryName = 'openreceptionclient';

View.ReceptionistclientDisaster appDisaster;
View.ReceptionistclientLoading  appLoading;
View.ReceptionistclientReady    appReady;
final Logger                    log = new Logger(libraryName);

main() async {
  final Model.AppClientState   appState = new Model.AppClientState();
  Uri                          appUri;
  ORModel.ClientConfiguration  clientConfig;
  Map<String, String>          language;
  Controller.Notification      notification;
  String                       token;
  ORTransport.WebSocketClient  webSocketClient;

  try {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(print);

    /// Hang here until the client configuration has been loaded from the server.
    clientConfig = await getClientConfiguration();

    /// Set the app language
    language = getLanguageMap(clientConfig.systemLanguage);

    /// Translate the static labels of the app. We do this early to have correct
    /// labels set while loading.
    translate(language);

    /// Get the app Disaster and Loading views up and running.
    registerDisasterAndLoadingViews(appState);

    appUri = Uri.parse(window.location.href);

    /// This is the 'settoken' URL path parameter.
    token = getToken(appUri);

    /// Make sure we don't steal focus from widgets with mouseclicks on non-widget
    /// elements. This is simply done by searching for the "ignoreclickfocus"
    /// attribute and ignoring mousedown events for those elements.
    document.onMouseDown.listen((MouseEvent event) {
      if((event.target as HtmlElement).attributes.keys.contains('ignoreclickfocus')) {
        event.preventDefault();
      }
    });

    if(token != null) {
      Model.User.currentUser = await getUser(clientConfig.authServerUri, token);

      webSocketClient = new ORTransport.WebSocketClient();
      notification    = new Controller.Notification(new ORService.NotificationSocket(webSocketClient));

      Uri uri = Uri.parse('${clientConfig.notificationSocketUri}?token=${token}');

      webSocketClient.connect(uri).then((_) {
        log.info('WebSocketClient connect succeeded - NotificationSocket up');

        ORService.CallFlowControl callFlowControl = new ORService.CallFlowControl
            (clientConfig.callFlowServerUri, token, new ORTransport.Client());
        Controller.User controllerUser = new Controller.User(callFlowControl);

        observers(controllerUser);

        Future rRV = registerReadyView(appState,
                                       clientConfig,
                                       controllerUser,
                                       callFlowControl,
                                       notification,
                                       language,
                                       token);
        Future lCS = loadCallState(callFlowControl);
        Future sP = controllerUser.setPaused(Model.User.currentUser);

        Future.wait([rRV, lCS, sP]).then((_) {
          appState.changeState(Model.AppState.READY);
        })
        .catchError((error) {
          log.shout('Loading of app failed with ${error}');
          appState.changeState(Model.AppState.ERROR);
        });
      });
    } else {
      String loginUrl = '${clientConfig.authServerUri}/token/create?returnurl=${window.location.toString()}';
      log.info('No token detected, redirecting user to $loginUrl');
      window.location.replace(loginUrl);
    }
  } catch(error, stackTrace) {
    log.shout('Could not fully initialize application. Trying again in 10 seconds');
    log.shout(error, stackTrace);
    appState.changeState(Model.AppState.ERROR);

    new Future.delayed(new Duration(seconds: 10)).then((_) {
      appUri = Uri.parse(window.location.href);
      window.location.replace('${appUri.origin}${appUri.path}');
    });
  }
}

/**
 * Return the configuration object for the client.
 */
Future<ORModel.ClientConfiguration> getClientConfiguration() async {
  ORService.RESTConfiguration configService =
      new ORService.RESTConfiguration(CONFIGURATION_URL, new ORTransport.Client());

  return configService.clientConfig().then((ORModel.ClientConfiguration config) {
      log.info('Loaded client config: ${config.asMap}');
      return config;
  });
}

/**
 * Return the language map that corresponds to [language]. If [language] doesn't
 * exist, then return the english language map.
 */
Map<String, String> getLanguageMap(String language) {
  Map<String, String> map;

  switch(language) {
    case 'da':
      map = Lang.da;
      break;
    case 'en':
      map = Lang.en;
      break;
    default:
      map = Lang.en;
      break;
  }

  return map;
}

/**
 * Return the value of the URL path parameter 'settoken'
 */
String getToken(Uri appUri) => appUri.queryParameters['settoken'];

/**
 * Return the current user.
 */
Future<ORModel.User> getUser(Uri authServerUri, String token) async {
  ORService.Authentication authService =
      new ORService.Authentication(authServerUri, token, new ORTransport.Client());

  return authService.userOf(token).then((ORModel.User user) {
    return new Model.User.fromORModel(user);
  });
}

/**
 * Load call state for current user.
 */
Future loadCallState(ORService.CallFlowControl callFlowControl) {
  return callFlowControl.callList().then((Iterable<ORModel.Call> calls) {
    ORModel.Call myActiveCall =
      calls.firstWhere((ORModel.Call call) =>
          call.assignedTo == Model.User.currentUser.ID &&
          call.state      == ORModel.CallState.Speaking, orElse: () => null);

    if(myActiveCall != null) {
      Model.Call.activeCall = new Model.Call.fromORModel(myActiveCall);
    }
  });
}

/**
 * Observers.
 *
 * Registers the [window.onBeforeUnload] and [window.onUnload] listeners that is
 * responsible for popping a warning on refresh/page close and logging out the
 * user when she exits the application.
 */
void observers(Controller.User controllerUser) {
  window.onBeforeUnload.listen((BeforeUnloadEvent event) {
    event.returnValue = '';
  });

  window.onUnload.listen((_) {
    controllerUser.setLoggedOut(Model.User.currentUser);
  });
}

/**
 * Register the [View.ReceptionistclientDisaster] and [View.ReceptionistclientLoading]
 * app view objects.
 *
 * NOTE: This depends on [clientConfig] being set.
 */
void registerDisasterAndLoadingViews(Model.AppClientState appState) {
  Model.UIReceptionistclientDisaster uiDisaster =
      new Model.UIReceptionistclientDisaster('receptionistclient-disaster');
  Model.UIReceptionistclientLoading  uiLoading =
      new Model.UIReceptionistclientLoading('receptionistclient-loading');

  appDisaster = new View.ReceptionistclientDisaster(appState, uiDisaster);
  appLoading  = new View.ReceptionistclientLoading(appState, uiLoading);
}

/**
 * Register the [View.ReceptionistclientReady] app view object.
 * NOTE: This depends on [clientConfig] being set.
 */
Future registerReadyView(Model.AppClientState appState,
                         ORModel.ClientConfiguration clientConfig,
                         Controller.User controllerUser,
                         ORService.CallFlowControl callFlowControl,
                         Controller.Notification notification,
                         Map<String, String> langMap,
                         String token) {
  Model.UIReceptionistclientReady uiReady =
      new Model.UIReceptionistclientReady('receptionistclient-ready');
  ORService.RESTContactStore contactStore = new ORService.RESTContactStore
      (clientConfig.contactServerUri, token, new ORTransport.Client());
  ORService.RESTReceptionStore receptionStore = new ORService.RESTReceptionStore
      (clientConfig.receptionServerUri, token, new ORTransport.Client());
  Controller.Reception receptionController = new Controller.Reception(receptionStore);

  return receptionController.list()
      .then((Iterable<Model.Reception> receptions) {
        Iterable<Model.Reception> sortedReceptions = receptions.toList()
            ..sort((x,y) => x.name.compareTo(y.name));

        appReady = new View.ReceptionistclientReady
            (appState,
             uiReady,
             new Controller.Contact(contactStore),
             receptionController,
             sortedReceptions,
             controllerUser,
             new Controller.Call(callFlowControl),
             notification,
             langMap);
      });
}

/**
 * Worlds most simple method to translate widget labels to supported languages.
 */
void translate(Map<String, String> langMap) {
  querySelectorAll('[data-lang-text]').forEach((HtmlElement element) {
    element.text = langMap[element.dataset['lang-text']];
  });

  querySelectorAll('[data-lang-placeholder]').forEach((HtmlElement element) {
    element.setAttribute('placeholder', langMap[element.dataset['lang-placeholder']]);
  });
}
