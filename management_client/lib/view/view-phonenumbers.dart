part of orm.view;

class Phonenumbers {
  final Logger _log = new Logger('$_libraryName.Phonenumbers');

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
    ..text = 'Telefonnumre'
    ..style.margin = '0px'
    ..style.padding = '0px 0px 4px 0px';

  final TextAreaElement _phonenumberInput = new TextAreaElement()
    ..classes.add('wide')
    ..text = '[]';

  final ButtonElement _unfoldJson = new ButtonElement()
    ..text = 'Fold ud'
    ..classes.add('create');

  Phonenumbers() {
    _buttons.children = [_addNew, _foldJson, _unfoldJson];
    _header.children = [_label, _buttons];
    element.children = [_header, _phonenumberInput];
    _observers();
  }

  void _observers() {
    _addNew.onClick.listen((_) {
      final model.PhoneNumber pn = new model.PhoneNumber.empty()
        ..confidential = true
        ..note = 'Kort beskrivelse'
        ..destination = '00000000';

      if (_unfoldJson.hidden) {
        _phonenumberInput.value =
            _jsonpp.convert(phoneNumbers.toList()..add(pn));
      } else {
        phoneNumbers = phoneNumbers.toList()..add(pn);
      }

      _resizeInput();

      if (onChange != null) {
        onChange();
      }
    });

    _phonenumberInput.onInput.listen((_) {
      _validationError = false;
      _phonenumberInput.classes.toggle('error', false);
      try {
        final dlist = phoneNumbers;

        ///TODO: Validate endpoints
      } on FormatException {
        _validationError = true;
        _phonenumberInput.classes.toggle('error', true);
      }

      if (onChange != null) {
        onChange();
      }
    });

    _unfoldJson.onClick.listen((_) {
      _unfoldJson.hidden = true;
      _foldJson.hidden = false;
      _phonenumberInput.value = _jsonpp.convert(phoneNumbers.toList());
      _resizeInput();
    });

    _foldJson.onClick.listen((_) {
      _foldJson.hidden = true;
      _unfoldJson.hidden = false;
      _phonenumberInput.style.height = '';
      _phonenumberInput.value = json.encode(phoneNumbers.toList());
    });
  }

  void set phoneNumbers(Iterable<model.PhoneNumber> pns) {
    if (_unfoldJson.hidden) {
      _phonenumberInput.value = _jsonpp.convert(pns.toList());
    } else {
      _phonenumberInput.value = json.encode(pns.toList());
    }
  }

  /**
   *
   */
  Iterable<model.PhoneNumber> get phoneNumbers {
    final List pnMaps = json.decode(_phonenumberInput.value);

    return pnMaps
        .map((m) => new model.PhoneNumber.fromJson(m as Map<String, dynamic>));
  }

  void _resizeInput() {
    while (_phonenumberInput.client.height < _phonenumberInput.scrollHeight) {
      _phonenumberInput.style.height =
          '${_phonenumberInput.client.height + 10}px';
    }
  }
}
