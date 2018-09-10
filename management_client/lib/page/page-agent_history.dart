library orm.page.agent_history;

import 'dart:async';
import 'dart:html';

//import 'package:logging/logging.dart';
import 'package:orm/controller.dart' as controller;
import 'package:orm/view.dart' as view;
import 'package:orf/event.dart' as event;
import 'package:route_hierarchical/client.dart';

/**
 *
 */
class AgentHistory {
  //final Logger _log = new Logger('orm.page.agent_history');

  final DivElement element = new DivElement()
    ..id = "monitoring-page"
    ..hidden = true
    ..classes.addAll(['page']);

  final controller.User _userController;
  final Router _router;

  view.AgentHistoryList _agentView;

  /**
   *
   */
  AgentHistory(
      controller.Call callController,
      controller.User this._userController,
      Stream<event.UserState> userStateChange,
      Stream<event.PeerState> peerStateChange,
      Stream<event.WidgetSelect> widgetSelect,
      Stream<event.FocusChange> focusChange,
      this._router) {
    _setupRouter();

    _agentView = new view.AgentHistoryList(_userController);

    element.children = [_agentView.element];
  }

  /**
   *
   */
  Future activate(RouteEvent e) async {
    element.hidden = false;
    loading = true;
    await _agentView.render();
    loading = false;
  }

  /**
   *
   */
  void deactivate(RouteEvent e) {
    element.hidden = true;
  }

  /**
   *
   */
  void _setupRouter() {
    print('setting up history router');
    _router.root
      ..addRoute(
          name: 'history',
          enter: activate,
          path: 'history',
          leave: deactivate);
  }

  /**
   *
   */
  void set loading(bool isLoading) {
    element.classes.toggle('loading', isLoading);
  }
}
