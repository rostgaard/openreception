part of orm.view;

/**
 * Visual representation of an endpoint collection belonging to a contact.
 */
class Endpoints {
  Logger _log = new Logger('$_libraryName.Endpoints');

  Function onChange;

  final controller.Contact _contactController;

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
    ..text = 'Beskedadresser'
    ..style.margin = '0px'
    ..style.padding = '0px 0px 4px 0px';

  final TextAreaElement _endpointsInput = new TextAreaElement()
    ..classes.add('wide');

  final ButtonElement _unfoldJson = new ButtonElement()
    ..text = 'Fold ud'
    ..classes.add('create');

  List<model.MessageEndpoint> _originalList = [];

  Endpoints(controller.Contact this._contactController) {
    _buttons.children = [_addNew, _foldJson, _unfoldJson];
    _header.children = [_label, _buttons];
    element.children = [_header, _endpointsInput];
    _observers();
  }

  void _observers() {
    _addNew.onClick.listen((_) {
      final model.MessageEndpoint template = new model.MessageEndpoint.empty()
        ..address = 'eksempel@domæne.dk'
        ..name = 'Navn'
        ..type = model.MessageEndpointType.emailTo;

      if (_unfoldJson.hidden) {
        _endpointsInput.value =
            _jsonpp.convert(endpoints.toList()..add(template));
      } else {
        endpoints = endpoints.toList()..add(template);
      }

      _resizeInput();

      if (onChange != null) {
        onChange();
      }
    });

    _unfoldJson.onClick.listen((_) {
      _unfoldJson.hidden = true;
      _foldJson.hidden = false;
      _endpointsInput.value = _jsonpp.convert(endpoints.toList());
      _resizeInput();
    });

    _foldJson.onClick.listen((_) {
      _foldJson.hidden = true;
      _unfoldJson.hidden = false;
      _endpointsInput.style.height = '';
      _endpointsInput.value = json.encode(endpoints.toList());
    });
  }

  /**
   *
   */
  void set endpoints(Iterable<model.MessageEndpoint> eps) {
    _originalList = eps.toList(growable: false);
    if (_unfoldJson.hidden) {
      _endpointsInput.value = _jsonpp.convert(_originalList);
    } else {
      _endpointsInput.value = json.encode(_originalList);
    }
  }

  /**
   *
   */
  Iterable<model.MessageEndpoint> get endpoints {
    final List epMaps = json.decode(_endpointsInput.value);

    return epMaps.map((map) =>
        new model.MessageEndpoint.fromJson(map));
  }

  void _resizeInput() {
    while (_endpointsInput.client.height < _endpointsInput.scrollHeight) {
      _endpointsInput.style.height = '${_endpointsInput.client.height + 10}px';
    }
  }
}
