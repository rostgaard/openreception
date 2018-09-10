part of orm.view;

class IvrMenu {
  bool create = false;
  final ButtonElement _deleteButton = new ButtonElement()
    ..classes.add('delete')
    ..text = 'Slet'
    ..hidden = true;
  final DivElement element = new DivElement()
    ..classes = ['ivrmenu-view-widget'];
  final ButtonElement _foldJson = new ButtonElement()
    ..text = 'Fold sammen'
    ..classes.add('fold-unfold')
    ..hidden = true;
  final UListElement _inputErrorList = new UListElement();
  final Logger _log = new Logger('$_libraryName.IvrMenu');
  final controller.Ivr _menuController;
  final TextAreaElement _menuInput = new TextAreaElement()
    ..classes.add('full-width')
    ..value = ''
    ..hidden = true;
  final ButtonElement _saveButton = new ButtonElement()
    ..classes.add('save')
    ..text = 'Gem'
    ..hidden = true;
  final ButtonElement _unfoldJson = new ButtonElement()
    ..text = 'Fold ud'
    ..classes.add('fold-unfold')
    ..hidden = true;

  Function onUpdate = (String extension) => null;
  Function onDelete = (String extension) => null;
  Changelog _changelog;

  IvrMenu(this._menuController) {
    _changelog = new Changelog();
    element.children = [
      _foldJson,
      _unfoldJson,
      _deleteButton,
      _saveButton,
      _inputErrorList,
      _menuInput,
      _changelog.element
    ];
    _observers();
  }

  void _checkInput() {
    model.IvrMenu menu;
    Map<String, dynamic> map;
    _inputErrorList.children.clear();
    _menuInput.classes.toggle('error', false);
    try {
      map = json.decode(_menuInput.value);

      try {
        menu = new model.IvrMenu.fromJson(map);
        final List<ValidationException> errors = validateIvrMenu(menu);

        if (errors.isNotEmpty) {
          //TODO: Map and build more informational LI-elements.
          _inputErrorList.children
              .add(new LIElement()..text = 'Kaldplan-parser fejl.');
          _menuInput.classes.toggle('error', true);
        }
      } on FormatException {
        _inputErrorList.children
            .add(new LIElement()..text = 'Kaldplan-parser fejl.');
        _menuInput.classes.toggle('error', true);
      }
    } on FormatException {
      _inputErrorList.children.add(new LIElement()..text = 'JSON-parser fejl.');
      _menuInput.classes.toggle('error', true);
    }
  }

  Future _deleteMenu() async {
    _log.finest('Deleting menu ${menu.name}');
    final String confirmationText = 'Bekræft sletning af menu: ${menu.name}}?';

    if (_deleteButton.text != confirmationText) {
      _deleteButton.text = confirmationText;
      return;
    }

    try {
      _deleteButton.disabled = true;

      await _menuController.remove(menu.name);
      notify.success('Menuen er slettet.', menu.name);

      onDelete != null ? onDelete(menu.name) : '';

      /// Cleanup element.
      _menuInput.value = '';
      element.hidden = true;
    } catch (error) {
      notify.error('Der skete en fejl i forbindelse med sletningen af menuen.',
          'Fejl: $error');
      _log.severe('Delete ivrmenu failed with: ${error}');
    }

    _deleteButton.text = 'Slet';
  }

  bool get hasValidationError => _menuInput.classes.contains('error');

  model.IvrMenu get menu => model.IvrMenu
      .decode(json.decode(_menuInput.value) as Map<String, dynamic>);

  set menu(model.IvrMenu menu) {
    _menuInput.hidden = false;
    _menuInput.style.height = '';
    _menuInput.value = json.encode(menu);
    _deleteButton.hidden = false;
    _foldJson.hidden = true;
    _saveButton.hidden = false;
    _unfoldJson.hidden = false;
    _checkInput();
    _saveButton.disabled = true;
    _deleteButton.disabled = !_saveButton.disabled || hasValidationError;

    /// Hack! To accomodate for the fact that hidden = false can take some time before "activating"
    new Future.delayed(new Duration(milliseconds: 100), () {
      _resizeInput();
    });

    _menuController.changelog(menu.name).then((String content) {
      _changelog.content = content;
    });
  }

  void _observers() {
    _saveButton.onClick.listen((_) async {
      if (create) {
        try {
          await _menuController.create(menu);
          notify.success('IVR-Menu blev oprettet.', menu.name);
        } catch (e, s) {
          _log.shout('Failed to create', e, s);
          notify.error('IVR-Menu blev ikke oprettet.', menu.name);
        }
      } else {
        try {
          await _menuController.update(menu);
          notify.success('IVR-Menu blev opdateret.', menu.name);
        } catch (e, s) {
          _log.shout('Failed to update', e, s);
          notify.error('IVR-Menu blev ikke opdateret.', menu.name);
        }
      }

      onUpdate != null ? onUpdate(menu.name) : '';
    });

    _deleteButton.onClick.listen((_) => _deleteMenu());

    _menuInput.onInput.listen((_) {
      _checkInput();

      _saveButton.disabled = hasValidationError;
      _deleteButton.disabled = !_saveButton.disabled || hasValidationError;
    });

    _unfoldJson.onClick.listen((_) {
      _unfoldJson.hidden = true;
      _foldJson.hidden = false;
      _menuInput.value = _jsonpp.convert(menu);
      _resizeInput();
    });

    _foldJson.onClick.listen((_) {
      _foldJson.hidden = true;
      _unfoldJson.hidden = false;
      _menuInput.style.height = '';
      _menuInput.value = json.encode(menu);
      _resizeInput();
    });
  }

  void _resizeInput() {
    while (_menuInput.client.height < _menuInput.scrollHeight) {
      _menuInput.style.height = '${_menuInput.client.height + 10}px';
    }
  }
}
