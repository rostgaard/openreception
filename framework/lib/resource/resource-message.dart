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

part of orf.resource;

/// Protocol wrapper class for building homogenic REST resources across
/// servers and clients.
abstract class Message {
  static const String _ns = 'message';

  static Uri single(Uri host, int mid) =>
      Uri.parse('${util.removeTailingSlashes(host)}/$_ns/$mid');

  static Uri send(Uri host, int mid) =>
      Uri.parse('${util.removeTailingSlashes(host)}/$_ns/$mid/send');

  static Uri root(Uri host) =>
      Uri.parse('${util.removeTailingSlashes(host)}/$_ns');

  static Uri list(Uri host, {model.MessageFilter filter}) {
    String filterParameter =
        filter != null ? '?filter=${_json.encode(filter)}' : '';

    return Uri.parse(
        '${util.removeTailingSlashes(host)}/$_ns/list$filterParameter');
  }

  static Uri listDay(Uri host, DateTime day, {model.MessageFilter filter}) {
    final String filterParameter =
        filter != null ? '?filter=${_json.encode(filter)}' : '';

    final String dateString = day.toIso8601String().split('T').first;

    return Uri.parse('$host/message/list/$dateString$filterParameter');
  }

  static Uri listDrafts(Uri host, {model.MessageFilter filter}) {
    final String filterParameter =
        filter != null ? '?filter=${_json.encode(filter)}' : '';

    return Uri.parse('$host/message/list/drafts$filterParameter');
  }

  static Uri changeList(Uri host, [int mid]) {
    if (mid == null) {
      return Uri.parse('$host/$_ns/history');
    } else {
      return Uri.parse('$host/$_ns/$mid/history');
    }
  }
}
