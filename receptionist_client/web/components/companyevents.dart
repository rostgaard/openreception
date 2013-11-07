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

class CompanyEvents {
  Box                box;
  Context            context;
  DivElement         element;
  SpanElement        header;
  model.Organization organization = model.nullOrganization;
  String             title        = 'Kalender';
  UListElement       ul;

  bool hasFocus = false;

  CompanyEvents(DivElement this.element) {
    element.classes.add('company-events-container');

    ul = new UListElement()
      ..id = 'company_events_list'
      ..classes.add('zebra')
      ..tabIndex = getTabIndex('company_events_list');

    header = new SpanElement()
      ..text = title;

    box = new Box.withHeader(element, header, ul);

    _registerEventListeners();
  }

  void _registerEventListeners() {
    event.bus.on(event.organizationChanged).listen((model.Organization value) {
      organization = value;
      render();
    });

    ul.onFocus.listen((_) {
      setFocus(ul.id);
    });

    element.onClick.listen((_) {
      setFocus(ul.id);
    });

    event.bus.on(event.focusChanged).listen((Focus value) {
      if (value.old == ul.id) {
        hasFocus = false;
        element.classes.remove(focusClassName);
      }

      if(value.current == ul.id) {
        hasFocus = true;
        element.classes.add(focusClassName);
        ul.focus();
      }
    });
  }

  String getClass(model.CalendarEvent event) {
    return event.active ? 'company-events-active' : '';
  }

  void render() {
    ul.children.clear();

    for(var event in organization.calendarEventList) {
      String html = '''
        <li class="${event.active ? 'company-events-active': ''}">
          <table class="calendar-event-table">
            <tbody>
              <tr>
                <td class="calendar-event-content ${event.active ? '' : 'calendar-event-notactive'}">
                  ${event}
                <td>
              </tr>
            </tbody>
            <tfoot>
              <tr>
                <td class="calendar-event-timestamp ${event.active ? '' : 'calendar-event-notactive'}">
                  ${event.start} - ${event.stop}
                <td>
              </tr>
            </tfoot>
          </table>
        </li>
      ''';

      ul.children.add(new DocumentFragment.html(html).children.first);
    }
  }
}
