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
 * Provides methods to manipulate and extract data from the widget UX parts.
 */
class UIMessageCompose extends UIModel {
  HtmlElement _myFirstTabElement;
  HtmlElement _myFocusElement;
  HtmlElement _myLastTabElement;
  final DivElement _myRoot;

  /**
   * Constructor.
   */
  UIMessageCompose(DivElement this._myRoot) {
    _myFocusElement = _callerNameInput;
    _myFirstTabElement = _callerNameInput;
    _myLastTabElement = _urgentInput;

    _pleaseCallInput.checked = true;

    _setupLocalKeys();
    _observers();
  }

  @override
  HtmlElement get _firstTabElement => _myFirstTabElement;
  @override
  HtmlElement get _focusElement => _myFocusElement;
  @override
  HtmlElement get _lastTabElement => _myLastTabElement;
  @override
  HtmlElement get _root => _myRoot;

  InputElement get _callerNameInput =>
      _root.querySelector('.names input.caller');
  InputElement get _callsBackInput =>
      _root.querySelector('.checks .calls-back');
  InputElement get _cellphoneInput =>
      _root.querySelector('.phone-numbers input.cell');
  InputElement get _companyNameInput =>
      _root.querySelector('.names input.company');
  ButtonElement get draftButton => _root.querySelector('.buttons .draft');
  InputElement get _extensionInput =>
      _root.querySelector('.phone-numbers input.extension');
  InputElement get _haveCalledInput =>
      _root.querySelector('.checks .have-called');
  InputElement get _landlineInput =>
      _root.querySelector('.phone-numbers input.landline');
  TextAreaElement get _messageTextarea =>
      _root.querySelector('.message textarea');
  InputElement get _pleaseCallInput =>
      _root.querySelector('.checks .please-call');
  DivElement get _prerequisites => _root.querySelector('.prerequisites');
  DivElement get _recipientsDiv => _root.querySelector('.recipients');
  OListElement get _recipientsList =>
      _root.querySelector('.recipients .generic-widget-list');
  ButtonElement get sendButton => _root.querySelector('.buttons .send');
  SpanElement get _showRecipientsSpan =>
      _root.querySelector('.show-recipients');
  SpanElement get _showRecipientsText =>
      _showRecipientsSpan.querySelector(':first-child');
  SpanElement get _showNoRecipientsText =>
      _showRecipientsSpan.querySelector(':last-child');
  ElementList<Element> get _tabElements => _root.querySelectorAll('[tabindex]');
  InputElement get _urgentInput => _root.querySelector('.checks .urgent');

  /**
   * If a valid input field detects a mouse click, focus it. Valid input fields
   * are those that are part of the [_tabElements] list.
   */
  void _focusFromClick(MouseEvent event) {
    if (_tabElements.contains(event.target) || (event.target is LabelElement)) {
      (event.target as HtmlElement).focus();
    } else {
      event.preventDefault();
    }
  }

  /**
   * Focus the message text area.
   */
  void focusMessageTextArea() {
    _messageTextarea.focus();
  }

  /**
   * Focus the message text area.
   */
  void focusCallerNameInput() {
    _callerNameInput.focus();
  }

  /**
   * Sets focus on whichever widget element is currently considered the widget
   * default.
   */
  void focusOnCurrentFocusElement() {
    _focusElement.focus();
  }

  /**
   * Extracts a ORModel.Message from the information stored in the widget.
   *
   * This does NOT set the 'context' field.
   */
  model.Message get message {
    final model.CallerInfo callerInfo = new model.CallerInfo.empty()
      ..cellPhone = _cellphoneInput.value.trim()
      ..company = _companyNameInput.value.trim()
      ..localExtension = _extensionInput.value.trim()
      ..name = _callerNameInput.value.trim()
      ..phone = _landlineInput.value.trim();
    final model.MessageFlag messageFlag = new model.MessageFlag.empty()
      ..called = _haveCalledInput.checked
      ..pleaseCall = _pleaseCallInput.checked
      ..urgent = _urgentInput.checked
      ..willCallBack = _callsBackInput.checked;

    return new model.Message.empty()
      ..body = _messageTextarea.value.trim()
      ..callerInfo = callerInfo
      ..flag = messageFlag
      ..recipients = recipients;
  }

  /**
   * Populate widget fields with [message].
   */
  set message(model.Message message) {
    _callerNameInput.value = message.callerInfo.name;
    _companyNameInput.value = message.callerInfo.company;
    _landlineInput.value = message.callerInfo.phone;
    _cellphoneInput.value = message.callerInfo.cellPhone;
    _extensionInput.value = message.callerInfo.localExtension;
    _messageTextarea.value = message.body;
    _haveCalledInput.checked = message.flag.called;
    _pleaseCallInput.checked = message.flag.pleaseCall;
    _callsBackInput.checked = message.flag.willCallBack;
    _urgentInput.checked = message.flag.urgent;

    _toggleButtons();
  }

