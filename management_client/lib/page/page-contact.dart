library orm.page.contact;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:orm/controller.dart' as controller;
import 'package:orm/view.dart' as view;
import 'package:orf/event.dart' as event;
import 'package:orf/model.dart' as model;
import 'package:route_hierarchical/client.dart';

const String _libraryName = 'contact.view';

controller.Popup _notify = controller.popup;

class Contact {
  final Logger _log = new Logger('$_libraryName.Contact');
  DivElement element;

  SearchInputElement _searchBox;

  final controller.Contact _contactController;
  final controller.Calendar _calendarController;
  final controller.Reception _receptionController;
  final Router _router;

  UListElement _ulContactList;
  UListElement _ulReceptionData;
  UListElement _ulReceptionList;
  UListElement _ulOrganizationList;
  List<model.BaseContact> _contactList = new List<model.BaseContact>();

  final ButtonElement _createButton = new ButtonElement()
    ..id = 'contact-create'
    ..text = 'Opret'
    ..classes.add('create');

  view.Contact _contactData;
  static const List<String> phonenumberTypes = const ['PSTN', 'SIP'];

  bool get isHidden => element.hidden;

  /**
   *
   */
  Contact(
      DivElement this.element,
      this._contactController,
      this._receptionController,
      this._calendarController,
      Stream<event.ContactChange> contactChanges,
      Stream<event.ReceptionData> receptionDataChanges,
      Stream<event.CalendarChange> calendarChanges,
      this._router) {
    _setupRouter();

    _searchBox = element.querySelector('#contact-search-box');

    _contactData = new view.Contact(
        _contactController, _calendarController, _receptionController);

    element.querySelector('#contact-create').replaceWith(_createButton);
    element
        .querySelector('#contact-base-info')
        .replaceWith(_contactData.element);

    _ulContactList = element.querySelector('#contact-list');
    element.classes.add('page');

    _observers(contactChanges, receptionDataChanges, calendarChanges);

    _refreshList();
    _ulReceptionData = element.querySelector('#reception-contacts');
    _ulReceptionList = element.querySelector('#contact-reception-list');
    _ulOrganizationList = element.querySelector('#contact-organization-list');
  }

  /**
   *
   */
  void _observers(
      Stream<event.ContactChange> contactChanges,
      Stream<event.ReceptionData> receptionDataChanges,
      Stream<event.CalendarChange> calendarChanges) {
    contactChanges.listen((event.ContactChange e) async {
      if (isHidden) {
        return null;
      }

      _refreshList();

      if (e.isUpdate && _contactData.contact.id == e.cid) {
        _contactData.contact = await _contactController.get(e.cid);

        controller.popup.info(
            'Valgte kontaktperson ændret af ${e.modifierUid} - opdaterer datablad',
            '');
      } else if (e.isDelete && _contactData.contact.id == e.cid) {
        _clearContent();
        controller.popup.info(
            'Valgte kontaktperson slettet af ${e.modifierUid} - rydder datablad',
            '');
      }
    });

    _createButton.onClick.listen((_) => _router.gotoUrl('/contact/create'));

    _searchBox.onInput.listen((_) => _performSearch());
  }

  void _performSearch() {
    String searchTerm = _searchBox.value;
    _ulContactList.children
      ..clear()
      ..addAll(_contactList
          .where((model.BaseContact contact) =>
              contact.name.toLowerCase().contains(searchTerm.toLowerCase()))
          .map(_makeContactNode));
  }

  void _refreshList() {
    _contactController.list().then((Iterable<model.BaseContact> cRefs) {
      int compareTo(model.BaseContact c1, model.BaseContact c2) =>
          c1.name.compareTo(c2.name);

      List<model.BaseContact> list = cRefs.toList()..sort(compareTo);
      this._contactList = list;
      _performSearch();
    }).catchError((error) {
      _log.severe('Tried to fetch organization but got error: $error');
    });
  }

  LIElement _makeContactNode(model.BaseContact cRef) {
    LIElement li = new LIElement()
      ..dataset['cid'] = cRef.id.toString()
      ..text = '${cRef.name}'
      ..onClick.listen((_) => _router.gotoUrl('/contact/edit/${cRef.id}'));

    return li;
  }

  void _highlightContactInList(int id) {
    _ulContactList.children.forEach((Element li) =>
        li.classes.toggle('highlightListItem', li.dataset['cid'] == '$id'));
  }

