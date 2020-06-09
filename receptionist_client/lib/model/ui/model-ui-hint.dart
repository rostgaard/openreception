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

/**
 * Provides methods for manipulating the hint related UIX parts.
 */
class UIHint {
  /**
   * Constructor.
   */
  UIHint();

  ElementList<DivElement> get _hintElements => querySelectorAll('div.hint');

  /**
   * Toggle the hidden class on all the [_hintElements]
   */
  void toggleHint() {
    _hintElements.forEach((DivElement hint) {
      hint.classes.toggle('hidden');

      if (!hint.classes.contains('hidden')) {
        final num parentWidth = hint.parent.getClientRects().first.width;
        final num hintWidth = hint.getClientRects().first.width;

        hint.style.left = '${(parentWidth - hintWidth)~/2}px';
      }
    });
  }
}
