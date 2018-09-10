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
 * Provides methods for manipulating the contact data UI widget.
 */
class UIContactData extends UIModel {
  final Bus<model.PhoneNumber> _busRinging = new Bus<model.PhoneNumber>();
  final DivElement _myRoot;

  /**
   * Constructor.
   */
  UIContactData(DivElement this._myRoot) {
    _observers();
  }

  @override
  HtmlElement get _firstTabElement => _root;
  @override
  HtmlElement get _focusElement => _root;
  @override
  HtmlElement get _lastTabElement => _root;
  @override
  HtmlElement get _listTarget => _phoneNumberList;
  @override
  HtmlElement get _root => _myRoot;

  OListElement get _additionalInfoList =>
      _root.querySelector('.additional-info');
  OListElement get _backupsList => _root.querySelector('.backups');
  OListElement get _commandsList => _root.querySelector('.commands');
  OListElement get _departmentList => _root.querySelector('.department');
  OListElement get _emailAddressesList =>
      _root.querySelector('.email-addresses');
  DivElement get _popupDiv => _root.querySelector('.popup');
  InputElement get _pstnInput => _root.querySelector('.popup .pstn');
  OListElement get _relationsList => _root.querySelector('.relations');
  OListElement get _responsibilityList =>
      _root.querySelector('.responsibility');
  SpanElement get _showPSTNSpan => _root.querySelector('.show-pstn');
  SpanElement get _showTagsSpan => _root.querySelector('.show-tags');
  OListElement get _tagsList =>
      _root.querySelector('.popup .generic-widget-list');
  OListElement get _phoneNumberList => _root.querySelector('.telephone-number');
  OListElement get _titleList => _root.querySelector('.title');
  OListElement get _workHoursList => _root.querySelector('.work-hours');

  /**
   * Add [items] to the additional info list.
   */
  set additionalInfo(List<String> items) =>
      _populateList(_additionalInfoList, items);

  /**
   * Add [items] to the backups list.
   */
  set backups(List<String> items) => _populateList(_backupsList, items);

  /**
   * Remove all data from the widget.
   *
   * If removePopup is true, then also remove the PSTN/Tags popup. Else leave
   * it.
   */
  void clear({bool removePopup: false}) {
    _headerExtra.text = '';
    _additionalInfoList.children.clear();
    _backupsList.children.clear();
    _commandsList.children.clear();
    _departmentList.children.clear();
    _emailAddressesList.children.clear();
    _relationsList.children.clear();
    _responsibilityList.children.clear();
    _tagsList.children.clear();
    _pstnInput.value = '';
    _phoneNumberList.children.clear();
    _titleList.children.clear();
    _workHoursList.children.clear();

    if (removePopup) {
      _showPSTNSpan.classes.toggle('active', false);
      _showTagsSpan.classes.toggle('active', false);
      _popupDiv.classes.toggle('popup-hidden', true);
    }
  }

  /**
   * Add [items] ot the commands list.
   */
  set commands(List<String> items) => _populateList(_commandsList, items);

  /**
   * Populate widget with contact data from [cwfc] data and mark tags according
   * to the filter context.
   */
  set contactWithFilterContext(ContactWithFilterContext cwfc) {
    if (cwfc.contact.isNotEmpty) {
      clear();

      headerExtra = ': ${cwfc.contact.name}';
      additionalInfo = cwfc.attr.infos;
      backups = cwfc.attr.backupContacts;
      commands = cwfc.attr.handling;
      departments = cwfc.attr.departments;
      emailAddresses = cwfc.attr.emailaddresses;
      relations = cwfc.attr.relations;
      responsibility = cwfc.attr.responsibilities;
      telephoneNumbers = cwfc.attr.phoneNumbers;
      titles = cwfc.attr.titles;
      workHours = cwfc.attr.workhours;

      if (_showPSTNSpan.classes.contains('active')) {
        _showPSTNSpan.classes.toggle('active', false);
        _popupDiv.classes.toggle('popup-hidden', true);
        _focusElement.focus();
      }
    }

    /// Always set tags, no matter what kind of contact and filter context we
    /// have.
    tags = cwfc;
  }

