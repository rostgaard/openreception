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

part of orc.model;

/**
 * Provides access to the MessageArchive UX components.
 */
class UIMessageArchive extends UIModel {
  model.MessageContext _currentContext = new model.MessageContext.empty();
  final Map<String, String> _langMap;
  final Bus<model.Message> _messageCloseBus = new Bus<model.Message>();
  final Bus<model.Message> _messageCopyBus = new Bus<model.Message>();
  final Bus<model.Message> _messageDeleteBus = new Bus<model.Message>();
  final Bus<model.Message> _messageSendBus = new Bus<model.Message>();
  final DivElement _myRoot;
  Map<int, String> _users = new Map<int, String>();
  final util.WeekDays _weekDays;

  TableElement _messagesTable;

  /**
   * Constructor.
   */
  UIMessageArchive(
      DivElement this._myRoot, util.WeekDays this._weekDays, this._langMap) {
    _setupLocalKeys();
    _observers();
  }

  @override
  HtmlElement get _firstTabElement => _body;
  @override
  HtmlElement get _focusElement => _tableContainer;
  @override
  HtmlElement get _lastTabElement => _body;
  @override
  HtmlElement get _root => _myRoot;

  DivElement get _archiveTableContainer =>
      _tableContainer.querySelector('.message-archive-tables') as DivElement;
  DivElement get _body => _root.querySelector('.generic-widget-body') as DivElement;
  String get header => _root.querySelector('h4 span.extra-header').text;
  ButtonElement get _loadMoreButton =>
      _body.querySelector('button.messages-load-more') as ButtonElement;
  TableSectionElement get _draftsTbody =>
      _tableContainer.querySelector('tbody.drafts-messages-tbody') as TableSectionElement;
  DivElement get _tableContainer => _body.querySelector('div') as DivElement;

  /**
   * Return an archive table element, with headers.
   */
  TableElement _archiveTable() => new TableElement()
    ..children.addAll([
      new Element.tag('thead')
        ..children.add(new TableRowElement()
          ..children.addAll([
            new TableCellElement()..text = _langMap[Key.date],
            new TableCellElement()..text = _langMap[Key.agent],
            new TableCellElement()..text = _langMap[Key.name],
            new TableCellElement()..text = _langMap[Key.company],
            new TableCellElement()..text = _langMap[Key.phone],
            new TableCellElement()..text = _langMap[Key.cellPhone],
            new TableCellElement()..text = _langMap[Key.extension],
            new TableCellElement()..text = _langMap[Key.message],
            new TableCellElement()..text = _langMap[Key.status],
            new TableCellElement()..text = _langMap[Key.actions]
          ])),
      new Element.tag('tbody')..classes.addAll(['messages-tbody', 'zebra'])
    ]);

  /**
   * Construct the send | delete | copy | close <td> cell.
   */
  TableCellElement _buildActionsCell(model.Message message) {
    final DivElement actionsContainer = new DivElement()
      ..classes.add('actions-container');
    final DivElement buttonBox = new DivElement()..classes.add('button-box');
    final TableCellElement cell = new TableCellElement()
      ..classes.add('actions');
    final DivElement yesNoBox = new DivElement()..classes.add('yes-no-box');

    buttonBox.children.addAll([
      new ImageElement()
        ..src = 'images/copy.svg'
        ..title = _langMap['copy'].toLowerCase()
        ..onClick.listen(
            (_) => _yesNo(buttonBox, yesNoBox, message, _messageCopyBus)),
      new ImageElement()
        ..src = 'images/send.svg'
        ..title = _langMap['send'].toLowerCase()
        ..style.visibility = message.isDraft ? 'visible' : 'hidden'
        ..onClick.listen(
            (_) => _yesNo(buttonBox, yesNoBox, message, _messageSendBus)),
      new ImageElement()
        ..src = 'images/bin.svg'
        ..title = _langMap['delete'].toLowerCase()
        ..style.visibility = message.isDraft ? 'visible' : 'hidden'
        ..onClick.listen(
            (_) => _yesNo(buttonBox, yesNoBox, message, _messageDeleteBus)),
      new ImageElement()
        ..src = 'images/close.svg'
        ..title = _langMap['close'].toLowerCase()
        ..style.visibility = message.isDraft ? 'visible' : 'hidden'
        ..onClick.listen(
            (_) => _yesNo(buttonBox, yesNoBox, message, _messageCloseBus))
    ]);

    actionsContainer.children.addAll([buttonBox, yesNoBox]);

    cell.children.add(actionsContainer);
    return cell;
  }

