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


typedef KeyBoardListener = void Function(html.KeyboardEvent event);

/**
 * Setup global keyboard shortcuts and associated event streams.
 */
class HotKeys {
  factory HotKeys() => _singleton;

  /**
   * Internal constructor.
   */
  HotKeys._internal() {
    deactivateCtrlA();
    html.window.document.onKeyDown.listen(_keyDown.press);

    final Map<dynamic, KeyBoardListener> preventDefaultBindings = <dynamic, KeyBoardListener>{
      'Alt+Down': (event) => _altArrowDown.fire(event),
      'Alt+Up': (event) => _altArrowUp.fire(event),
      'Alt+b': (event) => _altB.fire(event),
      'Alt+c': (event) => _altC.fire(event),
      'Alt+d': (event) => _altD.fire(event),
      'Alt+e': (event) => _altE.fire(event),
      'Alt+f': (event) => _altF.fire(event),
      'Alt+h': (event) => _altH.fire(event),
      'Alt+i': (event) => _altI.fire(event),
      'Alt+k': (event) => _altK.fire(event),
      'Alt+m': (event) => _altM.fire(event),
      'Alt+q': (event) => _altQ.fire(event),
      'Alt+s': (event) => _altS.fire(event),
      'Alt+Space': (event) => _altSpace.fire(event),
      'Alt+t': (event) => _altT.fire(event),
      'Alt+v': (event) => _altV.fire(event),
      'Alt+w': (event) => _altW.fire(event),
      'Alt+x': (event) => _altX.fire(event),
      'Ctrl+Alt+Enter': (event) => _ctrlAltEnter.fire(event),
      'Ctrl+d': _null, // Blackhole this
      'Ctrl+e': (event) => _ctrlE.fire(event),
      'Ctrl+Esc': (event) => _ctrlEsc.fire(event),
      'Ctrl+k': (event) => _ctrlK.fire(event),
      'Ctrl+l': _null, // Blackhole this
      'Ctrl+s': _null, // Blackhole this
      [Key.NumMinus]: _null, // Blackhole this
      'Ctrl+Space': (event) => _ctrlSpace.fire(event),
      [Key.Ctrl, Key.NumPlus]: _null, // Blackhole this
      'Ctrl+Alt+P': (event) => _ctrlAltP.fire(event),
      'Ctrl+Alt+R': (event) => _ctrlAltR.fire(event),
      [Key.Ctrl, Key.NumMinus]: (event) => _ctrlNumMinus.fire(event),
      'F1': (event) => _f1.fire(event),
      'F7': (event) => _f7.fire(event),
      'F8': (event) => _f8.fire(event),
      'F9': (event) => _f9.fire(event),
      [Key.NumPlus]: (event) => _numPlus.fire(event),
      [Key.NumDiv]: (event) => _numDiv.fire(event),
      [Key.NumMult]: (event) => _numMult.fire(event),
      'Shift+Esc': _null
    };

    registerKeysPreventDefault(_keyDown, preventDefaultBindings);
  }

  static final HotKeys _singleton = HotKeys._internal();

  final Keyboard _keyDown = Keyboard();

  final Bus<html.KeyboardEvent> _altArrowDown = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altArrowUp = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altB = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altC = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altD = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altE = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altF = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altH = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altI = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altK = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altM = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altQ = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altS = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altSpace = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altT = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altV = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altW = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _altX = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _ctrlAltEnter = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _ctrlAltP = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _ctrlAltR = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _ctrlE = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _ctrlEsc = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _ctrlK = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _ctrlNumMinus = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _ctrlSpace = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _f1 = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _f7 = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _f8 = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _f9 = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _numDiv = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _numMult = Bus<html.KeyboardEvent>();
  final Bus<html.KeyboardEvent> _numPlus = Bus<html.KeyboardEvent>();