  /**
   * Add [items] to the departments list.
   */
  set departments(List<String> items) => _populateList(_departmentList, items);

  /**
   * Add [items] to the email addresses list.
   */
  set emailAddresses(List<String> items) =>
      _populateList(_emailAddressesList, items);

  /**
   * Return true if no phonenumbers are marked "ringing".
   */
  bool get noRinging =>
      !_phoneNumberList.children.any((e) => e.classes.contains('ringing'));

  /**
   * Observers
   */
  void _observers() {
    _root.onKeyDown.listen(_keyboard.press);
    _root.onClick.listen(_selectFromClick);

    _hotKeys.onAltArrowDown.listen((_) => _markSelected(
        _scanForwardForVisibleElement(
            _phoneNumberList.querySelector('.selected')?.nextElementSibling)));

    _hotKeys.onAltArrowUp.listen((_) => _markSelected(
        _scanBackwardForVisibleElement(_phoneNumberList
            .querySelector('.selected')
            ?.previousElementSibling)));

    _hotKeys.onCtrlSpace.listen((_) => _togglePopup(_showTagsSpan));

    _showPSTNSpan.onClick
        .listen((MouseEvent event) => _togglePopup(event.target));
    _showTagsSpan.onClick
        .listen((MouseEvent event) => _togglePopup(event.target));
  }

  /**
   * Fires when a [model.PhoneNumber] is marked ringing.
   */
  Stream<model.PhoneNumber> get onMarkedRinging => _busRinging.stream;

  /**
   * Appends each of the [list] elements to [parent]
   */
  void _populateList(OListElement parent, List<String> list) {
    list.forEach((String item) {
      parent.append(new LIElement()..text = item);
    });
  }

  /**
   * Add [items] to the relations list.
   */
  set relations(List<String> items) => _populateList(_relationsList, items);

  /**
   * Removes the ringing effect from whatever element that might currently be
   * marked ringing.
   *
   * Removing the effect is delayed by 500ms for usability reasons.
   */
  void removeRinging() {
    new Future.delayed(new Duration(milliseconds: 500), () {
      final Element elem = _root.querySelector('.ringing');

      if (elem != null) {
        elem.classes.toggle('ringing', false);
      }
    });
  }

  /**
   * Add [items] to the responsibility list.
   */
  set responsibility(List<String> items) =>
      _populateList(_responsibilityList, items);

  /**
   * Mark selected [model.PhoneNumber] ringing if we're not already ringing.
   * If the PSTN input field is active and contains something, then call that.
   *
   * Numbers that start with 0 are illegal to ring from the PSTN field.
   *
   * This fires a [model.PhoneNumber] object on the [onMarkedRinging] stream.
   */
  void ring() {
    if (_showPSTNSpan.classes.contains('active') &&
        _pstnInput.value.trim().isNotEmpty &&
        _headerExtra.text.isNotEmpty &&
        !_pstnInput.value.trim().startsWith('0') &&
        noRinging) {
      model.PhoneNumber phoneNumber = new model.PhoneNumber.empty()
        ..destination = _pstnInput.value.trim();
      _pstnInput.classes.toggle('ringing', true);
      _busRinging.fire(phoneNumber);
    } else if (!_showPSTNSpan.classes.contains('active') && noRinging) {
      LIElement li = _phoneNumberList.querySelector('.selected');

      if (li != null) {
        li.classes.toggle('ringing');
        _busRinging.fire(new model.PhoneNumber.fromJson(
            json.decode(li.dataset['object']) as Map<String, dynamic>));
      }
    }
  }

  /**
   * Select the first [model.PhoneNumber] in the list.
   */
  void selectFirstPhoneNumber() {
    if (_phoneNumberList.children.isNotEmpty) {
      _markSelected(
          _scanForwardForVisibleElement(_phoneNumberList.children.first));
    }
  }

  /**
   * Mark a [LIElement] in the telephone number list selected, if one such is
   * the target of the [event].
   */
  void _selectFromClick(MouseEvent event) {
    if (event.target is LIElement &&
        (event.target as LIElement).parent == _phoneNumberList) {
      _markSelected(event.target);
    }
  }