  /**
   * Construct a <tr> element from [message]. The only data used from [message]
   * is the createAt DateTime.
   *
   * The resulting row is empty, except for the date column.
   */
  TableRowElement _buildEmptyRow(model.Message message) {
    String date() {
      final DateTime now = new DateTime.now();
      final StringBuffer sb = new StringBuffer();

      final String day = new DateFormat.d().format(message.createdAt);
      final String month = new DateFormat.M().format(message.createdAt);
      final String year = new DateFormat.y().format(message.createdAt);

      sb.write('${_weekDays.name(message.createdAt.weekday)} $day/$month');

      if (message.createdAt.year != now.year) {
        sb.write('/${year.substring(2)}');
      }

      return sb.toString();
    }

    TableCellElement emptyCell() => new TableCellElement()
      ..text = '-'
      ..style.textAlign = 'center';

    final TableRowElement row = new TableRowElement();
    row.children.addAll([
      new TableCellElement()..text = date(),
      emptyCell(),
      emptyCell(),
      emptyCell(),
      emptyCell(),
      emptyCell(),
      emptyCell(),
      emptyCell(),
      emptyCell(),
      emptyCell(),
    ]);

    return row;
  }

  /**
   * Construct the message <td> cell.
   */
  TableCellElement _buildMessageCell(model.Message msg) {
    final DivElement div = new DivElement()
      ..classes.add('slim')
      ..appendHtml(msg.body.replaceAll("\n", '<br>'));
    div.onClick.listen((MouseEvent _) => div.classes.toggle('slim'));

    return new TableCellElement()
      ..classes.add('message-cell')
      ..children.add(div);
  }

  /**
   * Construct a <tr> element from [message]
   *
   * If [isDraft] is true then output the recipient contact and reception name
   * columns.
   */
  TableRowElement _buildRow(model.Message message, bool isDraft) {
    final TableRowElement row = new TableRowElement()
      ..dataset['message-id'] = message.id.toString()
      ..dataset['message-date'] = message.createdAt.toString()
      ..dataset['contact-string'] = message.context.contactString;

    row.children.add(new TableCellElement()
      ..text = util.humanReadableTimestamp(message.createdAt, _weekDays));

    if (isDraft) {
      row.children.addAll([
        new TableCellElement()..text = message.context.contactName,
        new TableCellElement()..text = message.context.receptionName,
      ]);
    }

    row.children.addAll([
      new TableCellElement()
        ..text = _users[message.sender.id] ?? message.sender.id.toString(),
      new TableCellElement()..text = message.callerInfo.name,
      new TableCellElement()..text = message.callerInfo.company,
      new TableCellElement()..text = message.callerInfo.phone,
      new TableCellElement()..text = message.callerInfo.cellPhone,
      new TableCellElement()..text = message.callerInfo.localExtension,
      _buildMessageCell(message),
      _buildStatusCell(message, isDraft),
      _buildActionsCell(message)
    ]);

    return row;
  }

  /**
   * Build the status column for those
   */
  TableCellElement _buildStatusCell(model.Message message, bool isDraft) {
    final TableCellElement td = new TableCellElement()
      ..classes.add('td-center')
      ..text = _getStatus(message);

    if (isDraft) {
      td.classes.add('drafts-alert');
    }

    return td;
  }

  /**
   * Remove all the message archive tables.
   */
  void cacheClear() {
    _archiveTableContainer.children.clear();
    _archiveTableContainer.dataset['rid'] = '';
  }

