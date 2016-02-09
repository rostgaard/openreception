library record.view;

import 'dart:async';
import 'dart:html';

import '../lib/eventbus.dart';
import '../notification.dart' as notify;

import 'package:openreception_framework/model.dart' as ORModel;
import 'package:management_tool/controller.dart' as Controller;

class RecordView {
  static const String viewName = 'record';
  DivElement element;

  final Controller.Reception _receptionController;
  final Controller.Dialplan _dialplanController;


  List<ORModel.Reception> receptions = new List<ORModel.Reception>();
  UListElement receptionListUL;
  InputElement receptionSearchBox;
  LIElement highlightedReceptionLI;
  ButtonElement newRecording;
  TextInputElement newFileName;
  int selectedOrganizationId;
  int selectedReceptionId;
  UListElement fileListUL;

  RecordView(DivElement this.element,
                     Controller.Reception this._receptionController, this._dialplanController) {
    receptionListUL = element.querySelector('#record-reception-list');
    receptionSearchBox = element.querySelector('#record-reception-search-box');
    newRecording = element.querySelector('#record-new-file-button');
    newFileName = element.querySelector('#record-new-file-name');

    fileListUL = element.querySelector('#record-file-list');

    refreshList();
    registrateEventHandlers();
  }

  void registrateEventHandlers() {
    receptionSearchBox.onInput.listen((_) => performSearch());

    bus.on(WindowChanged).listen((WindowChanged event) {
      element.classes.toggle('hidden', event.window != viewName);
    });

    newRecording.onClick.listen((_) {
      String fileName = newFileName.value;
      if(fileName != null && fileName.trim().isNotEmpty) {
        if(selectedReceptionId != null && selectedReceptionId > 0) {
          _dialplanController.recordSoundFile(selectedReceptionId, '${fileName}.wav').catchError((error) {
            notify.error('Der er skete en fejl med opringen.');
          });
        } else {
          notify.error('Der skal være valgt en reception før man kan starte optagelsen.');
        }
      } else {
        notify.error('Filnavnet må ikke være tomt.');
      }
    });
  }

  LIElement makeReceptionNode(ORModel.Reception reception) {
    LIElement li = new LIElement();
    return li
      ..classes.add('clickable')
      ..dataset['receptionid'] = '${reception.ID}'
      ..text = '${reception.fullName}'
      ..onClick.listen((_) {
        activateReception(reception.organizationId, reception.ID);
      });
  }

  void performSearch() {
    String searchText = receptionSearchBox.value;
    List<ORModel.Reception> filteredList = receptions.where((ORModel.Reception recep) =>
        recep.fullName.toLowerCase().contains(searchText.toLowerCase())).toList();
    renderReceptionList(filteredList);
  }

  Future refreshList() {
    return _receptionController.list().then((Iterable<ORModel.Reception> receptions) {

      this.receptions = receptions.toList();
      performSearch();
    });
  }

  void renderReceptionList(List<ORModel.Reception> receptions) {
    receptionListUL.children
        ..clear()
        ..addAll(receptions.map(makeReceptionNode));
  }

  void highlightContactInList(int id) {
    receptionListUL.children.forEach((LIElement li) => li.classes.toggle('highlightListItem', li.dataset['receptionid'] == '$id'));
  }

  void activateReception(int organization, int receptionId) {
    selectedOrganizationId = organization;
    selectedReceptionId = receptionId;

    highlightContactInList(receptionId);

    _dialplanController.getAudiofileList(receptionId).then((Iterable<ORModel.Audiofile> files) {
      fileListUL.children.clear();
      fileListUL.children.addAll(files.map(makeAudioFileNode));
    }).catchError((error) {
      notify.error('activateReception: ${error}');
    });
  }

  LIElement makeAudioFileNode(ORModel.Audiofile file) {
    LIElement li = new LIElement();

    SpanElement content = new SpanElement()
      ..text = file.shortname;
//    InputElement editBox = new InputElement(type: 'text');
//
//    editableSpan(content, editBox, () {
//      //TODO save changes. //Expand Dialplan Compiler and update where the file is used...
//      notify.info(content.text);
//    });

    ButtonElement play = new ButtonElement()
      ..text = 'Afspil'
      ..onClick.listen((_) {
      _dialplanController.recordSoundFile(selectedReceptionId, file.shortname).catchError((error) {
        notify.error('Det skete en fejl i forbindelse med oprettelsen af opkaldet. ${error}');
      });
    });

    ButtonElement delete = new ButtonElement()
      ..text = 'Slet'
      ..onClick.listen((_) {
      _dialplanController.deleteSoundFile(selectedReceptionId, file.shortname).then((_) {
        return activateReception(selectedOrganizationId, selectedReceptionId);
      }).catchError((error) {
        notify.error('Det skete en fejl, i forbindelse med sletningen af filen ${error}');
      });
    });

    /**
     * The Delete button is not rendered, because without any kind of check on
     * if the file is used, it will be too easy for the user to make a mistake.
     *
     * The same follows for the editBox(rename feature).
     */
    li.children.addAll([play, content ]); //delete, editBox

    return li;
  }
}
