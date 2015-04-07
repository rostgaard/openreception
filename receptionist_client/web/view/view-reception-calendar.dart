part of view;

class ReceptionCalendar extends ViewWidget {
  Place                _myPlace;
  UIReceptionCalendar _dom;

  /**
   * [root] is the parent element of the widget, and [_myPlace] is the [Place]
   * object that this widget reacts on when Navigate.go fires.
   */
  ReceptionCalendar(UIReceptionCalendar this._dom, Place this._myPlace) {
    _registerEventListeners();
  }

  @override HtmlElement get focusElement => _dom.eventList;
  @override Place get myPlace => _myPlace;
  @override HtmlElement get root => _dom.root;

  void _activateMe(_) {
    _navigateToMyPlace();
  }

  void _registerEventListeners() {
    _navigate.onGo.listen(_setWidgetState);

    _dom.root.onClick.listen(_activateMe);

    _hotKeys.onAltA.listen(_activateMe);

    // TODO (TL): temporary stuff
    _dom.eventList.onDoubleClick.listen((_) => _navigate.goCalendarEdit());
  }
}