  /**
   * Remove all data from the body and clear the header.
   */
  void clear() {
    _headerExtra.text = '';
    _body.text = '';
  }

  /**
   * Set the current message context. If the context contains an empty reception
   * then disable and hide the loadmore button.
   */
  set currentContext(model.MessageContext context) {
    final bool emptyReception = context.rid == model.Reception.noId;
    final bool emptyContact = context.cid == model.BaseContact.noId;
    final String rid = _archiveTableContainer.dataset['rid'];

    if (emptyReception || emptyContact) {
      _archiveTableContainer.children.clear();
      _archiveTableContainer.dataset['rid'] = '';
    } else {
      _messagesTable = _archiveTableContainer
          .querySelector('[data-contact="${context.contactString}"]') as TableElement;

      if (_messagesTable == null) {
        _messagesTable = _archiveTable();
        _messagesTable.dataset['contact'] = context.contactString;
        _archiveTableContainer.children.add(_messagesTable);
      }

      _messagesTable.hidden = false;

      if (rid == null || rid.isEmpty || rid == context.rid.toString()) {
        _archiveTableContainer.dataset['rid'] = context.rid.toString();
      } else {}
    }

    _currentContext = context;

    _loadMoreButton.disabled = emptyReception || emptyContact;
    _loadMoreButton.style.display =
        emptyReception || emptyContact ? 'none' : 'block';
  }

  /**
   * Return the current message context.
   */
  model.MessageContext get currentContext => _currentContext;

  /**
   * Add the [list] of [model.Message] to the widgets "drafts messages" table.
   */
  set drafts(Iterable<model.Message> list) {
    final List<TableRowElement> rows = new List<TableRowElement>();
    _draftsTbody.children.clear();

    list.forEach((model.Message msg) {
      rows.add(_buildRow(msg, true));
    });

    _draftsTbody.children.addAll(rows);
    _draftsTbody.parent.hidden = _draftsTbody.children.isEmpty;
  }

  /**
   * Return the String status of [msg].
   */
  String _getStatus(model.Message msg) {
    if (msg.isClosed) {
      return _langMap[Key.closed].toUpperCase();
    }

    if (msg.isDraft) {
      return _langMap[Key.draft].toUpperCase();
    }

    if (msg.isSent) {
      return _langMap[Key.sent].toUpperCase();
    }

    return _langMap[Key.unknown].toUpperCase();
  }

  /**
   * Hide all the message archive tables.
   */
  void hideTables() {
    _archiveTableContainer.querySelectorAll('table').forEach((Element table) {
      table.hidden = true;
    });
  }

  /**
   * Get rid of all the Yes/No confirmation boxes.
   */
  void hideYesNoBoxes() {
    _body.querySelectorAll('.yes-no-box').forEach((Element yesNoBox) {
      yesNoBox.style.display = 'none';
      yesNoBox.children.clear();
      yesNoBox.previousElementSibling.style.display = 'flex';
    });
  }

  /**
   * Disable the "load more messages" button.
   */
  set loading(bool isLoading) {
    _loadMoreButton
      ..disabled = isLoading
      ..classes.toggle('loading', isLoading);
    _loadMoreButton.text = isLoading
        ? _langMap[Key.messagesLoading]
        : _langMap[Key.messagesLoadMore];
  }

  /**
   * Return true if we're in the process of loading messages.
   */
  bool get loading => _loadMoreButton.disabled;

  /**
   * Move the [message] from the drafts list to the messages list and update the
   * actions cell according to the state of the [message]. [message] is ALWAYS
   * moved to the top of the messages list to make it clear that the move has
   * happened.
   *
   * NOTE: This is a visual only action. It does not perform any actions on the
   * server.
   */
  void moveMessage(model.Message message) {
    final TableRowElement tr =
        _draftsTbody.querySelector('[data-message-id="${message.id}"]') as TableRowElement;

    if (tr != null) {
      tr.classes.add('fade-out');
      tr.onTransitionEnd.listen((TransitionEvent event) {
        if (event.propertyName == 'opacity') {
          tr.remove();
          _draftsTbody.parent.hidden = _draftsTbody.children.isEmpty;
          if (currentContext == message.context) {
            TableSectionElement _messagesTbody =
                _messagesTable.querySelector('tbody.messages-tbody') as TableSectionElement;
            _messagesTbody.insertBefore(
                _buildRow(message, false), _messagesTbody.firstChild);
          }
        }
      });
    }
  }

