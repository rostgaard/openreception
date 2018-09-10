library orm.controller;

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:logging/logging.dart';
import 'package:orf/event.dart' as event;
import 'package:orf/exceptions.dart';
import 'package:orf/model.dart' as model;
import 'package:orf/service.dart' as service;

part 'controller/controller-calendar.dart';
part 'controller/controller-call.dart';
part 'controller/controller-cdr.dart';
part 'controller/controller-contact.dart';
part 'controller/controller-dialplan.dart';
part 'controller/controller-ivr.dart';
part 'controller/controller-message.dart';
part 'controller/controller-notification.dart';
part 'controller/controller-organization.dart';
part 'controller/controller-peer_account.dart';
part 'controller/controller-popup.dart';
part 'controller/controller-reception.dart';
part 'controller/controller-user.dart';

const String _libraryName = 'controller';

final Popup popup = new Popup(
    new Uri.file('image/popup_error.png'),
    new Uri.file('image/popup_info.png'),
    new Uri.file('image/popup_success.png'));

Function onForbidden = () => null;

void _handleError(e) {
  if (e is Forbidden) {
    onForbidden();
  } else {
    throw e;
  }
}
