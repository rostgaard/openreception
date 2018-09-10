/*                  This file is part of OpenReception
                   Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orc.model;

/// Provides methods for manipulating the visibility of the loading view.
class UIORCLoading {

  /// Constructor.
  UIORCLoading(String id) {
    _myRoot = querySelector('#$id');
  }
  DivElement _myRoot;
  
  DivElement get _loadingProgressMessages =>
      _myRoot.querySelector('div.loading-progress');

  /// Set visibility according to [value].
  set visible(bool value) {
    _myRoot.style.display = value ? 'flex' : 'none';
  }

  void addLoadingMessage(String message) {
    _loadingProgressMessages.children.add(SpanElement()..text = message);
  }
}
