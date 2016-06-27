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
 * The message archive list.
 */
class MessageArchive extends ViewWidget {
  Map<String, DateTime> _lastFetchedCache = new Map<String, DateTime>();
  final Model.UIContactSelector _contactSelector;
  ORModel.MessageContext _context;
  final Map<String, String> _langMap;
  DateTime _lastFetched;
  final Logger _log = new Logger('$libraryName.MessageArchive');
  final Controller.Message _messageController;
  final Model.UIMessageCompose _messageCompose;
  final Controller.Destination _myDestination;
  final Controller.Popup _popup;
  final Model.UIReceptionSelector _receptionSelector;
  final Model.UIMessageArchive _uiModel;
  final Controller.User _user;

  /**
   * Constructor.
   */
  MessageArchive(
      Model.UIMessageArchive this._uiModel,
      Controller.Destination this._myDestination,
      Controller.Message this._messageController,
      Controller.User this._user,
      Model.UIContactSelector this._contactSelector,
      Model.UIReceptionSelector this._receptionSelector,
      Model.UIMessageCompose this._messageCompose,
      Controller.Popup this._popup,
      Map<String, String> this._langMap) {
    _observers();
  }

  @override
  Controller.Destination get _destination => _myDestination;
  @override
  Model.UIMessageArchive get _ui => _uiModel;

  @override
  void _onBlur(Controller.Destination _) {
    _ui.hideYesNoBoxes();
    _ui.hideTables();
  }

  @override
  void _onFocus(Controller.Destination _) {
    _lastFetched = new DateTime.now();

    _context = new ORModel.MessageContext.empty()
      ..cid = _contactSelector.selectedContact.contact.id
      ..contactName = _contactSelector.selectedContact.contact.name
      ..rid = _receptionSelector.selectedReception.id
      ..receptionName = _receptionSelector.selectedReception.name;

    _ui.currentContext = _context;

    if (_context.rid == ORModel.Reception.noId) {
      _ui.headerExtra = '';
    } else if (_context.cid == ORModel.BaseContact.noId) {
      _ui.headerExtra = '(${_receptionSelector.selectedReception.name})';
    } else {
      _ui.headerExtra =
          '(${_contactSelector.selectedContact.contact.name} @ ${_receptionSelector.selectedReception.name})';
    }

    _user.list().then((Iterable<ORModel.UserReference> users) {
      _ui.users = users;

      _messageController
          .listDrafts()
          .then((Iterable<ORModel.Message> messages) {
        final List<ORModel.Message> list = messages.toList(growable: false);
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _ui.drafts = list;
      });

      if (_lastFetchedCache[_ui.currentContext.contactString] != null) {
        _lastFetched = _lastFetchedCache[_ui.currentContext.contactString];
      } else {
        _loadMoreMessages();
      }
    });
  }

  /**
   * Simply navigate to my [_myDestination].
   */
  void _activateMe(MouseEvent event) {
    if (!_ui.isFocused && event.target is! ButtonElement) {
      _navigateToMyDestination();
    }
  }

  /**
   * Close [message] and update the UI.
   */
  dynamic _closeMessage(ORModel.Message message) async {
    try {
      message.recipients = new Set();
      message.state = ORModel.MessageState.closed;

      ORModel.Message savedMessage = await _messageController.save(message);

      _ui.moveMessage(savedMessage);

      _popup.success(
          _langMap[Key.messageCloseSuccessTitle], 'ID ${message.id}');
    } catch (error) {
      _log.shout('Could not close ${message.asMap} $error');
      _popup.error(_langMap[Key.messageCloseErrorTitle], 'ID ${message.id}');
    }
  }

  /**
   * Delete [message] and update the UI.
   */
  dynamic _deleteMessage(ORModel.Message message) async {
    try {
      await _messageController.remove(message.id);

      _ui.removeMessage(message);

      _log.info('Message id ${message.id} successfully deleted');
      _popup.success(
          _langMap[Key.messageDeleteSuccessTitle], 'ID ${message.id}');
    } catch (error) {
      _log.shout('Could not delete ${message.asMap} $error');
      _popup.error(_langMap[Key.messageDeleteErrorTitle], 'ID ${message.id}');
    }
  }

  /**
   * Load more messages.
   *
   * This will never look more than 7 days back, and it will stop as soon as
   * more than 50 messages have been found.
   *
   * Ignores drafts.
   */
  Future _loadMoreMessages() async {
    if (!_ui.loading &&
        _context.cid != ORModel.BaseContact.noId &&
        _context.rid != ORModel.Reception.noId) {
      int counter = 0;
      final ORModel.MessageFilter filter = new ORModel.MessageFilter.empty()
        ..contactId = _contactSelector.selectedContact.contact.id
        ..receptionId = _receptionSelector.selectedReception.id;
      final List<ORModel.Message> messages = new List<ORModel.Message>();

      _ui.loading = true;

      while (counter < 7 && messages.length < 50) {
        final List<ORModel.Message> list =
            (await _messageController.list(_lastFetched))
                .where((ORModel.Message msg) =>
                    filter.appliesTo(msg) && !msg.isDraft ||
                    (msg.isDraft && msg.isClosed))
                .toList();

        if (list.isNotEmpty) {
          messages.addAll(list);
        } else {
          final ORModel.Message emptyMessage = new ORModel.Message.empty()
            ..createdAt = _lastFetched;
          list.add(emptyMessage);
          messages.add(emptyMessage);
        }

        _lastFetched = _lastFetched.subtract(new Duration(days: 1));

        _lastFetchedCache[_ui.currentContext.contactString] = _lastFetched;

        counter++;
      }

      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _ui.setMessages(messages, addToExisting: true);

      _ui.loading = false;
    }
  }

  /**
   * Observers.
   */
  void _observers() {
    _navigate.onGo.listen(_setWidgetState);

    _messageCompose.onDraft.listen((MouseEvent _) {
      _ui.headerExtra = '';
      _ui.cacheClear();
      _lastFetchedCache.clear();
    });
    _messageCompose.onSend.listen((MouseEvent _) {
      _ui.headerExtra = '';
      _ui.cacheClear();
      _lastFetchedCache.clear();
    });

    _receptionSelector.onSelect.listen((_) {
      _ui.cacheClear();
      _lastFetchedCache.clear();
      if (_ui.isFocused) {
        _navigate.goHome();
      }
    });

    _ui.onClick.listen(_activateMe);

    _ui.onLoadMoreMessages.listen((_) {
      _loadMoreMessages();
    });

    /// We don't need to listen on the onMessageCopy stream here. It is handled
    /// in MessageCompose.
    _ui.onMessageClose.listen(_closeMessage);
    _ui.onMessageDelete.listen(_deleteMessage);
    _ui.onMessageSend.listen(_sendMessage);
  }

  /**
   * Queue/send [message] and update the UI.
   */
  dynamic _sendMessage(ORModel.Message message) async {
    try {
      ORModel.Message savedMessage = await _messageController.save(message);
      ORModel.MessageQueueEntry response =
          await _messageController.enqueue(savedMessage);

      _ui.moveMessage(savedMessage);

      _log.info('Message id ${response.message.id} successfully enqueued');
      _popup.success(_langMap[Key.messageSaveSendSuccessTitle],
          'ID ${response.message.id}');
    } catch (error) {
      _log.shout('Could not save/enqueue ${message.asMap} $error');
      _popup.error(_langMap[Key.messageSaveSendErrorTitle], 'ID ${message.id}');
    }
  }
}