  /**
   * Observers.
   */
  void _observers() {
    _root.onKeyDown.listen(_keyboard.press);
    _root.onClick.listen((_) => _tableContainer.focus());
  }

  /**
   * The click event stream for the load more messages button.
   */
  Stream<MouseEvent> get onLoadMoreMessages => _loadMoreButton.onClick;

  /**
   * Fire a [model.Message] when closing it.
   */
  Stream<model.Message> get onMessageClose => _messageCloseBus.stream;

  /**
   * Fire a [model.Message] when copying it.
   */
  Stream<model.Message> get onMessageCopy => _messageCopyBus.stream;

  /**
   * Fire a [model.Message] when deleting it.
   */
  Stream<model.Message> get onMessageDelete => _messageDeleteBus.stream;

  /**
   * Fire a [model.Message] when sending it.
   */
  Stream<model.Message> get onMessageSend => _messageSendBus.stream;

  /**
   * Removes a draft [message] from the list.
   *
   * NOTE: This is a visual only action. It does not perform any actions on the
   * server.
   */
  void removeMessage(model.Message message) {
    TableRowElement tr =
        _root.querySelector('table [data-message-id="${message.id}"]') as TableRowElement;

    if (tr != null) {
      tr.classes.add('fade-out');
      tr.onTransitionEnd.listen((TransitionEvent event) {
        if (event.propertyName == 'opacity') {
          tr.remove();
          _draftsTbody.parent.hidden = _draftsTbody.children.isEmpty;
        }
      });
    }
  }

  /**
   * Add the [list] of [model.Message] to the widgets messages table.
   *
   * If [addToExisting] is true, the [list] is appended to the table, else the
   * table is cleared and [list] is set as its sole content.
   */
  void setMessages(Iterable<model.Message> list, {bool addToExisting: false}) {
    TableSectionElement _messagesTbody =
        _messagesTable.querySelector('tbody.messages-tbody') as TableSectionElement;
    final List<TableRowElement> rows = new List<TableRowElement>();

    list.forEach((model.Message msg) {
      if (msg.id != model.Message.noId) {
        rows.add(_buildRow(msg, false));
      } else {
        rows.add(_buildEmptyRow(msg));
      }
    });

    if (addToExisting) {
      _messagesTbody.children.addAll(rows);
    } else {
      _messagesTbody.children = rows;
    }

    _messagesTbody.parent.hidden = _messagesTbody.children.isEmpty;
  }

  /**
   * Setup keys and bindings to methods specific for this widget.
   */
  void _setupLocalKeys() {
    _hotKeys.registerKeysPreventDefault(_keyboard, _defaultKeyMap());
  }

  /**
   * Set the list of users. This is used to map the users id of a message to
   * the users name.
   */
  set users(Iterable<model.UserReference> list) {
    list.forEach((model.UserReference user) {
      _users[user.id] = user.name;
    });
  }

  /**
   * Setup the yes|no action confirmation box.
   */
  void _yesNo(DivElement actionBox, DivElement yesNoBox, model.Message message,
      Bus bus) {
    yesNoBox.children.addAll([
      new SpanElement()
        ..text = _langMap[Key.yes]
        ..onClick.listen((_) {
          bus.fire(message);
        }),
      new SpanElement()
        ..text = _langMap[Key.no]
        ..onClick.listen((_) {
          yesNoBox.style.display = 'none';
          yesNoBox.children.clear();
          actionBox.style.display = 'flex';
        })
    ]);

    yesNoBox.style.width = '${actionBox.borderEdge.width.toString()}px';
    actionBox.style.display = 'none';
    yesNoBox.style.display = 'flex';
  }
}
