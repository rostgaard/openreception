library orm.page.organization;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:orm/configuration.dart';
import 'package:orm/controller.dart' as controller;
import 'package:orm/view.dart' as view;
import 'package:orf/event.dart' as event;
import 'package:orf/model.dart' as model;
import 'package:route_hierarchical/client.dart';

controller.Popup _notify = controller.popup;

const String _libraryName = 'orm.page.organization';

class Organization {
  Logger _log = new Logger('$_libraryName.Organization');

  final controller.Organization _organizationController;

  final Router _router;

  final DivElement element = new DivElement()
    ..id = "organization-page"
    ..hidden = true
    ..classes.add('page');
  final UListElement _orgUList = new UListElement()
    ..id = 'organization-list'
    ..classes.add('zebra-even');

  final ButtonElement _createButton = new ButtonElement()
    ..text = 'Opret'
    ..classes.add('create');

  final SearchInputElement _searchBox = new SearchInputElement()
    ..id = 'organization-search-box'
    ..value = ''
    ..placeholder = 'Filter...';
  final UListElement _ulReceptionList = new UListElement()
    ..id = 'organization-reception-list'
    ..classes.add('zebra-odd');
  final UListElement _ulContactList = new UListElement()
    ..id = 'organization-contact-list'
    ..classes.add('zebra-odd');

  view.Organization _organizationView;

  List<model.OrganizationReference> _organizations =
      new List<model.OrganizationReference>();

  List<model.ReceptionReference> _currentReceptionList =
      new List<model.ReceptionReference>();

  /**
   *
   */
  Organization(controller.Organization this._organizationController,
      Stream<event.OrganizationChange> orgChanges, Router this._router) {
    _setupRouter();
    _organizationView = new view.Organization(_organizationController);

    element.children = [
      new DivElement()
        ..id = 'organization-listing'
        ..children = [
          new DivElement()
            ..id = "user-controlbar"
            ..classes.add('basic3controls')
            ..children = [_createButton],
          _searchBox,
          _orgUList,
        ],
      new DivElement()
        ..id = 'organization-content'
        ..children = [_organizationView.element],
      new DivElement()
        ..id = 'organization-rightbar'
        ..children = [
          new DivElement()
            ..id = 'organization-reception-container'
            ..children = [
              new DivElement()
                ..children = [
                  new HeadingElement.h4()..text = 'Receptioner',
                  _ulReceptionList
                ]
            ],
          new DivElement()
            ..id = 'organization-contact-container'
            ..children = [
              new DivElement()
                ..children = [
                  new HeadingElement.h4()..text = 'Kontakter',
                  _ulContactList
                ]
            ]
        ]
    ];

    _observers(orgChanges);
  }

  /**
   *
   */
  void _observers(Stream<event.OrganizationChange> orgChanges) {
    _createButton.onClick.listen((_) {
      _router.go('organization.create', {});
    });

    _searchBox.onInput.listen((_) => _performSearch());

    orgChanges.listen((event.OrganizationChange ogc) async {
      if (!this.element.hidden) {
        /// Always refresh the userlist
        await _refreshList();

        /// This is the currently selected organization
        if (ogc.oid == _organizationView.organization.id) {
          if (ogc.isDelete) {
            _organizationView.clear();
            _organizationView.hidden = true;
            _clearRightBar();
            _router.go('organization.edit.id', {'oid': ogc.oid});
          } else if (ogc.isUpdate) {
            _router.go('organization.edit.id', {'oid': ogc.oid});
          }
        } else if (ogc.isCreate && ogc.modifierUid == config.user.id) {
          _router.go('organization.edit.id', {'oid': ogc.oid});
        }
      }
    });
  }

  /**
   * Clear out the nodes on the right side of the UI.
   */
  void _clearRightBar() {
    _currentReceptionList.clear();
    _ulContactList.children.clear();
    _ulReceptionList.children.clear();
  }

  /**
   *
   */
  void _performSearch() {
    String searchText = _searchBox.value;
    List<model.OrganizationReference> filteredList = _organizations
        .where((model.OrganizationReference org) =>
            org.name.toLowerCase().contains(searchText.toLowerCase()))
        .toList();
    _renderOrganizationList(filteredList);
  }

