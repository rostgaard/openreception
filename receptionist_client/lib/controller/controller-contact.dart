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

part of orc.controller;

class Contact {

  /// Constructor.
  Contact(this._store, this._notification) {
    _notification.onReceptionDataChange.listen((or_event.ReceptionData e) {
      _rcCache.remove(e.rid);
    });

    _notification.onContactChange.listen((or_event.ContactChange e) {
      if (e.isUpdate) {
        _rcCache.clear();
      }
    });
  }

  final service.RESTContactStore _store;
  final Notification _notification;
  final Map<int, Iterable<model.ReceptionContact>> _rcCache = {};

  /// Fetch the [model.BaseContact] identified by [cid] .
  Future<model.BaseContact> get(int cid) => _store.get(cid);

  /**
   * Return all the [model.BaseContact]'s that belong to the reception
   * reference [rRef].
   */
  Future<Iterable<model.ReceptionContact>> list(
      model.ReceptionReference rRef) async {
    if (!_rcCache.containsKey(rRef.id)) {
      _rcCache[rRef.id] = await _store.receptionContacts(rRef.id);
    }

    return _rcCache[rRef.id];
  }
}
