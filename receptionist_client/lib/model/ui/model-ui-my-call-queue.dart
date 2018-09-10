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
 * Provides access to the my call queue widget.
 */
class UIMyCallQueue extends UIModel {
  final Bus<model.Call> _dblClickBus = new Bus<model.Call>();
  final controller.Contact _contactController;
  final Map<int, String> _contactMap = new Map<int, String>();
  final Map<String, String> _langMap;
  final DivElement _myRoot;
  final controller.Reception _receptionController;
  final Map<int, String> _receptionMap = new Map<int, String>();
  final Set<String> _transferUUIDs = new Set<String>();

  /**
   * Constructor.
   */
  UIMyCallQueue(
      DivElement this._myRoot,
      Map<String, String> this._langMap,
      controller.Contact this._contactController,
      controller.Reception this._receptionController) {
    _setupLocalKeys();
    _observers();
  }

  @override
  HtmlElement get _firstTabElement => _list;
  @override
  HtmlElement get _focusElement => _list;
  @override
  HtmlElement get _lastTabElement => _list;
  @override
  HtmlElement get _root => _myRoot;

  SpanElement get _queueLength =>
      _root.querySelector('.generic-widget-headline span.queue-length');
  OListElement get _list => _root.querySelector('.generic-widget-list');

  /**
   * Append [call] to the calls list.
   */
  void appendCall(model.Call call) {
    _list.children.add(_buildCallElement(call));
    setTransferMark(call);
    _queueLengthUpdate();
  }

  /**
   * Construct a call [LIElement] from [call]
   */
  LIElement _buildCallElement(model.Call call) {
    final DivElement numbersAndStateDiv = new DivElement()
      ..classes.add('numbers-and-state')
      ..style.pointerEvents = 'none';
    final DivElement nameDiv = new DivElement()..style.pointerEvents = 'none';

    /// Add a contact or reception name to [nameDiv].
    /// If a name cannot be found in either [_contactMap] or [_receptionMap],
    /// then we will fetch a name from the server asynchronously and cache it
    /// locally.
    final SpanElement rName = new SpanElement()..style.pointerEvents = 'none';
    if (_receptionMap.containsKey(call.rid)) {
      rName.text = _receptionMap[call.rid];
    } else {
      _receptionController.get(call.rid).then((model.Reception reception) {
        rName.text = reception.name;
        _receptionMap[call.rid] = reception.name;
      });
    }

    if (!call.inbound) {
      final SpanElement cName = new SpanElement()
        ..style.pointerEvents = 'none'
        ..style.display = 'block';
      if (_contactMap.containsKey(call.cid)) {
        cName.text = _contactMap[call.cid];
      } else {
        _contactController.get(call.cid).then((model.BaseContact contact) {
          cName.text = contact.name;
          _contactMap[call.cid] = contact.name;
        });
      }
      nameDiv.children.add(cName);
    }

    if (nameDiv.children.isNotEmpty) {
      rName..style.fontSize = '0.7em';
    }

    nameDiv.children.add(rName);

    final SpanElement callState = new SpanElement()
      ..style.pointerEvents = 'none'
      ..classes.add('call-state')
      ..text = _langMap['callstate-${call.state.toLowerCase()}'];

    final SpanElement callDesc = new SpanElement()
      ..style.pointerEvents = 'none'
      ..classes.add('call-description')
      ..text = call.inbound ? '${call.callerId}' : '${call.destination}'
      ..children.add(callState);

    final SpanElement callWaitTimer = new SpanElement()
      ..style.pointerEvents = 'none'
      ..classes.add('call-wait-time')
      ..text = new DateTime.now().difference(call.arrived).inSeconds.toString();

    numbersAndStateDiv.children.addAll([callDesc, callWaitTimer]);

    return new LIElement()
      ..dataset['id'] = call.id
      ..dataset['object'] = json.encode(call)
      ..children.addAll([numbersAndStateDiv, nameDiv])
      ..classes.add(call.inbound ? 'inbound' : 'outbound')
      ..classes.toggle('locked', call.locked)
      ..classes.toggle('speaking', call.state == model.CallState.speaking)
      ..title =
          '${call.inbound ? _langMap[Key.callStateInbound] : _langMap[Key.callStateOutbound]} (${call.id})';
  }

