part of orm.view;

class Contact {
  final Logger _log = new Logger('$_libraryName.Contact');
  final DivElement element = new DivElement()
    ..hidden = true
    ..id = 'contact-base-info';

  final controller.Contact _contactController;
  final controller.Calendar _calendarController;
  final controller.Reception _receptionController;

  Calendar _calendarView;
  Changelog _changelog;
  Changelog _receptionChangelog;

  final TextInputElement _nameInput = new TextInputElement()
    ..id = 'contact-input-name'
    ..classes.add('wide');

  final NumberInputElement _importCidInput = new NumberInputElement()
    ..style.width = '50%'
    ..placeholder = 'Kontakt ID at importere fra';
  final ButtonElement _importButton = new ButtonElement()
    ..classes.add('create')
    ..text = 'Importer';

  final SelectElement _typeInput = new SelectElement();
  final CheckboxInputElement _enabledInput = new CheckboxInputElement()
    ..id = 'contact-input-enabled';

  final ButtonElement _saveButton = new ButtonElement()
    ..text = 'Gem'
    ..classes.add('save');

  final ButtonElement _deleteButton = new ButtonElement()
    ..text = 'Slet'
    ..classes.add('delete');

  final HiddenInputElement _bcidInput = new HiddenInputElement()
    ..value = model.BaseContact.noId.toString();

  final HeadingElement _header = new HeadingElement.h2();

  final ButtonElement _joinReceptionbutton = new ButtonElement()
    ..text = 'Tilføj'
    ..id = 'contact-add';

  final AnchorElement _calendarToggle = new AnchorElement()
    ..href = '#calendar'
    ..text = 'Vis kalenderaftaler';

  final DivElement _receptionOuterSelector = new DivElement()
    ..id = 'contact-reception-selector';

  final DivElement _calendarsContainer = new DivElement()..style.clear = 'both';

  SearchComponent<model.ReceptionReference> _search;
  String _receptionToSearchboxString(
      model.ReceptionReference reception, String searchterm) {
    return '${reception.name}';
  }

  bool _receptionSearchHandler(
      model.ReceptionReference ref, String searchTerm) {
    return ref.name.toLowerCase().contains(searchTerm.toLowerCase());
  }

  /**
   * Loads a [model.BaseContact] into the view.
   */
  void set contact(model.BaseContact c) {
    _nameInput.value = c.name;
    _typeInput.options.forEach(
        (OptionElement option) => option.selected = option.value == c.type);
    _enabledInput.checked = c.enabled;

    _importButton.text = 'Importer';
    _importCidInput.value = '';
    _deleteButton.text = 'Slet';
    _bcidInput.value = c.id.toString();

    _calendarsContainer..hidden = true;
    _calendarToggle..text = 'Vis kalenderaftaler';

    if (c.id != model.BaseContact.noId) {
      _saveButton.disabled = true;
      _header.text =
          'Retter kontaktperson ${c.name} (cid: ${_bcidInput.value})';
    } else {
      _header.text = 'Opretter ny kontaktperson';

      _saveButton.disabled = false;
    }

    _deleteButton.disabled = !_saveButton.disabled;
    _joinReceptionbutton.disabled =
        c.id == model.BaseContact.noId || _saveButton.disabled;
    element.hidden = false;

    _typeInput.options.forEach(
        (OptionElement option) => option.selected = option.value == c.type);

    _contactController.changelog(c.id).then((String content) {
      _changelog.content = content;
    });

    _contactController.receptionChangelog(c.id).then((String content) {
      _receptionChangelog.content = content;
    });
  }

  /**
   * Extracts the [model.BaseContact] object from the view.
   */
  model.BaseContact get contact => new model.BaseContact.empty()
    ..id = int.parse(_bcidInput.value)
    ..enabled = _enabledInput.checked
    ..type = _typeInput.value
    ..name = _nameInput.value;

