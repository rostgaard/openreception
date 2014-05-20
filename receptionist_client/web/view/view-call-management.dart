/*                     This file is part of Bob
                   Copyright (C) 2012-, AdaHeads K/S

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
 * 
 */

class CallManagement {

  static final String id = constant.ID.CALL_MANAGEMENT;
  static final String className = '${libraryName}.CallManagement';
  final DivElement node;

  // Temporary
  ButtonElement pickupnextcallbutton;
  ButtonElement hangupcallButton;
  ButtonElement holdcallButton;
  Component.Call currentCall;

  /**
   * TODO
   */
  CallManagement(DivElement this.node) {
    pickupnextcallbutton = querySelector('#pickupnextcallbutton')
        ..onClick.listen((_) => Controller.Call.pickup())
        ..tabIndex = -1;

    hangupcallButton = querySelector('#hangupcallButton')
        ..onClick.listen((_) => Controller.Call.hangup(model.Call.currentCall))
        ..tabIndex = -1;

    holdcallButton = querySelector('#holdcallButton')
        ..onClick.listen((_) => Controller.Call.park(model.Call.currentCall))
        ..tabIndex = -1;
    
    registerEventListeners();
    _changeActiveCall(model.Call.currentCall);
  }

  _changeActiveCall(model.Call call) {
    String newText;

    if (call != model.nullCall) {
      newText = call.otherLegCallerID();
    } else {
      newText = constant.Label.NOT_IN_CALL;
    }

    this.node.querySelector('#current-call-info').text = newText;
  }

  void _originationStarted(model.DiablePhoneNumber number) {
    this.node.querySelector('#current-call-info').text = 'Ringer til ${number.toLabel()}..';
  }

  void _originationSucceded(dynamic) {
    this.node.querySelector('#current-call-info').text = 'Forbundet!';
  }

  void _originationFailed(dynamic) {
    this.node.querySelector('#current-call-info').text = 'Fejlet!';
  }

  void _handleHangup(dynamic) {
    
  }
  
  void registerEventListeners() {
    event.bus.on(event.callChanged).listen(_changeActiveCall);
    event.bus.on(event.hangupCall).listen(_handleHangup);
    event.bus.on(event.originateCallRequest).listen(_originationStarted);
    event.bus.on(event.originateCallRequestSuccess).listen(_originationSucceded);
    event.bus.on(event.originateCallRequestFailure).listen(_originationFailed);
  }
}
