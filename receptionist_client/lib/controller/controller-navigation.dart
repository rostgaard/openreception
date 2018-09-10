/*                  This file is part of OpenReception
                   Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orc.controller;

enum Context { home, homePlus, calendarEdit, messages }

enum Widget {
  agentInfo,
  calendar,
  calendarEditor,
  contactData,
  contactSelector,
  globalCallQueue,
  messageArchive,
  messageCompose,
  myCallQueue,
  receptionAddresses,
  receptionAltNames,
  receptionBankInfo,
  receptionCommands,
  receptionEmail,
  receptionMiniWiki,
  receptionOpeningHours,
  receptionProduct,
  receptionSalesmen,
  receptionSelector,
  receptionTelephoneNumbers,
  receptionType,
  receptionVATNumbers,
  receptionWebsites
}

final Map<Context, Widget> _defaultWidgets = {
  Context.calendarEdit: Widget.calendarEditor,
  Context.home: Widget.receptionSelector,
  Context.homePlus: Widget.receptionMiniWiki,
  Context.messages: Widget.messageArchive
};

final Map<String, Destination> _destinations = {
  '${Context.calendarEdit}-${Widget.calendarEditor}':
      new Destination(Context.calendarEdit, Widget.calendarEditor),
  '${Context.home}-${Widget.calendar}':
      new Destination(Context.home, Widget.calendar),
  '${Context.home}-${Widget.contactData}':
      new Destination(Context.home, Widget.contactData),
  '${Context.home}-${Widget.contactSelector}':
      new Destination(Context.home, Widget.contactSelector),
  '${Context.home}-${Widget.globalCallQueue}':
      new Destination(Context.home, Widget.globalCallQueue),
  '${Context.home}-${Widget.messageCompose}':
      new Destination(Context.home, Widget.messageCompose),
  '${Context.home}-${Widget.receptionCommands}':
      new Destination(Context.home, Widget.receptionCommands),
  '${Context.home}-${Widget.receptionOpeningHours}':
      new Destination(Context.home, Widget.receptionOpeningHours),
  '${Context.home}-${Widget.receptionProduct}':
      new Destination(Context.home, Widget.receptionProduct),
  '${Context.home}-${Widget.receptionSalesmen}':
      new Destination(Context.home, Widget.receptionSalesmen),
  '${Context.home}-${Widget.receptionSelector}':
      new Destination(Context.home, Widget.receptionSelector),
  '${Context.homePlus}-${Widget.receptionAddresses}':
      new Destination(Context.homePlus, Widget.receptionAddresses),
  '${Context.homePlus}-${Widget.receptionAltNames}':
      new Destination(Context.homePlus, Widget.receptionAltNames),
  '${Context.homePlus}-${Widget.receptionBankInfo}':
      new Destination(Context.homePlus, Widget.receptionBankInfo),
  '${Context.homePlus}-${Widget.receptionEmail}':
      new Destination(Context.homePlus, Widget.receptionEmail),
  '${Context.homePlus}-${Widget.receptionMiniWiki}':
      new Destination(Context.homePlus, Widget.receptionMiniWiki),
  '${Context.homePlus}-${Widget.receptionTelephoneNumbers}':
      new Destination(Context.homePlus, Widget.receptionTelephoneNumbers),
  '${Context.homePlus}-${Widget.receptionType}':
      new Destination(Context.homePlus, Widget.receptionType),
  '${Context.homePlus}-${Widget.receptionVATNumbers}':
      new Destination(Context.homePlus, Widget.receptionVATNumbers),
  '${Context.homePlus}-${Widget.receptionWebsites}':
      new Destination(Context.homePlus, Widget.receptionWebsites),
  '${Context.messages}-${Widget.messageArchive}':
      new Destination(Context.messages, Widget.messageArchive)
};

/// A [Destination] points to a location in the application. It does this by
/// utilizing the [Context] and [Widget] enum's.
///
/// The optional [from] [Destination] MAY be used to inform a widget from where
/// it was brought into focus.
///
/// The optional [cmd] [Cmd] can be used as a lightweight payload given
/// to the destination.
class Destination {
  /// Constructor.
  Destination(Context this.context, Widget this.widget,
      {Destination this.from, Cmd this.cmd});
  Context context;
  Cmd cmd;
  Destination from;
  Widget widget;



  @override
  bool operator ==(Object other) =>
      other is Destination &&
      context == other.context &&
      widget == other.widget;

  @override
  int get hashCode => this.toString().hashCode;

  @override
  String toString() => '$context-$widget';
}

/// Handles navigation for the application. This is a singleton.
class Navigate {

  /// Constructor.
  Navigate._internal() {
    _observers();
  }
  final Bus<Destination> _bus = new Bus<Destination>();
  static final Navigate _singleton = new Navigate._internal();
  factory Navigate() => _singleton;
  final Map<Context, Widget> _widgetHistory = {};


  /// Push [destination] to the [onGo] stream. If [pushState] is true, then also
  /// add [destination] to the browser history.
  void go(Destination destination, {bool pushState: true}) {
    if (destination.widget == null) {
      if (_widgetHistory.containsKey(destination.context)) {
        destination.widget = _widgetHistory[destination.context];
      } else {
        destination.widget = _defaultWidgets[destination.context];
      }
    }

    _widgetHistory[destination.context] = destination.widget;

    if (pushState) {
      html.window.history.pushState(null, '$destination', '#$destination');
    }
    _bus.fire(destination);
  }

  /// Turn the current window.location into a [Destination] and call [go] using
  /// that.
  /// If [pushState] is true, then also add the resulting [Destination] to the
  /// browser history.
  void goWindowLocation({bool pushState: true}) {
    String hash = '';

    if (html.window.location.hash.isNotEmpty) {
      hash = html.window.location.hash.substring(1);
    }

    if (hash.isEmpty || !_destinations.containsKey(hash)) {
      goHome();
    } else {
      go(_destinations[hash], pushState: pushState);
    }
  }

  /**
   * Convenience method to navigate to [Context.calendarEdit].
   */
  void goCalendarEdit({Destination from}) {
    go(new Destination(Context.calendarEdit, null, from: from, cmd: from.cmd));
  }

  /**
   * Convenience method to navigate to [Context.home].
   */
  void goHome() {
    go(new Destination(Context.home, null));
  }

  /**
     * Convenience method to navigate to [Context.homePlus].
     */
  void goHomeplus() {
    go(new Destination(Context.homePlus, null));
  }

  /**
   * Convenience method to navigate to [Context.messages].
   */
  void goMessages() {
    go(new Destination(Context.messages, null));
  }

  /**
   *
   */
  void _observers() {
    html.window.onPopState.listen((_) => goWindowLocation(pushState: false));
  }

  /**
   * Fires a [Destination] whenever navigation is happening.
   */
  Stream<Destination> get onGo => _bus.stream;
}