  /**
   * Default constructor.
   */
  Contact(this._contactController, this._calendarController,
      this._receptionController) {
    _calendarView = new Calendar(_calendarController);
    _changelog = new Changelog();
    _receptionChangelog = new Changelog();

    element.children = [
      _deleteButton,
      _saveButton,
      _header,
      _bcidInput,
      new DivElement()
        ..classes.add('col-1-2')
        ..children = [
          new DivElement()
            ..children = [new LabelElement()..text = 'Aktiv', _enabledInput],
          new DivElement()
            ..children = [new LabelElement()..text = 'Navn', _nameInput],
          new DivElement()
            ..children = [
              new LabelElement()..text = 'Importer receptioner fra kontakt',
              _importCidInput,
              _importButton
            ],
        ],
      new DivElement()
        ..classes.add('col-1-2')
        ..children = [
          new DivElement()
            ..children = [new LabelElement()..text = 'Type', _typeInput],
          new LabelElement()..text = 'Tilføj til Reception:',
          _receptionOuterSelector,
          _joinReceptionbutton
        ],
      new DivElement()
        ..style.clear = 'both'
        ..children = [_changelog.element, _receptionChangelog.element],
      new DivElement()
        ..style.clear = 'both'
        ..children = [_calendarToggle],
      _calendarsContainer
    ];

    _calendarsContainer
      ..children = [
        new HeadingElement.h4()..text = 'Kalender',
        _calendarView.element,
        new HeadingElement.h4()..text = 'Slettede KalenderPoster',
      ];

    _search = new SearchComponent<model.ReceptionReference>(
        _receptionOuterSelector, 'contact-reception-searchbox')
      ..listElementToString = _receptionToSearchboxString
      ..searchFilter = _receptionSearchHandler
      ..searchPlaceholder = 'Søg...';

    _typeInput.children.addAll(model.ContactType.types
        .map((type) => new OptionElement(data: type, value: type)));
    _fillSearchComponent();

    _observers();
  }

  /**
   *
   */
  void clear() {
    contact = new model.BaseContact.empty();
    _header.text = 'Henter...';
  }

