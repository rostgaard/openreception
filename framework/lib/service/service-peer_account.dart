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

/// Peer account service client class.
///
/// The client class wraps REST methods and handles lower-level
/// communication, such as serialization/deserialization, method choice
/// (GET, PUT, POST, DELETE) and resource uri building./
class PeerAccount {
  PeerAccount(Uri host, String token, dynamic _backend) : _client =
  api.PeerAccountApi(api.ApiClient(basePath: host.toString())) {
    _client.apiClient
        .getAuthentication<api.ApiKeyAuth>('ApiKeyAuth')
        .apiKey = token;
  }

  final api.PeerAccountApi _client;

  Future<model.PeerAccount> get(String accountName) async {
    try {
      return await _client.peerAccount(accountName);
      } on api.ApiException catch (e)
      {
        WebService.checkResponse(e.code, "GET", null, e.message);
        throw e;
      }
    }

  Future<List<model.PeerAccount>> list() async {
    try {
      return _client.peerAccounts();

    } on api.ApiException catch (e) {
      WebService.checkResponse(e.code, "GET", null, e.message);
      throw e;
    }
  }

  /// (Re-)deploys a [model.PeerAccount] for user with [uid].
  Future<Iterable<dynamic>> deployAccount(model.PeerAccount account,
      int uid) async => _client.deployPeerAccount(account.username);

  Future<Null> remove(String username) async {
    await _client.deletePeerAccount(username);
  }
}
