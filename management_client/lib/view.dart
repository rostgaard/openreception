library management_tool.view;

import 'dart:async';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:openreception_framework/bus.dart';
import 'package:openreception_framework/model.dart' as model;
import 'package:management_tool/controller.dart' as controller;
import 'package:management_tool/notification.dart' as notify;

part 'view/view-dialplan.dart';
part 'view/view-dialplan_list.dart';
part 'view/view-organization.dart';
part 'view/view-user.dart';
part 'view/view-user_groups.dart';
part 'view/view-user_identities.dart';

const String _libraryName = 'management_tool.view';

abstract class Key {
  static const int ESCAPE = 27;
  static const int ENTER = 13;
}

LIElement actionTemplate(model.Action oh) =>
    new LIElement()..text = oh.toString();

LIElement hourActionTemplate(model.HourAction ha) => new LIElement()
  ..children = [
    new HeadingElement.h4()..text = 'Hours',
    new UListElement()
      ..children = (ha.hours
          .map((oh) => new LIElement()..text = oh.toString())
          .toList()),
    new HeadingElement.h4()..text = 'Actions',
    new UListElement()..children = (ha.actions.map(actionTemplate).toList())
  ];

LIElement extensionTemplate(model.NamedExtension ne) => new LIElement()
  ..children = [
    new HeadingElement.h4()..text = ne.name,
    new UListElement()..children = (ne.actions.map(actionTemplate).toList())
  ];

class IvrMenuList {
  set menus(Iterable<model.IvrMenu> menus) {
    LIElement template(model.IvrMenu menu) =>
        new IvrMenuListItem(menu).element;

    element.children = new List<Element>.from(
        [new AnchorElement(href: '/ivr/create')..text = 'Create new'])
      ..addAll(menus.map(template));
  }

  final UListElement element = new UListElement()
    ..classes = ['ivr-listing-widget'];
}

class IvrMenuListItem {
  IvrMenuListItem(model.IvrMenu menu) {
    element.children = [
      new AnchorElement(href: '/ivr/${menu.name}')..text = menu.name
    ];
  }

  final LIElement element = new LIElement();
}

class IvrMenuView {
  //final ORService.RESTIvrStore _ivrStore;

  String get name => element.id.replaceFirst('ivr-menu-', '');

  IvrMenuView() {
//    _saveButton.onClick.listen(
//        (_) => _ivrStore.update(menu).then((savedMenu) => menu = savedMenu));

    element.children = [
      _nameLabel,
      _nameInput,
      _longGreeting,
      _entries,
      _saveButton
    ];
  }

  set menu(model.IvrMenu menu) {
    element.id = 'ivr-menu-${menu.name}';
    _nameInput
      ..id = 'ivr-menu${menu.name}-name'
      ..value = menu.name;
    _nameLabel.text = 'ivr-menu${menu.name}-name';
    _longGreeting.text = '${menu.greetingLong}';
    _entries.value = menu.entries.map((entry) => entry.toJson()).join('\n');
  }

  model.IvrMenu get menu => new model.IvrMenu(
      _nameInput.value, model.Playback.parse(_longGreeting.text))
    ..name = name
    ..entries = _entries.value.split('\n').map(model.IvrEntry.parse).toList();

  final DivElement element = new DivElement()..classes = ['ivr-edit-widget'];
  final InputElement _nameInput = new InputElement();
  final ParagraphElement _nameLabel = new ParagraphElement()..text = 'Name: ';
  final ParagraphElement _longGreeting = new ParagraphElement();
  final TextAreaElement _entries = new TextAreaElement();
  final ButtonElement _saveButton = new ButtonElement()..text = 'Update';
}