  /**
   * Set the message prerequisites for the current contact.
   *
   * Ignores whitespace only elements.
   */
  set messagePrerequisites(List<String> prerequisites) {
    _prerequisites.children.clear();
    prerequisites.removeWhere((String prereg) => prereg.trim().isEmpty);

    if (prerequisites.isEmpty) {
      _prerequisites.style.display = 'none';
    } else {
      final List<SpanElement> spans = prerequisites
          .map((String s) => new SpanElement()
            ..text = s.replaceAll('!', '').replaceAll('--', '')
            ..classes.addAll(s.startsWith('!') ? ['is-prerequisite'] : [])
            ..dataset['prerequisite'] = s.startsWith('!')
                ? s.split('--').first.replaceAll('!', '').trim()
                : '')
          .toList(growable: false);

      int counter = 0;
      while (counter < spans.length) {
        _prerequisites.children.add(spans[counter]);
        if (spans.length - counter > 1) {
          _prerequisites.children.add(new SpanElement()
            ..text = '|'
            ..classes.add('prerequisites_separator'));
        }
        counter++;
      }

      _prerequisites.style.display = 'block';
    }
  }

  /**
   * Return true if message body, name, company, phone and cellphone are empty.
   * False otherwise.
   */
  bool get noMessage =>
      message.body.trim().isEmpty &&
      message.callerInfo.name.trim().isEmpty &&
      message.callerInfo.company.trim().isEmpty &&
      message.callerInfo.phone.trim().isEmpty &&
      message.callerInfo.cellPhone.trim().isEmpty;

  /**
   * Observers.
   */
  void _observers() {
    _root.onKeyDown.listen(_keyboard.press);

    _root.onMouseDown.listen(_focusFromClick);

    _hotKeys.onCtrlEsc.listen((KeyboardEvent _) {
      reset(pristine: true);
      if (isFocused) {
        _callerNameInput.focus();
      } else {
        _myFocusElement = _callerNameInput;
      }
    });

    _hotKeys.onAltSpace.listen((_) {
      _transferPrerequisitesToMessageBody();
    });

    _prerequisites.onDoubleClick.listen((_) {
      _transferPrerequisitesToMessageBody();
    });

    /// Flash alert if user is trying to pickup a new call while there is data
    /// in the message compose widget.
    _hotKeys.onNumPlus.listen((_) {
      if (!noMessage && !_root.classes.contains('message-compose-alert')) {
        _root.classes.toggle('message-compose-alert', true);
        new Future.delayed(new Duration(seconds: 2), () {
          _root.classes.toggle('message-compose-alert', false);
        });
      }
      _root.classes.toggle('message-compose-alert', !noMessage);
    });

    _hotKeys.onCtrlSpace.listen((_) => _toggleRecipients());

    /// Enables focused element memory for this widget.
    _tabElements.forEach((Element element) {
      element.onFocus.listen(
          (Event event) => _myFocusElement = (event.target as HtmlElement));
    });

    _showRecipientsSpan.onClick.listen((MouseEvent _) => _toggleRecipients());

    _callerNameInput.onInput.listen((Event _) => _toggleButtons());
    _messageTextarea.onInput.listen((Event _) => _toggleButtons());
  }

  /**
   * Return the click event stream for the draft button.
   */
  Stream<MouseEvent> get onDraft => draftButton.onClick;

  /**
   * Return the click event stream for the send button.
   */
  Stream<MouseEvent> get onSend => sendButton.onClick;

  /**
   * Return the Set of [model.MessageEndpoint]. May return the empty set.
   */
  Set<model.MessageEndpoint> get recipients {
    final String recipientsList = _recipientsList.dataset['recipients-list'];

    if (recipientsList != null && recipientsList.isNotEmpty) {
      return new Set<model.MessageEndpoint>.from(json
          .decode(recipientsList)
          .map((Map<String, dynamic> map) =>
              new model.MessageEndpoint.fromJson(map)));
    } else {
      return new Set<model.MessageEndpoint>();
    }
  }

