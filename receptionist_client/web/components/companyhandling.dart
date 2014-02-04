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

part of components;

class CompanyHandling {
  Box             box;
  Context         context;
  DivElement      element;
  bool            hasFocus  = false;
  SpanElement     header;
  model.Reception reception = model.nullReception;
  UListElement    ul;
  String          title     = 'Håndtering';

  CompanyHandling(DivElement this.element, Context this.context) {
    ul = new UListElement()
      ..id = 'company_handling_list'
      ..classes.add('zebra');

    header = new SpanElement()
      ..text = title;

    box = new Box.withHeader(element, header, ul);

    context.registerFocusElement(ul);

    _registerEventListeners();
  }

  void _registerEventListeners() {
    event.bus.on(event.receptionChanged).listen((model.Reception value) {
      reception = value;
      render();
    });

//    ul.onFocus.listen((_) {
//      if(!hasFocus) {
//        setFocus(ul.id);
//      }
//    });

    element.onClick.listen((_) {
//      setFocus(ul.id);
      event.bus.fire(event.locationChanged, new nav.Location(context.id, element.id, ul.id));
    });

    event.bus.on(event.locationChanged).listen((nav.Location location) {
      bool active = location.widgetId == element.id;
      element.classes.toggle(focusClassName, active);
      if(active) {
        ul.focus();
      }
    });
    
//    event.bus.on(event.focusChanged).listen((Focus value) {
//      hasFocus = handleFocusChange(value, [ul], element);
//    });
  }

  void render() {
    ul.children.clear();

    for(var value in reception.handlingList) {
      ul.children.add(new LIElement()
                        ..text = value.value);
    }
  }
}
