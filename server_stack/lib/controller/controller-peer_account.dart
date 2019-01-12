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

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:xml/xml.dart' as xml;

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart' as shelf_route;
import 'package:logging/logging.dart';

import 'package:orf/model.dart' as model;
import 'package:orf/storage.dart' as storage;
import 'package:orf/dialplan_tools.dart' as dialplanTools;

import 'package:ors/response_utils.dart';

const _json = const JsonCodec();

/**
 * PeerAccount controller class.
 */
class PeerAccount {
  final Logger _log = new Logger('server.controller.peer_account');
  final dialplanTools.DialplanCompiler _compiler;
  final storage.User _userStore;
  final String fsConfPath;

  /**
   *
   */
  PeerAccount(this._userStore, this._compiler, this.fsConfPath);

  /**
   *
   */
  Future<shelf.Response> deploy(shelf.Request request) async {
    final int uid = int.parse(shelf_route.getPathParameter(request, 'uid'));
    final model.PeerAccount account = await request
        .readAsString()
        .then(_json.decode)
        .then(
            (Map<String, dynamic> map) => new model.PeerAccount.fromJson(map));

    final model.User user = await _userStore.get(uid);

    final String xmlFilePath =
        fsConfPath + '/directory/receptionists/${account.username}.xml';
    final List<String> generatedFiles = new List<String>.from([xmlFilePath]);

    _log.fine(
        'Deploying new peer account to file ${new File(xmlFilePath).absolute.path}');
    new File(xmlFilePath).writeAsStringSync(_compiler.userToXml(user, account));

    return okJson(generatedFiles);
  }

  /**
   *
   */
  Future<shelf.Response> get(shelf.Request request) async {
    final String accountName = shelf_route.getPathParameter(request, 'aid');

    final String xmlFilePath = fsConfPath + '/directory/receptionists';
    final File xmlFile = new File(xmlFilePath + '/$accountName.xml');

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

    final callgroup = document
        .findAllElements('variable')
        .where((node) => node.getAttribute('name') == 'callgroup')
        .first
        .attributes
        .where((attr) => attr.name.toString() == 'value')
        .first
        .value;

    return okJson(new model.PeerAccount(user, password, callgroup));
  }

  /**
   *
   */
  Future<shelf.Response> list(shelf.Request request) async {
    final String xmlFilePath = fsConfPath + '/directory/receptionists';

    bool isXmlFile(FileSystemEntity fse) =>
        fse is File && fse.path.toLowerCase().endsWith('.xml');

    final List<String> listing = new List.from(new Directory(xmlFilePath)
        .listSync()
        .where(isXmlFile)
        .map((fse) => fse.uri.pathSegments.last.split('.xml').first));

    return okJson(listing);
  }

  /**
   *
   */
  Future<shelf.Response> remove(shelf.Request request) async {
    final String aid = shelf_route.getPathParameter(request, 'aid');

    final String xmlFilePath = fsConfPath + '/directory/receptionists/$aid.xml';

    final File peerAccount = new File(xmlFilePath);

    if (!await peerAccount.exists()) {
      return notFound('No peer account for $aid');
    }

    await new File(xmlFilePath).delete();
    return okJson({});
  }
}
