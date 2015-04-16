part of view;

class Contexts {
  Model.UIContexts _ui;

  Contexts(Model.UIModel this._ui) {
    _navigate.onGo.listen(_ui.toggleContext);

    _hotKeys.onAltQ.listen((_) => _navigate.goHome());
    _hotKeys.onAltW.listen((_) => _navigate.goHomeplus());
    _hotKeys.onAltE.listen((_) => _navigate.goMessages());
  }
}
