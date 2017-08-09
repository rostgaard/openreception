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

part of orc.view;

/**
 * Component for creating/editing and saving/sending messages.
 */
class MessageCompose extends ViewWidget {
  final ui_model.AppClientState _appState;
  final ui_model.UIContactSelector _contactSelector;
  final Map<String, String> _langMap;
  final Logger _log = new Logger('$libraryName.MessageCompose');
  final controller.Message _messageController;
  final controller.Destination _myDestination;
  controller.Destination _myDestinationMessageBox;
  final controller.Notification _notification;
  final List<model.Call> _pickedUpCalls = new List<model.Call>();
  final controller.Popup _popup;
  final ui_model.UIReceptionSelector _receptionSelector;
  final ui_model.UIMessageArchive _uiMessageArchive;
  final ui_model.UIMessageCompose _uiModel;

  /**
   * Constructor.
   */
  MessageCompose(
      ui_model.UIMessageCompose this._uiModel,
      ui_model.UIMessageArchive this._uiMessageArchive,
      ui_model.AppClientState this._appState,
      controller.Destination this._myDestination,
      ui_model.UIContactSelector this._contactSelector,
      ui_model.UIReceptionSelector this._receptionSelector,
      controller.Message this._messageController,
      controller.Notification this._notification,
      controller.Popup this._popup,
      Map<String, String> this._langMap) {
    _ui.setHint('alt+b | alt+d | alt+space | ctrl+space | ctrl+s | ctrl+enter');

    _myDestinationMessageBox = new controller.Destination(
        controller.Context.home, controller.Widget.messageCompose,
        cmd: controller.Cmd.focusMessageArea);

    _observers();
  }

  @override
  controller.Destination get _destination => _myDestination;
  @override
  ui_model.UIMessageCompose get _ui => _uiModel;

  @override
  void _onBlur(controller.Destination _) {}
  @override
  void _onFocus(controller.Destination destination) {
    if (destination.cmd == controller.Cmd.focusMessageArea) {
      _ui.focusMessageTextArea();
    }
  }

  /**
   * Simply navigate to my [_myDestination]. Matters not if this widget is
   * already focused.
   */
  void _activateMe() {
    _navigateToMyDestination();
  }

  /**
   * Save message draft in the message archive.
   */
  Future _draft(model.Message message) async {
    message.state = model.MessageState.draft;
    try {
      model.Message savedMessage = await _messageController.save(message);

      _ui.reset();
      _ui.focusOnCurrentFocusElement();

      _log.info('Message id ${savedMessage.id} successfully saved as draft');
      _popup.success(
          _langMap[Key.messageSaveSuccessTitle], 'ID ${savedMessage.id}');
    } catch (error) {
      _log.shout('Could not save as draft ${message.toJson()} $error');
      _popup.error(_langMap[Key.messageSaveErrorTitle], 'ID ${message.id}');
    }
  }

  /**
   * Return a [model.Message] build from the form data and the currently
   * selected contact.
   */
  model.Message get _message {
    final model.Message message = _ui.message;
    message.sender = _appState.currentUser;
    final model.MessageContext messageContext =
        new model.MessageContext.fromContact(
            _contactSelector.selectedContact.contact,
            _receptionSelector.selectedReception);

    if (messageContext.rid == model.Reception.noId) {
      /// We shouldn't really be here, since that means the system have returned
      /// an empty reception reference from _receptionSelector.selectedReception
      /// Lets at least try to get a rid, so we can proceed with sending the
      /// message.
      messageContext.rid = _contactSelector.selectedContact.attr.receptionId;
    }

    message.context = messageContext;

    return message;
  }

  /**
   * If a contact is selected in [_contactSelector], then navigate to the
   * calendar editor with `cmd` set.
   */
  void _navigateToMessageTextArea() {
    _navigate.go(_myDestinationMessageBox);
  }

  /**
   * Observers.
   */
  void _observers() {
    _navigate.onGo.listen(_setWidgetState);

    _ui.onClick.listen((MouseEvent _) => _activateMe());

    _hotKeys.onAltB.listen((KeyboardEvent _) {
      if (_ui.isFocused) {
        _ui.focusCallerNameInput();
      } else {
        _activateMe();
      }
    });

    _hotKeys.onAltD.listen((KeyboardEvent _) => _navigateToMessageTextArea());

    _contactSelector.onSelect.listen(
        (ui_model.ContactWithFilterContext c) => _render(c.contact, c.attr));

    _contactSelector.onCtrlEnter.listen((_) {
      _ui.sendButton.click();
    });

    _contactSelector.onCtrlS.listen((_) {
      _ui.draftButton.click();
    });

    _notification.onAnyCallStateChange.listen((or_event.CallEvent event) {
      if (event.call.assignedTo == _appState.currentUser.id &&
          event.call.state == model.CallState.hungup) {
        _pickedUpCalls.removeWhere((model.Call c) => c.id == event.call.id);
      }
    });

    _appState.activeCallChanged.listen((model.Call newCall) {
      if (newCall != model.Call.noCall &&
          newCall.inbound &&
          !_pickedUpCalls.any((model.Call c) => c.id == newCall.id)) {
        _pickedUpCalls.add(newCall);

        /// This is somewhat nasty. We're assuming that this fires _before_ the
        /// _contactSelector fires a newly selected contact.
        _ui.reset(pristine: true);

        if (_ui.isFocused) {
          /// Will focus whichever element that has been registered by the
          /// _ui.reset() call.
          _ui.focusOnCurrentFocusElement();
        }
      }
    });

    _ui.onDraft.listen((MouseEvent _) async => await _draft(_message));
    _ui.onSend.listen((MouseEvent _) async => await _send(_message));

    _uiMessageArchive.onMessageCopy.listen((model.Message msg) {
      /**
       * Hack alert!
       * For some odd reason we're forced to wrap the _activateMe() call in a
       * Future, else the HTML textarea will not focus. I've no idea why.
       */
      new Future(() {
        _activateMe();

        _ui.message = msg;
      });
    });
  }

  /**
   * Render the widget with [Contact].
   */
  void _render(model.BaseContact contact, model.ReceptionAttributes attr) {
    _ui.headerExtra = contact.name.isEmpty ? '' : ': ${contact.name}';

    if (attr.isEmpty) {
      _ui.resetOnEmptyContact();
    } else {
      _ui.recipients = attr.endpoints.toSet();
      _ui.messagePrerequisites = attr.messagePrerequisites;
    }
  }

  /**
   * Send message. This entails first saving and then enqueueing the message.
   */
  Future _send(model.Message message) async {
    try {
      model.Message savedMessage = await _messageController.save(message);
      model.MessageQueueEntry response =
          await _messageController.enqueue(savedMessage);

      _ui.reset();
      _ui.focusOnCurrentFocusElement();

      _log.info('Message id ${response.message.id} successfully enqueued');
      _popup.success(_langMap[Key.messageSaveSendSuccessTitle],
          'ID ${response.message.id}');
    } catch (error) {
      _log.shout('Could not save/enqueue ${message.toJson()} $error');
      _popup.error(_langMap[Key.messageSaveSendErrorTitle], 'ID ${message.id}');
    }
  }
}