  /**
   *
   */
  Future _refreshList() async {
    await _organizationController
        .list()
        .then((Iterable<model.OrganizationReference> organizations) {
      int compareTo(model.OrganizationReference org1,
              model.OrganizationReference org2) =>
          org1.name.compareTo(org2.name);

      List<model.OrganizationReference> list = organizations.toList()
        ..sort(compareTo);
      this._organizations = list;
      _renderOrganizationList(list);
      _highlightOrganizationInList(_organizationView.organization.id);
    }).catchError((error) {
      _notify.error('Organisationsliste kunne ikke hentes', 'Fejl: $error');
      _log.severe('Tried to fetch organization list, got error: $error');
    });
  }

  void _renderOrganizationList(
      List<model.OrganizationReference> organizations) {
    _orgUList.children
      ..clear()
      ..addAll(organizations.map(_makeOrganizationNode));
  }

  LIElement _makeOrganizationNode(model.OrganizationReference organization) {
    return new LIElement()
      ..classes.add('clickable')
      ..dataset['organizationid'] = '${organization.id}'
      ..text = '${organization.name}'
      ..onClick.listen((_) {
        _router.go('organization.edit.id', {'oid': organization.id});
        //_activateOrganization(organization.id);
      });
  }

  void _highlightOrganizationInList(int id) {
    _orgUList.children.forEach((Element li) => li.classes
        .toggle('highlightListItem', li.dataset['organizationid'] == '$id'));
  }

  Future _activateOrganization(int oid) async {
    try {
      _organizationView.loading = true;
      _organizationView.organization = await _organizationController.get(oid);
      _organizationView.loading = false;
    } catch (error) {
      _notify.error('Kunne ikke hente stamdata for organisation oid:$oid',
          'Fejl: $error');
      _log.severe(
          'Tried to activate organization "$oid" but gave error: $error');
    }

    _highlightOrganizationInList(oid);

    _updateReceptionList(oid);
    _updateContactList(oid);
  }

  void _updateReceptionList(int organizationId) {
    _organizationController
        .receptions(organizationId)
        .then((Iterable<model.ReceptionReference> rRefs) {
      _currentReceptionList = rRefs.toList();
      _ulReceptionList.children
        ..clear()
        ..addAll(rRefs.map(_makeReceptionNode));
    });
  }

  LIElement _makeReceptionNode(model.ReceptionReference rRef) {
    LIElement li = new LIElement()
      ..classes.add('clickable')
      ..text = '${rRef.name}'
      ..onClick.listen((_) {
        _router.go('reception.edit.id', {'rid': rRef.id});
      });
    return li;
  }

  void _updateContactList(int organizationId) {
    _organizationController
        .contacts(organizationId)
        .then((Iterable<model.BaseContact> contacts) {
      int compareTo(model.BaseContact c1, model.BaseContact c2) =>
          c1.name.toLowerCase().compareTo(c2.name.toLowerCase());

      List<model.BaseContact> sorted = contacts.toList()..sort(compareTo);

      _ulContactList.children
        ..clear()
        ..addAll(sorted.map(_makeContactNode));
    }).catchError((error) {
      _notify.error('Kunne ikke hente organisationskontakter', 'Fejl: $error');
      _log.severe(
          'Tried to fetch the contactlist from an organization Error: $error');
    });
  }

  LIElement _makeContactNode(model.BaseContact cRef) {
    LIElement li = new LIElement()
      ..classes.add('clickable')
      ..text = '${cRef.name}'
      ..onClick.listen((_) {
        _router.go('contact.edit.id', {'cid': cRef.id});
      });
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

  Future activateCreate(RouteEvent e) async {
    await activate(e);
    _clearRightBar();
    _organizationView.hidden = false;
    _organizationView.loading = true;
    _organizationView.organization = new model.Organization.empty();
    _organizationView.loading = false;
  }

  /**
   *
   */
  void deactivateCreate(RouteEvent e) {
    _clearRightBar();
    _organizationView.organization = new model.Organization.empty();
    _organizationView.element.hidden = true;
  }

  Future activateEdit(RouteEvent e) async {
    final int oid = int.parse(e.parameters['oid']);
    await activate(e);
    await _activateOrganization(oid);
  }

  /**
   *
   */
  void _setupRouter() {
    print('setting up organization router');
    _router.root
      ..addRoute(
          name: 'organization',
          enter: activate,
          path: '/organization',
          leave: deactivate,
          mount: (router) => router
            ..addRoute(
                name: 'create',
                path: '/create',
                enter: activateCreate,
                leave: deactivateCreate)
            ..addRoute(
                name: 'edit',
                path: '/edit',
                mount: (router) => router
                  ..addRoute(
                      name: 'id',
                      path: '/:oid',
                      enter: activateEdit,
                      leave: deactivateCreate)));
  }
}
