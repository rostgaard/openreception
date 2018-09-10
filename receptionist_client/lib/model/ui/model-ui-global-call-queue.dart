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
 * Provides access to the global call queue widget.
 */
class UIGlobalCallQueue extends UIModel {
  final bool _hideInboundCallerId;
  final Map<String, String> _langMap;
  final List<String> _myIdentities;
  final DivElement _myRoot;

  /**
   * Constructor.
   */
  UIGlobalCallQueue(DivElement this._myRoot, Map<String, String> this._langMap,
      bool this._hideInboundCallerId, List<String> this._myIdentities) {
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
  TitleElement get _title => querySelector('title');

  /**
   * Append [call] to the calls list.
   */
  void appendCall(model.Call call) {
    _list.children.add(_buildCallElement(call));
    _queueLengthUpdate();
  }

  /**
   * Construct a call [LIElement] from [call]
   */
  LIElement _buildCallElement(model.Call call) {
    final SpanElement callState = new SpanElement()
      ..classes.add('call-state')
      ..text = _langMap['callstate-${call.state.toLowerCase()}'];

    final SpanElement callDesc = new SpanElement()
      ..classes.add('call-description')
      ..text = (_myIdentities.contains(call.callerId) || !_hideInboundCallerId)
          ? call.callerId
          : _langMap[Key.call]
      ..children.add(callState);

    final SpanElement callWaitTimer = new SpanElement()
      ..classes.add('call-wait-time')
      ..text = new DateTime.now()
          .difference(call.arrived)
          .inSeconds
          .abs()
          .toString();

    return new LIElement()
      ..dataset['id'] = call.id
      ..dataset['object'] = json.encode(call)
      ..children.addAll([callDesc, callWaitTimer])
      ..classes.add(call.inbound ? 'inbound' : 'outbound')
      ..classes.toggle('locked', call.locked)
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
   * Add [calls] to the calls list.
   */
  set calls(List<model.Call> calls) {
    final List<LIElement> list = new List<LIElement>();

    calls.forEach((model.Call call) {
      list.add(_buildCallElement(call));
    });

    _list.children = list;

    _queueLengthUpdate();
  }

  /**
   * Remove all entries from the list and clear the header.
   */
  void clear() {
    _headerExtra.text = '';
    _list.children.clear();
  }

  /**
   * Return true if there are calls in the queue.
   */
  bool get hasCalls => _list.children.isNotEmpty;

  /**
   * Observers.
   */
  void _observers() {
    _root.onKeyDown.listen(_keyboard.press);
    _root.onClick.listen((_) => _list.focus());

    _callAgeUpdate();
  }

  /**
   * Update the queue length counter in the widget and the app title element.
   */
  void _queueLengthUpdate() {
    final String queueLength = _list.querySelectorAll('li').length.toString();
    _queueLength.text = queueLength;
    _title.text = 'ORC ($queueLength)';
  }

  /**
   * Remove [call] from the call list. Does nothing if [call] does not exist
   * in the call list.
   */
  void removeCall(model.Call call) {
    final LIElement li = _list.querySelector('[data-id="${call.id}"]');

    if (li != null) {
      li.remove();
      _queueLengthUpdate();
    }
  }

  /**
   * Setup keys and bindings to methods specific for this widget.
   */
  void _setupLocalKeys() {
    _hotKeys.registerKeysPreventDefault(_keyboard, _defaultKeyMap());
  }

  /**
   * Update [call] in the call list. Does nothing if [call] does not exist in
   * the call list.
   */
  void updateCall(model.Call call) {
    final LIElement li = _list.querySelector('[data-id="${call.id}"]');

    if (li != null) {
      li.replaceWith(_buildCallElement(call));
    }
  }
}
