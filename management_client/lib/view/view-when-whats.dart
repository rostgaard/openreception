part of orm.view;

class WhenWhats {
  final Logger _log = new Logger('$_libraryName.WhenWhats');

  Function onChange;

  final DivElement element = new DivElement();
  final DivElement _header = new DivElement()
    ..style.display = 'flex'
    ..style.justifyContent = 'space-between'
    ..style.alignItems = 'flex-end'
    ..style.width = '97%'
    ..style.paddingLeft = '10px';
  final DivElement _buttons = new DivElement();
  bool _validationError = false;
  bool get validationError => _validationError;

  final ButtonElement _addNew = new ButtonElement()
    ..text = 'Indsæt ny tom'
    ..classes.add('create');

  final ButtonElement _foldJson = new ButtonElement()
    ..text = 'Fold sammen'
    ..classes.add('create')
    ..hidden = true;

  final HeadingElement _label = new HeadingElement.h3()
    ..text = 'WhenWhat'
    ..style.margin = '0px'
    ..style.padding = '0px 0px 4px 0px';

  final TextAreaElement _whenWhatInput = new TextAreaElement()
    ..classes.add('wide');

  final ButtonElement _unfoldJson = new ButtonElement()
    ..text = 'Fold ud'
    ..classes.add('create');

  WhenWhats() {
    _buttons.children = [_addNew, _foldJson, _unfoldJson];
    _header.children = [_label, _buttons];
    element.children = [_header, _whenWhatInput];
    _observers();
  }

  void _observers() {
    _addNew.onClick.listen((_) {
      final model.WhenWhat ww =
          new model.WhenWhat('mon-fri 12:00-12:30', 'Frokost');

      if (_unfoldJson.hidden) {
        _whenWhatInput.value = _jsonpp.convert(whenWhats.toList()..add(ww));
      } else {
        whenWhats = whenWhats.toList()..add(ww);
      }

      _resizeInput();

      if (onChange != null) {
        onChange();
      }
    });

    _whenWhatInput.onInput.listen((_) {
      _validationError = false;
      _whenWhatInput.classes.toggle('error', false);
      try {
        final List<String> errors = <String>[];
        for (model.WhenWhat whenWhat in whenWhats) {
          errors.addAll(whenWhat.check);
        }
        if (errors.isNotEmpty) {
          _validationError = true;
          _whenWhatInput.classes.toggle('error', true);
        }
      } on FormatException {
        _validationError = true;
        _whenWhatInput.classes.toggle('error', true);
      }

      if (onChange != null) {
        onChange();
      }
    });

    _unfoldJson.onClick.listen((_) {
      _unfoldJson.hidden = true;
      _foldJson.hidden = false;
      _whenWhatInput.value = _jsonpp.convert(whenWhats.toList());
      _resizeInput();
    });

    _foldJson.onClick.listen((_) {
      _foldJson.hidden = true;
      _unfoldJson.hidden = false;
      _whenWhatInput.style.height = '';
      _whenWhatInput.value = json.encode(whenWhats.toList());
    });
  }

  void set whenWhats(Iterable<model.WhenWhat> wws) {
    if (_unfoldJson.hidden) {
      _whenWhatInput.value = _jsonpp.convert(wws.toList());
    } else {
      _whenWhatInput.value = json.encode(wws.toList());
    }
  }

  Iterable<model.WhenWhat> get whenWhats => json
          .decode(_whenWhatInput.value)
          .map((Map<String, dynamic> m) => new model.WhenWhat.fromJson(m))
      as Iterable<model.WhenWhat>;

  void _resizeInput() {
    while (_whenWhatInput.client.height < _whenWhatInput.scrollHeight) {
      _whenWhatInput.style.height = '${_whenWhatInput.client.height + 10}px';
    }
  }
}