  Stream<html.KeyboardEvent> get onAltArrowDown => _altArrowDown.stream;
  Stream<html.KeyboardEvent> get onAltArrowUp => _altArrowUp.stream;
  Stream<html.KeyboardEvent> get onAltB => _altB.stream;
  Stream<html.KeyboardEvent> get onAltC => _altC.stream;
  Stream<html.KeyboardEvent> get onAltD => _altD.stream;
  Stream<html.KeyboardEvent> get onAltE => _altE.stream;
  Stream<html.KeyboardEvent> get onAltF => _altF.stream;
  Stream<html.KeyboardEvent> get onAltH => _altH.stream;
  Stream<html.KeyboardEvent> get onAltI => _altI.stream;
  Stream<html.KeyboardEvent> get onAltK => _altK.stream;
  Stream<html.KeyboardEvent> get onAltM => _altM.stream;
  Stream<html.KeyboardEvent> get onAltQ => _altQ.stream;
  Stream<html.KeyboardEvent> get onAltS => _altS.stream;
  Stream<html.KeyboardEvent> get onAltSpace => _altSpace.stream;
  Stream<html.KeyboardEvent> get onAltT => _altT.stream;
  Stream<html.KeyboardEvent> get onAltV => _altV.stream;
  Stream<html.KeyboardEvent> get onAltW => _altW.stream;
  Stream<html.KeyboardEvent> get onAltX => _altX.stream;
  Stream<html.KeyboardEvent> get onCtrlAltEnter => _ctrlAltEnter.stream;
  Stream<html.KeyboardEvent> get onCtrlAltP => _ctrlAltP.stream;
  Stream<html.KeyboardEvent> get onCtrlAltR => _ctrlAltR.stream;
  Stream<html.KeyboardEvent> get onCtrlE => _ctrlE.stream;
  Stream<html.KeyboardEvent> get onCtrlEsc => _ctrlEsc.stream;
  Stream<html.KeyboardEvent> get onCtrlK => _ctrlK.stream;
  Stream<html.KeyboardEvent> get onCtrlNumMinus => _ctrlNumMinus.stream;
  Stream<html.KeyboardEvent> get onCtrlSpace => _ctrlSpace.stream;
  Stream<html.KeyboardEvent> get onF1 => _f1.stream;
  Stream<html.KeyboardEvent> get onF7 => _f7.stream;
  Stream<html.KeyboardEvent> get onF8 => _f8.stream;
  Stream<html.KeyboardEvent> get onF9 => _f9.stream;
  Stream<html.KeyboardEvent> get onNumDiv => _numDiv.stream;
  Stream<html.KeyboardEvent> get onNumMult => _numMult.stream;
  Stream<html.KeyboardEvent> get onNumPlus => _numPlus.stream;

  /**
   * Activates Ctrl+a functionality.
   */
  void activateCtrlA() {
    _keyDown.unregister('Ctrl+a');
  }

  /**
   * Deactivates Crtl+a functionality.
   */
  void deactivateCtrlA() {
    _keyDown.register('Ctrl+a', (html.Event event) => event.preventDefault());
  }

  /**
   * Black hole for hotkey combos we don't want.
   */
  void _null(html.Event _) => null;

  /**
   * Register the [keyMap] keybindings to [keyboard].
   */
  void registerKeys(
      Keyboard keyboard, Map<dynamic, html.EventListener> keyMap) {
    keyMap.forEach((dynamic key, html.EventListener callback) {
      keyboard.register(key, callback);
    });
  }

  /**
   * Register the [keyMap] key bindings to [keyboard]. Prevent default on all
   * key events.
   */
  void registerKeysPreventDefault(
      Keyboard keyboard, Map<dynamic, KeyBoardListener> keyMap) {
    keyMap.forEach((dynamic key, KeyBoardListener callback) {
      keyboard.register(key, (html.Event event) {
        event.preventDefault();
        callback(event as html.KeyboardEvent);
      });
    });
  }
}

/// Convenience methods to push events unto the various hotkeys busses without
/// having an actual keyboard event.
class SimulationHotKeys {
  /// Constructor
  SimulationHotKeys(HotKeys this._hotKeys);
  final HotKeys _hotKeys;

  void altArrowDown() => _hotKeys._altArrowDown.fire(null);
  void altArrowUp() => _hotKeys._altArrowUp.fire(null);
  void altB() => _hotKeys._altB.fire(null);
  void altC() => _hotKeys._altC.fire(null);
  void altD() => _hotKeys._altD.fire(null);
  void altE() => _hotKeys._altE.fire(null);
  void altF() => _hotKeys._altF.fire(null);
  void altH() => _hotKeys._altH.fire(null);
  void altI() => _hotKeys._altI.fire(null);
  void altK() => _hotKeys._altK.fire(null);
  void altM() => _hotKeys._altM.fire(null);
  void altQ() => _hotKeys._altQ.fire(null);
  void altS() => _hotKeys._altS.fire(null);
  void altSpace() => _hotKeys._altS.fire(null);
  void altT() => _hotKeys._altT.fire(null);
  void altV() => _hotKeys._altV.fire(null);
  void altW() => _hotKeys._altW.fire(null);
  void altX() => _hotKeys._altX.fire(null);
  void ctrlAltEnter() => _hotKeys._ctrlAltEnter.fire(null);
  void ctrlAltP() => _hotKeys._ctrlAltP.fire(null);
  void ctrlAltR() => _hotKeys._ctrlAltR.fire(null);
  void ctrlE() => _hotKeys._ctrlE.fire(null);
  void ctrlEsc() => _hotKeys._ctrlEsc.fire(null);
  void ctrlK() => _hotKeys._ctrlK.fire(null);
  void ctrlNumMinus() => _hotKeys._ctrlNumMinus.fire(null);
  void ctrlSpace() => _hotKeys._ctrlSpace.fire(null);
  void f1() => _hotKeys._f1.fire(null);
  void f7() => _hotKeys._f7.fire(null);
  void f8() => _hotKeys._f8.fire(null);
  void f9() => _hotKeys._f9.fire(null);
  void numDiv() => _hotKeys._numDiv.fire(null);
  void numMult() => _hotKeys._numMult.fire(null);
  void numPlus() => _hotKeys._numPlus.fire(null);
}
