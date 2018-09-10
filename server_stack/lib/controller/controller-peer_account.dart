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

library ors.controller.peer_account;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:orf/dialplan_tools.dart' as dialplanTools;
import 'package:orf/model.dart' as model;
import 'package:orf/storage.dart' as storage;
import 'package:ors/response_utils.dart';
import 'package:shelf/shelf.dart';
import 'package:xml/xml.dart' as xml;

/// PeerAccount controller class.
class PeerAccount {
  /**
   *
   */
  PeerAccount(this._userStore, this._compiler, this.fsConfPath);

  final Logger _log = Logger('server.controller.peer_account');
  final dialplanTools.DialplanCompiler _compiler;
  final storage.User _userStore;
  final String fsConfPath;

  /**
   *
   */
  Future<Response> deploy(Request request, final String uid) async {
    final model.PeerAccount account = await request.readAsString()
        .then(json.decode)
        .then(
            (map) => model.PeerAccount.fromJson(map));

    final model.User user = await _userStore.get(int.parse(uid));

    final String xmlFilePath =
        fsConfPath + '/directory/receptionists/${account.username}.xml';
    final List<String> generatedFiles = <String>[xmlFilePath];

    _log.fine(
        'Deploying peer account to file ${File(xmlFilePath).absolute.path}');
    File(xmlFilePath).writeAsStringSync(_compiler.userToXml(user, account));

    return okJson(generatedFiles);
  }

  /**
   *
   */
  Future<Response> get(Request request, final String aid) async {

    final String xmlFilePath = fsConfPath + '/directory/receptionists';
    final File xmlFile = File(xmlFilePath + '/$aid.xml');

    if (!(await xmlFile.exists())) {
      return notFound('No such file ${xmlFile.path}');
    }

    final document = xml.parse(await xmlFile.readAsString());

    final user = document
        .findAllElements('user')
        .first
        .attributes
        .where((attr) => attr.name.toString() == 'id')
        .first
        .value;

    final password = document
        .findAllElements('param')
        .where((node) => node.getAttribute('name') == 'password')
        .first
        .attributes
        .where((attr) => attr.name.toString() == 'value')
        .first
        .value;

    final callGroup = document
        .findAllElements('variable')
        .where((node) => node.getAttribute('name') == 'callgroup')
        .first
        .attributes
        .where((attr) => attr.name.toString() == 'value')
        .first
        .value;

    return okJson(model.PeerAccount(user, password, callGroup));
  }

  /**
   *
   */
  Future<Response> list(Request request) async {
    final String xmlFilePath = fsConfPath + '/directory/receptionists';

    bool isXmlFile(FileSystemEntity fse) =>
        fse is File && fse.path.toLowerCase().endsWith('.xml');

    final List<String> listing = List.from(Directory(xmlFilePath)
        .listSync()
        .where(isXmlFile)
        .map((fse) => fse.uri.pathSegments.last.split('.xml').first));

    return okJson(listing);
  }

  /**
   *
   */
  Future<Response> remove(Request request, final String aid ) async {

    final String xmlFilePath = fsConfPath + '/directory/receptionists/$aid.xml';

    final File peerAccount = File(xmlFilePath);

    if (!await peerAccount.exists()) {
      return notFound('No peer account for $aid');
    }

    await  File(xmlFilePath).delete();
    return okJson({});
  }
}