  /**
   * Extracts and adds tags from [cwfc] to the tags list.
   */
  set tags(ContactWithFilterContext cwfc) {
    final List<String> filterParts = new List<String>()
      ..addAll(cwfc.state == filterState.tag
          ? cwfc.filterValue.split(' ')
          : new List<String>());
    filterParts.removeWhere((String f) => f.trim().length < 2);

    final List<LIElement> foundLis = new List<LIElement>();
    final List<LIElement> lis = new List<LIElement>();

    for (String item in cwfc.attr.tags.toSet()) {
      final LIElement li = new LIElement()..text = item;
      if (cwfc.state == filterState.tag &&
          filterParts
              .every((String part) => item.toLowerCase().contains(part))) {
        li.classes.add('found');
        foundLis.add(li);
      } else {
        lis.add(li);
      }
    }

    foundLis
        .sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));

    _tagsList.children = []..addAll(foundLis)..addAll(lis);
  }

  /**
   * Add [items] to the telephone number list.
   */
  set telephoneNumbers(List<model.PhoneNumber> items) {
    final List<LIElement> list = new List<LIElement>();

    items.forEach((model.PhoneNumber item) {
      final SpanElement spanLabel = new SpanElement();
      final SpanElement spanNumber = new SpanElement();

      spanNumber.classes.toggle('secret', item.confidential);
      spanNumber.classes.add('number');
      spanNumber.text = item.destination;

      spanLabel.classes.add('label');
      spanLabel.text = item.note;

      list.add(new LIElement()
        ..children.addAll([spanNumber, spanLabel])
        ..dataset['object'] = json.encode(item));
    });

    _phoneNumberList.children = list;
  }

  /**
   * Add [items] to the titles list.
   */
  set titles(List<String> items) => _populateList(_titleList, items);

  /**
   * Show/hide the popup.
   *
   * Venture forth at your own peril!
   */
  void _togglePopup(HtmlElement target) {
    if (_popupDiv.classes.contains('popup-hidden')) {
      _popupDiv.classes.toggle('popup-hidden', false);

      if (target == _showPSTNSpan) {
        _showPSTNSpan.classes.toggle('active', true);
        _tagsList.style.display = 'none';
        _pstnInput.style.display = 'inline';
        new Future.delayed(new Duration(milliseconds: 1))
            .then((_) => _pstnInput.focus());
      } else {
        _showTagsSpan.classes.toggle('active', true);
        _pstnInput.style.display = 'none';
        _tagsList.style.display = 'block';
      }
    } else {
      if (target == _showPSTNSpan && _showPSTNSpan.classes.contains('active')) {
        _showPSTNSpan.classes.toggle('active', false);
        _popupDiv.classes.toggle('popup-hidden', true);
        _focusElement.focus();
      } else if (target == _showTagsSpan &&
          _showTagsSpan.classes.contains('active')) {
        _showTagsSpan.classes.toggle('active', false);
        _popupDiv.classes.toggle('popup-hidden', true);
      } else if (target == _showPSTNSpan &&
          _showTagsSpan.classes.contains('active')) {
        _tagsList.style.display = 'none';
        _pstnInput.style.display = 'inline';
        _showTagsSpan.classes.toggle('active', false);
        _showPSTNSpan.classes.toggle('active', true);
        new Future.delayed(new Duration(milliseconds: 1))
            .then((_) => _pstnInput.focus());
      } else if (target == _showTagsSpan &&
          _showPSTNSpan.classes.contains('active')) {
        _pstnInput.style.display = 'none';
        _tagsList.style.display = 'block';
        _showPSTNSpan.classes.toggle('active', false);
        _showTagsSpan.classes.toggle('active', true);
        _focusElement.focus();
      } else {
        // This is bonkers! Why are we here!! Hide the popup and remove .active
        _showPSTNSpan.classes.toggle('active', false);
        _showTagsSpan.classes.toggle('active', false);
        _popupDiv.classes.toggle('popup-hidden', true);
        _focusElement.focus();
      }
    }
  }

  /**
   * Add [items] to the workhours list.
   */
  set workHours(List<String> items) => _populateList(_workHoursList, items);
}
