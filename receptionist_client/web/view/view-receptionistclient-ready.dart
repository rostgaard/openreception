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

part of view;

/**
 * This class is responsible for instantiating all the widgets when then
 * [Model.AppClientState] is [Model.AppState.READY].
 */
class ReceptionistclientReady {
  final Model.AppClientState _appState;
  AgentInfo _agentInfo;
  CalendarEditor _calendarEditor;
  ContactCalendar _contactCalendar;
  final Controller.Calendar _calendarController;
  final Controller.Endpoint _endpointController;
  final Controller.Call _callController;
  final Controller.Contact _contactController;
  ContactData _contactData;
  ContactSelector _contactSelector;
  Contexts _contexts;
  GlobalCallQueue _globalCallQueue;
  Hint _help;
  Map<String, String> _langMap;
  MessageArchive _messageArchive;
  MessageCompose _messageCompose;
  Controller.Message _messageController;
  MyCallQueue _myCallQueue;
  Controller.Notification _notification;
  Popup _popup;
  ReceptionAddresses _receptionAddresses;
  ReceptionAltNames _receptionAltNames;
  ReceptionBankInfo _receptionBankInfo;
  ReceptionCalendar _receptionCalendar;
  ReceptionCommands _receptionCommands;
  final Controller.Reception _receptionController;
  ReceptionEmail _receptionEmail;
  ReceptionMiniWiki _receptionMiniWiki;
  ReceptionOpeningHours _receptionOpeningHours;
  ReceptionProduct _receptionProduct;
  ReceptionSalesmen _receptionSalesmen;
  ReceptionSelector _receptionSelector;
  ReceptionTelephoneNumbers _receptionTelephoneNumbers;
  ReceptionType _receptionType;
  ReceptionVATNumbers _receptionVATNumbers;
  ReceptionWebsites _receptionWebsites;
  static ReceptionistclientReady _singleton;
  List<ORModel.Reception> _sortedReceptions;
  final Controller.User _userController;
  final Model.UIReceptionistclientReady _ui;
  WelcomeMessage _welcomeMessage;

  /**
   * Constructor.
   */
  factory ReceptionistclientReady(
      Model.AppClientState appState,
      Model.UIReceptionistclientReady uiReady,
      Controller.Calendar calendarController,
      Controller.Contact contactController,
      Controller.Reception receptionController,
      List<ORModel.Reception> sortedReceptions,
      Controller.User userController,
      Controller.Call callController,
      Controller.Notification notification,
      Controller.Message message,
      Controller.Endpoint endpointController,
      Popup popup,
      Map<String, String> langMap) {
    if (_singleton == null) {
      _singleton = new ReceptionistclientReady._internal(
          appState,
          uiReady,
          calendarController,
          contactController,
          receptionController,
          sortedReceptions,
          userController,
          callController,
          notification,
          message,
          endpointController,
          popup,
          langMap);
    } else {
      return _singleton;
    }
  }

  /**
   * Internal constructor.
   */
  ReceptionistclientReady._internal(
      Model.AppClientState this._appState,
      Model.UIReceptionistclientReady this._ui,
      this._calendarController,
      this._contactController,
      this._receptionController,
      this._sortedReceptions,
      this._userController,
      this._callController,
      this._notification,
      this._messageController,
      this._endpointController,
      this._popup,
      this._langMap) {
    _observers();
  }

  /**
   * Observers.
   */
  void _observers() {
    _appState.onStateChange.listen((Model.AppState appState) =>
        appState == Model.AppState.READY ? _runApp() : _ui.visible = false);
  }