  /**
   * Read all .call-wait-time values in _list and increment them by one.
   */
  void _callAgeUpdate() {
    new Timer.periodic(new Duration(seconds: 1), (_) {
      _list.querySelectorAll('li span.call-wait-time').forEach((Element span) {
        if (span.text.isEmpty) {
          span.text = '0';
        } else {
          span.text = (int.parse(span.text) + 1).toString();
        }
      });
    });
  }

  /**
   * Return the list of calls found in my call queue.
   */
  Iterable<model.Call> get calls =>
      _list.querySelectorAll('li').map((Element li) => new model.Call.fromJson(
          json.decode(li.dataset['object']) as Map<String, dynamic>));

  /**
   * Add [calls] to the calls list.
   */
  set calls(Iterable<model.Call> calls) {
    final List<LIElement> newList = new List<LIElement>();

    for (model.Call call in calls) {
      newList.add(_buildCallElement(call));
    }

    _list.children = newList;

    _queueLengthUpdate();
  }

  /**
   * Return all calls that are marked for transfer.
   */
  Iterable<model.Call> get markedForTransfer {
    return _list.querySelectorAll('[transfer]').map((Element li) =>
        new model.Call.fromJson(
            json.decode(li.dataset['object']) as Map<String, dynamic>));
  }

  /**
   * Mark [call] ready for transfer. Does nothing if [call] is not found in the
   * list.
   */
  void markForTransfer(model.Call call) {
    final LIElement li = _list.querySelector('[data-id="${call.id}"]');

    _transferUUIDs.add(call.id);

    if (li != null) {
      li.setAttribute('transfer', '');
    }
  }

  /**
   * Observers.
   */
  void _observers() {
    _root.onKeyDown.listen(_keyboard.press);
    _root.onClick.listen((_) => _list.focus());

    _list.onDoubleClick.listen((Event event) {
      if ((event as MouseEvent).target is LIElement) {
        _dblClickBus.fire(new model.Call.fromJson(
            json.decode((event.target as LIElement).dataset['object'])
            as Map<String, dynamic>));
      }
    });

    _callAgeUpdate();
  }

  /**
   * Returns a call when double clicking a call in the call list.
   */
  Stream<model.Call> get onDblClick => _dblClickBus.stream;

  /**
   * Update the queue length counter in the widget.
   */
  void _queueLengthUpdate() {
    _queueLength.text = _list.querySelectorAll('li').length.toString();
  }

  /**
   * Remove [call] from the call list. Does nothing if [call] does not exist
   * in the call list.
   *
   * If [call] was marked with the "transfer" attribute, then remove all
   * transfer marks from the call list.
   */
  void removeCall(model.Call call) {
    final LIElement li = _list.querySelector('[data-id="${call.id}"]');

    if (li != null) {
      li.remove();
      if (_transferUUIDs.contains(call.id)) {
        removeTransferMark(call);
      }
      _queueLengthUpdate();
    }
  }

  /**
   * Removes the transfer attribute from the [call] li element.
   */
  void removeTransferMark(model.Call call) {
    final LIElement li = _list.querySelector('[data-id="${call.id}"]');

    if (li != null) {
      li.attributes.remove('transfer');
    }

    _transferUUIDs.remove(call.id);
  }

  /**
   * Removes all transfer attributes.
   */
  void removeTransferMarks() {
    _transferUUIDs.clear();
    _list
        .querySelectorAll('[transfer]')
        .forEach((Element li) => li.attributes.remove('transfer'));
  }

  /**
   * Find [call] in queue list and set the transfer attribute.
   */
  void setTransferMark(model.Call call) {
    if (_transferUUIDs.contains(call.id)) {
      _list
          .querySelector('[data-id="${call.id}"]')
          ?.setAttribute('transfer', '');
      _transferUUIDs.remove(call.id);
    }
  }

  /**
   * Setup keys and bindings to methods specific for this widget.
   */
  void _setupLocalKeys() {
    _hotKeys.registerKeysPreventDefault(_keyboard, _defaultKeyMap());
  }

  /**
   * Update [call] in the call list. If [call] does not exist in the call list,
   * it is appended to the list.
   */
  void updateCall(model.Call call) {
    final LIElement li = _list.querySelector('[data-id="${call.id}"]');

    if (li != null) {
      final LIElement newLI = _buildCallElement(call);
      if (li.attributes.containsKey('transfer')) {
        newLI.setAttribute('transfer', '');
      }
      li.replaceWith(newLI);
    } else {
      appendCall(call);
    }
  }
}