  /**
   *
   */
  Future _activateContact(int cid) async {
    /// Clear fields
    _contactData.clear();
    _ulReceptionData.children = [new ParagraphElement()..text = 'Henter'];
    _ulReceptionList.children = [new ParagraphElement()..text = 'Henter'];
    _ulOrganizationList.children = [new ParagraphElement()..text = 'Henter'];

    _contactData.contact = await _contactController.get(cid);

    _highlightContactInList(cid);

    final Iterable<model.ReceptionReference> rRefs =
        await _contactController.receptions(cid);

    _ulReceptionData.children = new List.from(
        await Future.wait(rRefs.map((model.ReceptionReference rRef) async {
      final model.ReceptionAttributes attr =
          await _contactController.getByReception(cid, rRef.id);
      view.ReceptionContact rcView = new view.ReceptionContact(
          _receptionController, _contactController, rRefs.length == 1)
        ..attributes = attr;

      return rcView.element;
    })));

    //Rightbar
    final List<model.OrganizationReference> oRefs = (await _contactController
            .contactOrganizations(cid))
        .toList(growable: false)..sort(view.compareOrgRefs);

    _ulOrganizationList.children =
        new List.from(oRefs.map(_createOrganizationNode));

    final Map<model.ReceptionReference, Iterable<model.BaseContact>> collRefs =
        (await _contactController.colleagues(cid));

    _ulReceptionList.children.clear();
    collRefs.forEach(
        (model.ReceptionReference rRef, Iterable<model.BaseContact> crefs) {
      final li = _createReceptionNode(rRef);
      List<model.BaseContact> colls = crefs.toList(growable: false)..sort(view.compareContacts);

      li.children.add(new UListElement()
        ..classes.add('zebra-odd')
        ..children = new List<LIElement>.from(colls.map(_createColleagueNode)));

      _ulReceptionList.children.add(li);
    });
  }

  /**
   * Clear our the fields of the view and hide the relevant DOM nodes.
   */
  void _clearContent() {
    _contactData.clear();
    _ulOrganizationList.children.clear();
    _ulReceptionData.children.clear();
    _ulReceptionList.children.clear();
    _contactData.element.hidden = true;
  }

  /**
   *
   */
  LIElement _createReceptionNode(model.ReceptionReference rRef) {
    return new LIElement()
      ..classes.add('clickable')
      ..classes.add('reception')
      ..children = [
        new AnchorElement(href: '/reception/edit/${rRef.id}')
          ..text = '${rRef.name}'
      ];
  }

  /**
   *
   */
  LIElement _createColleagueNode(model.BaseContact cRef) {
    return new LIElement()
      ..classes.add('clickable')
      ..classes.add('colleague')
      ..children = [
        new AnchorElement(href: '/contact/edit/${cRef.id}')
          ..text = '${cRef.name}'
      ];
  }

  /**
   *
   */
  LIElement _createOrganizationNode(model.OrganizationReference oRef) {
    final String name = oRef.name.isEmpty ? '(uden navn)' : oRef.name;

    LIElement li = new LIElement()
      ..children = [
        new AnchorElement(href: '/organization/edit/${oRef.id}')
          ..text = '${name} (oid:${oRef.id})'
      ];

    return li;
  }

  /**
     *
     */
  Future activate(RouteEvent e) async {
    element.hidden = false;
    await _refreshList();
  }

  /**
     *
     */
  void deactivate(RouteEvent e) {
    element.hidden = true;
  }

  /**
   *
   */
  Future _createContact(RouteEvent e) async {
    _clearContent();
    _contactData.contact = new model.BaseContact.empty();
  }

  Future _contactEdit(RouteEvent e) async {
    final int cid = int.parse(e.parameters['cid']);

    await _activateContact(cid);
  }

  /**
   *
   */
  void _setupRouter() {
    print('Setting up contact routes');
    _router.root
      ..addRoute(
          name: 'contact',
          enter: activate,
          path: '/contact',
          leave: deactivate,
          mount: (router) => router
            ..addRoute(name: 'create', path: '/create', enter: _createContact)
            ..addRoute(
                name: 'edit',
                path: '/edit',
                mount: (router) => router
                  ..addRoute(name: 'id', path: '/:cid', enter: _contactEdit)));
  }
}
