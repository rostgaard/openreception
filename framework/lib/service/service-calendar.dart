/*                  This file is part of OpenReception
                   Copyright (C) 2014-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.service;

/// Calendar store client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building.
class RESTCalendarStore implements storage.Calendar {

  RESTCalendarStore(Uri host, String token, dynamic _backend) : _client =
  api.CalendarApi(api.ApiClient(basePath: host.toString())) {
    _client.apiClient.getAuthentication<api.ApiKeyAuth>('ApiKeyAuth').apiKey =
        token;
  }

  final api.CalendarApi _client;


  @override
  Future<model.CalendarEntry> create(
      model.CalendarEntry entry, model.Owner owner, model.User user) async {
    try {
      return _client.createCalendarEntry(owner.toString(), entry);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }



  @override
  Future<List<model.CalendarEntry>> list(model.Owner owner) async {
    try {
      return _client.listCalendarEntries(owner.toString());
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<Null> remove(int eid, model.Owner owner, model.User user) async {
    try {
      return _client.deleteCalendarEntry(owner.toString(), eid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<model.CalendarEntry> update(
      model.CalendarEntry entry, model.Owner owner, model.User modifier) async {
    try {
      return _client.updateCalendarEntry(owner.toString(), entry.id, entry);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<model.CalendarEntry> get(int eid, model.Owner owner) {
    try {
      return _client.getCalendarEntry(owner.toString(), eid);
    } on api.ApiException catch(e) {
      WebService.checkResponse(e.code,"GET" , null, e.message);
      throw e;
    }
  }

  @override
  Future<List<model.Commit>> changes(model.Owner owner, [int eid]) {
    // TODO: implement changes
    return null;
  }
}
