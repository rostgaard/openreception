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
 * Toggle visibility of contexts. Basically all this does is set the z-index
 * to 1 of the latest [controller.Destination].context and z-index 0 on all
 * other contexts.
 */
class UIContexts {
  Map<controller.Context, HtmlElement> _contextMap;

  /**
   * Constructor.
   */
  UIContexts() {
    _contextMap = {
      controller.Context.calendarEdit: contextCalendarEdit,
      controller.Context.home: contextHome,
      controller.Context.homePlus: contextHomeplus,
      controller.Context.messages: contextMessages
    };
  }

  HtmlElement get contextCalendarEdit =>
      querySelector('#context-calendar-edit') as HtmlElement;
  HtmlElement get contextHome => querySelector('#context-home') as HtmlElement;
  HtmlElement get contextHomeplus => querySelector('#context-homeplus') as HtmlElement;
  HtmlElement get contextMessages => querySelector('#context-messages') as HtmlElement;

  /**
   * Make [destination].context visible and all other contexts invisible.
   */
  void toggleContext(controller.Destination destination) {
    _contextMap.forEach((id, element) {
      id == destination.context
          ? element.style.zIndex = '1'
          : element.style.zIndex = '0';
    });
  }
}