  /**
   *
   */
  void _observers() {
    _nameInput.onInput.listen((_) {
      _saveButton.disabled = false;
      _deleteButton.disabled = !_saveButton.disabled;
      _joinReceptionbutton.disabled =
          contact.id == model.BaseContact.noId || _saveButton.disabled;
    });

    _enabledInput.onChange.listen((_) {
      _saveButton.disabled = false;
      _deleteButton.disabled = !_saveButton.disabled;
      _joinReceptionbutton.disabled =
          contact.id == model.BaseContact.noId || _saveButton.disabled;
    });

    _typeInput.onChange.listen((_) {
      _saveButton.disabled = false;
      _deleteButton.disabled = !_saveButton.disabled;
      _joinReceptionbutton.disabled =
          contact.id == model.BaseContact.noId || _saveButton.disabled;
    });

    _importCidInput.onInput.listen((_) {
      _saveButton.disabled = true;
      _deleteButton.disabled = true;
      _joinReceptionbutton.disabled = true;
    });

    _calendarView.onDelete = () async {
      _calendarView.loadEntries(new model.OwningContact(contact.id));
    };

    _calendarToggle.onClick.listen((_) async {
      _calendarsContainer.hidden = !_calendarsContainer.hidden;

      _calendarToggle.text = _calendarsContainer.hidden
          ? 'Vis kalenderaftaler'
          : 'Skjul kalenderaftaler';

      if (!_calendarsContainer.hidden) {
        await _calendarView.loadEntries(new model.OwningContact(contact.id));
      }
    });

    _saveButton.onClick.listen((_) async {
      model.BaseContact updated;
      if (contact.id == model.BaseContact.noId) {
        updated = await _contactController.create(contact);
        notify.success('Oprettede kontaktperson', '${updated.name}');
      } else {
        updated = contact;
        await _contactController.update(contact);
        notify.success('Opdaterede kontaktperson', '${updated.name}');
      }
      _saveButton.disabled = false;
      _deleteButton.disabled = !_saveButton.disabled;
      contact = await _contactController.get(updated.id);
    });

    /**
     * TODO: Fix this hunk-o-old-crap.
     */
    _importButton.onClick.listen((_) async {
      int sourceCid;
      final String confirmationText =
          'Bekræft import (slet cid:${_importCidInput.value})';

      if (_importCidInput.value.isEmpty) {
        return null;
      }

      if (_importButton.text != confirmationText) {
        _importButton.text = confirmationText;
        _saveButton.disabled = true;
        _deleteButton.disabled = true;
      } else {
        try {
          sourceCid = int.parse(_importCidInput.value);

          if (sourceCid == contact.id) {
            notify.error('"${_importCidInput.value}" er egen ID', '');
            return null;
          }
        } on FormatException {
          notify.error('"${_importCidInput.value}" er ikke et tal', '');
          return null;
        }

        try {
          final int dcid = contact.id;
          final List<model.ReceptionReference> rRefs =
              await _contactController.receptions(sourceCid);

          await Future.wait(rRefs.map((model.ReceptionReference rRef) async {
            final model.ReceptionAttributes contactData =
                await _contactController.getByReception(sourceCid, rRef.id);
            contactData.cid = dcid;
            contactData.receptionId = rRef.id;
            await _contactController.addToReception(contactData);
          }));

          /// Import calender entries
          final Iterable<model.CalendarEntry> entries =
              await _calendarController.listContact(sourceCid);

          _log.finest('Found calendar list : ${entries.join(', ')}');

          await Future.wait(entries.map((ce) async {
            ce..id = model.CalendarEntry.noId;

            _log.finest('Adding calendar entry ${ce.toJson()} to cid:$dcid');

            await _calendarController.create(ce, new model.OwningContact(dcid));
          }));

          _log.finest('Deleting cid:$sourceCid');
          await _contactController.remove(sourceCid);

          notify.success(
              'Tilføjede ${contact.name} til ${rRefs.length} receptioner', '');

          contact = await _contactController.get(dcid);
        } on NotFound {
          notify.error('cid:${sourceCid} Findes ikke', '');

          return null;
        }
      }
    });

    _joinReceptionbutton.onClick.listen((_) async {
      await _addToReception(_search.currentElement);
    });
    _deleteButton.onClick.listen((_) => _deleteSelectedContact());
  }

  /**
     *
     */
  Future _addToReception(model.ReceptionReference rRef) async {
    if (_search.currentElement != null && int.parse(_bcidInput.value) > 0) {
      final model.ReceptionAttributes template =
          new model.ReceptionAttributes.empty()
            ..receptionId = rRef.id
            ..cid = contact.id;

      try {
        model.ReceptionContact ref = await _contactController.addToReception(
            template);

        notify.success('Tilføjede kontaktperson til reception',
            '${contact.name} til ${rRef.name}');
      } catch (e) {
        notify.error(
            'Kunne ikke tilføje kontaktperson til reception', 'Fejl: ${e}');
      }
    }
  }

  /**
   *
   */
  Future _deleteSelectedContact() async {
    _log.finest('Deleting contact cid${contact.id}');
    final String confirmationText = 'Bekræft sletning af cid: ${contact.id}?';

    if (_deleteButton.text != confirmationText) {
      _deleteButton.text = confirmationText;
      return;
    }

    try {
      _deleteButton.disabled = true;

      await _contactController.remove(contact.id);
      notify.success('Kontaktperson slettet', contact.name);
      element.hidden = true;

      _joinReceptionbutton.disabled = true;
      contact = new model.BaseContact.empty();
    } catch (error) {
      notify.error('Kunne ikke slette kontaktperson', contact.name);
      _log.severe('Delete baseContact failed with: ${error}');
    }

    _deleteButton.text = 'Slet';
  }

  void _fillSearchComponent() {
    _receptionController
        .list()
        .then((Iterable<model.ReceptionReference> receptions) {
      int compareTo(
              model.ReceptionReference rs1, model.ReceptionReference rs2) =>
          rs1.name.compareTo(rs2.name);

      List<model.ReceptionReference> list = receptions.toList()
        ..sort(compareTo);

      _search.updateSourceList(list);
    });
  }
}