  /**
   * Go visible and setup all the app widgets.
   */
  void _runApp() {
    final ORUtil.WeekDays _weekDays = new ORUtil.WeekDays(
        _langMap[Key.dayMonday],
        _langMap[Key.dayTuesday],
        _langMap[Key.dayWednesday],
        _langMap[Key.dayThursday],
        _langMap[Key.dayFriday],
        _langMap[Key.daySaturday],
        _langMap[Key.daySunday]);
    Model.UIContactCalendar _uiContactCalendar =
        new Model.UIContactCalendar(querySelector('#contact-calendar'), _weekDays);
    Model.UIContactSelector _uiContactSelector =
        new Model.UIContactSelector(querySelector('#contact-selector'));
    Model.UIMessageArchive _uiMessageArchive =
        new Model.UIMessageArchive(querySelector('#message-archive'), _weekDays, _langMap);
    Model.UIMessageCompose _uiMessageCompose =
        new Model.UIMessageCompose(querySelector('#message-compose'));
    Model.UIReceptionCalendar _uiReceptionCalendar =
        new Model.UIReceptionCalendar(querySelector('#reception-calendar'), _weekDays);
    Model.UIReceptionSelector _uiReceptionSelector =
        new Model.UIReceptionSelector(querySelector('#reception-selector'));

    _contexts = new Contexts(new Model.UIContexts());
    _help = new Hint(new Model.UIHint());

    _agentInfo = new AgentInfo(new Model.UIAgentInfo(querySelector('#agent-info')), _appState,
        _userController, _notification);

    _contactCalendar = new ContactCalendar(
        _uiContactCalendar,
        new Controller.Destination(Controller.Context.Home, Controller.Widget.ContactCalendar),
        _uiContactSelector,
        _uiReceptionSelector,
        _contactController,
        _calendarController,
        _notification);

    _contactData = new ContactData(
        new Model.UIContactData(querySelector('#contact-data')),
        new Controller.Destination(Controller.Context.Home, Controller.Widget.ContactData),
        _uiContactSelector,
        _uiReceptionSelector,
        _callController);

    _calendarEditor = new CalendarEditor(
        new Model.UICalendarEditor(querySelector('#calendar-editor'), _weekDays),
        new Controller.Destination(
            Controller.Context.CalendarEdit, Controller.Widget.CalendarEditor),
        _uiContactCalendar,
        _uiContactSelector,
        _uiReceptionCalendar,
        _uiReceptionSelector,
        _calendarController,
        _popup,
        _langMap);

    _contactSelector = new ContactSelector(
        _uiContactSelector,
        new Controller.Destination(Controller.Context.Home, Controller.Widget.ContactSelector),
        _uiReceptionSelector,
        _contactController);

    _globalCallQueue = new GlobalCallQueue(
        new Model.UIGlobalCallQueue(querySelector('#global-call-queue'), _langMap),
        _appState,
        new Controller.Destination(Controller.Context.Home, Controller.Widget.GlobalCallQueue),
        _notification,
        _callController,
        _popup,
        _langMap);

    _messageArchive = new MessageArchive(
        _uiMessageArchive,
        new Controller.Destination(Controller.Context.Messages, Controller.Widget.MessageArchive),
        _messageController,
        _userController,
        _uiContactSelector,
        _uiReceptionSelector,
        _uiMessageCompose,
        _popup,
        _langMap);

    _messageCompose = new MessageCompose(
        _uiMessageCompose,
        _uiMessageArchive,
        _appState,
        new Controller.Destination(Controller.Context.Home, Controller.Widget.MessageCompose),
        _uiContactSelector,
        _uiReceptionSelector,
        _messageController,
        _endpointController,
        _popup,
        _langMap);

    _myCallQueue = new MyCallQueue(
        new Model.UIMyCallQueue(querySelector('#my-call-queue'), _langMap),
        _appState,
        new Controller.Destination(Controller.Context.Home, Controller.Widget.MyCallQueue),
        _notification,
        _callController,
        _popup,
        _langMap);

    _receptionAddresses = new ReceptionAddresses(
        new Model.UIReceptionAddresses(querySelector('#reception-addresses')),
        new Controller.Destination(
            Controller.Context.Homeplus, Controller.Widget.ReceptionAddresses),
        _uiReceptionSelector);

    _receptionAltNames = new ReceptionAltNames(
        new Model.UIReceptionAltNames(querySelector('#reception-alt-names')),
        new Controller.Destination(
            Controller.Context.Homeplus, Controller.Widget.ReceptionAltNames),
        _uiReceptionSelector);

    _receptionBankInfo = new ReceptionBankInfo(
        new Model.UIReceptionBankInfo(querySelector('#reception-bank-info')),
        new Controller.Destination(
            Controller.Context.Homeplus, Controller.Widget.ReceptionBankInfo),
        _uiReceptionSelector);

    _receptionCalendar = new ReceptionCalendar(
        _uiReceptionCalendar,
        new Controller.Destination(Controller.Context.Home, Controller.Widget.ReceptionCalendar),
        _uiReceptionSelector,
        _calendarController,
        _notification);

    _receptionCommands = new ReceptionCommands(
        new Model.UIReceptionCommands(querySelector('#reception-commands')),
        new Controller.Destination(Controller.Context.Home, Controller.Widget.ReceptionCommands),
        _uiReceptionSelector);

    _receptionEmail = new ReceptionEmail(
        new Model.UIReceptionEmail(querySelector('#reception-email')),
        new Controller.Destination(Controller.Context.Homeplus, Controller.Widget.ReceptionEmail),
        _uiReceptionSelector);

    _receptionMiniWiki = new ReceptionMiniWiki(
        new Model.UIReceptionMiniWiki(querySelector('#reception-mini-wiki')),
        new Controller.Destination(
            Controller.Context.Homeplus, Controller.Widget.ReceptionMiniWiki),
        _uiReceptionSelector);

    _receptionOpeningHours = new ReceptionOpeningHours(
        new Model.UIReceptionOpeningHours(querySelector('#reception-opening-hours')),
        new Controller.Destination(
            Controller.Context.Home, Controller.Widget.ReceptionOpeningHours),
        _uiReceptionSelector);

    _receptionProduct = new ReceptionProduct(
        new Model.UIReceptionProduct(querySelector('#reception-product')),
        new Controller.Destination(Controller.Context.Home, Controller.Widget.ReceptionProduct),
        _uiReceptionSelector);

    _receptionSalesmen = new ReceptionSalesmen(
        new Model.UIReceptionSalesmen(querySelector('#reception-salesmen')),
        new Controller.Destination(Controller.Context.Home, Controller.Widget.ReceptionSalesmen),
        _uiReceptionSelector);

    _receptionSelector = new ReceptionSelector(
        _uiReceptionSelector,
        _appState,
        new Controller.Destination(Controller.Context.Home, Controller.Widget.ReceptionSelector),
        _sortedReceptions,
        _popup,
        _langMap);

    _receptionTelephoneNumbers = new ReceptionTelephoneNumbers(
        new Model.UIReceptionTelephoneNumbers(querySelector('#reception-telephone-numbers')),
        new Controller.Destination(
            Controller.Context.Homeplus, Controller.Widget.ReceptionTelephoneNumbers),
        _uiReceptionSelector);

    _receptionType = new ReceptionType(
        new Model.UIReceptionType(querySelector('#reception-type')),
        new Controller.Destination(Controller.Context.Homeplus, Controller.Widget.ReceptionType),
        _uiReceptionSelector);

    _receptionVATNumbers = new ReceptionVATNumbers(
        new Model.UIReceptionVATNumbers(querySelector('#reception-vat-numbers')),
        new Controller.Destination(
            Controller.Context.Homeplus, Controller.Widget.ReceptionVATNumbers),
        _uiReceptionSelector);

    _receptionWebsites = new ReceptionWebsites(
        new Model.UIReceptionWebsites(querySelector('#reception-websites')),
        new Controller.Destination(
            Controller.Context.Homeplus, Controller.Widget.ReceptionWebsites),
        _uiReceptionSelector);

    _welcomeMessage = new WelcomeMessage(
        new Model.UIWelcomeMessage(querySelector('#welcome-message')),
        _appState,
        _uiReceptionSelector,
        _langMap);

    _ui.visible = true;

    window.location.hash.isEmpty ? _navigate.goHome() : _navigate.goWindowLocation();
  }
}
