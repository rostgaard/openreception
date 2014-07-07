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

class ReceptionOther {
  final Context uiContext;
  final Element element;

  bool     hasFocus  = false;
  bool get muted     => this.uiContext != Context.current;
  
  static const String className = '${libraryName}.ReceptionOther';
  static const String NavShortcut = 'V';
  List<Element> get nudges => this.element.querySelectorAll('.nudge');
  void set nudgesHidden(bool hidden) => this.nudges.forEach((Element element) => element.hidden = hidden);

  Element          get header => this.element.querySelector('legend');
  ParagraphElement get body   => element.querySelector('#${id.COMPANY_OTHER_BODY}');

  String           title    = 'Andet';

  ReceptionOther(Element this.element, Context this.uiContext) {
    assert(element.attributes.containsKey(defaultElementId));

    ///Navigation shortcuts
    this.element.insertBefore(new Nudge(NavShortcut).element, this.header);
    keyboardHandler.registerNavShortcut(NavShortcut, this._select);

    header.text = title;

    registerEventListeners();
  }
  
  void _select (_) {
    const String context = '${className}._select';
    log.debugContext('${this.uiContext} : ${Context.current}', context);
    
    if (!this.muted) {
      Controller.Context.changeLocation(new nav.Location(uiContext.id, element.id, body.id));
    } 
  }

  void registerEventListeners() {

    event.bus.on(event.keyNav).listen((bool isPressed) => this.nudgesHidden = !isPressed);

    event.bus.on(event.receptionChanged).listen((model.Reception selectedReception) {
      if (selectedReception.extraDataUri != null) {
        this.body.children = [new ProgressElement()];

        selectedReception.loadExtraData().then ((String responseText) {
          this.body.children = new DocumentFragment.html(responseText).children;
        });
      }
    });

    element.onClick.listen((_) {
      event.bus.fire(event.locationChanged, new nav.Location(uiContext.id, element.id, body.id));
    });

    event.bus.on(event.locationChanged).listen((nav.Location location) {
      bool active = location.widgetId == element.id;
      element.classes.toggle(FOCUS, active);
      if(active) {
        body.focus();
      }
    });
  }
}