  /**
   * Add [recipients] to the recipients list.
   */
  set recipients(Set<model.MessageEndpoint> recipients) {
    _showRecipientsText.hidden = true;
    _showNoRecipientsText.hidden = true;

    String contactString(model.MessageEndpoint recipient) =>
        '${recipient.name} (${recipient.address})';

    Iterable<model.MessageEndpoint> toRecipients() =>
        recipients.where((model.MessageEndpoint r) =>
            r.type == model.MessageEndpointType.emailTo);

    Iterable<model.MessageEndpoint> ccRecipients() =>
        recipients.where((model.MessageEndpoint r) =>
            r.type == model.MessageEndpointType.emailCc);

    Iterable<model.MessageEndpoint> bccRecipients() =>
        recipients.where((model.MessageEndpoint r) =>
            r.type == model.MessageEndpointType.emailBcc);

    List<LIElement> list = new List<LIElement>();

    Iterable maps = recipients.map((model.MessageEndpoint r) => r.toJson());
    _recipientsList.dataset['recipients-list'] = json.encode(maps.toList());

    toRecipients().forEach((model.MessageEndpoint recipient) {
      list.add(new LIElement()..text = contactString(recipient));
    });

    ccRecipients().forEach((model.MessageEndpoint recipient) {
      list.add(new LIElement()
        ..text = contactString(recipient)
        ..classes.add('cc'));
    });

    bccRecipients().forEach((model.MessageEndpoint recipient) {
      list.add(new LIElement()
        ..text = contactString(recipient)
        ..classes.add('bcc'));
    });

    _recipientsList.children = list;

    _showRecipientsText.hidden = list.isEmpty;
    _showNoRecipientsText.hidden = list.isNotEmpty;

    _toggleButtons();
  }

  /**
   * Reset the widget fields to their pristine state and registers
   * [_callerNameInput] as the field that will get focus on next navigate.
   *
   * By default this maintains the recipient list of the currently selected
   * contact.
   *
   * If [pristine] is true, then also clear and close the recipient list.
   */
  void reset({pristine: false}) {
    _root.classes.remove('message-compose-alert');
    _callerNameInput.value = '';
    _callsBackInput.checked = false;
    _cellphoneInput.value = '';
    _companyNameInput.value = '';
    _extensionInput.value = '';
    _haveCalledInput.checked = false;
    _landlineInput.value = '';
    _messageTextarea.value = '';
    messagePrerequisites = [];
    _pleaseCallInput.checked = true;
    _urgentInput.checked = false;

    _myFocusElement = _callerNameInput;
    _myFirstTabElement = _callerNameInput;
    _myLastTabElement = _urgentInput;

    _toggleButtons();

    if (pristine) {
      _recipientsList.dataset['recipients-list'] = '';
      _recipientsList.children.clear();
      _recipientsDiv.classes.toggle('recipients-hidden', true);
      _showRecipientsSpan.classes.toggle('active', false);
      _showRecipientsText.hidden = true;
      _showNoRecipientsText.hidden = false;
    }
  }

  /**
   * Reset the recipients list and toggle buttons when receiving and empty
   * contact.
   */
  void resetOnEmptyContact() {
    messagePrerequisites = [];
    _recipientsList.dataset['recipients-list'] = '';
    _recipientsList.children.clear();
    _recipientsDiv.classes.toggle('recipients-hidden', true);
    _showRecipientsSpan.classes.toggle('active', false);
    _showRecipientsText.hidden = true;
    _showNoRecipientsText.hidden = false;

    _toggleButtons();
  }

  /**
   * Setup keys and bindings to methods specific for this widget.
   */
  void _setupLocalKeys() {
    final Map<String, EventListener> bindings = {
      'Ctrl+enter': (Event _) => sendButton.click(),
      'Ctrl+s': (Event _) => draftButton.click()
    };

    _hotKeys.registerKeysPreventDefault(_keyboard, bindings);
    _hotKeys.registerKeys(_keyboard, _defaultKeyMap());
  }

  /**
   * Enable/disable the widget buttons and as a sideeffect set the value of
   * [_myLastTabElement] as this depends on the state of the buttons.
   */
  void _toggleButtons() {
    final bool toggle = !(_callerNameInput.value.trim().isNotEmpty &&
        _messageTextarea.value.trim().isNotEmpty);

    draftButton.disabled = toggle || _recipientsList.children.isEmpty;
    sendButton.disabled = toggle || _recipientsList.children.isEmpty;

    _myLastTabElement = toggle ? _urgentInput : sendButton;
  }

  /**
   * Show/hide the recipients list.
   */
  void _toggleRecipients() {
    _recipientsDiv.classes.toggle('recipients-hidden');
    _showRecipientsSpan.classes.toggle('active');
  }

  /**
   * Dump the message prerequisites into the message body text area.
   */
  void _transferPrerequisitesToMessageBody() {
    if (isFocused) {
      final StringBuffer sb = new StringBuffer();
      final List<SpanElement> spans = _prerequisites
          .querySelectorAll('span.is-prerequisite')
          .toList(growable: false);

      for (SpanElement span in spans) {
        sb.write('\n${span.dataset['prerequisite']}: ');
      }

      if (sb.isNotEmpty) {
        _messageTextarea.value =
            (_messageTextarea.value + sb.toString()).trimLeft();
      }
    }
  }
}
