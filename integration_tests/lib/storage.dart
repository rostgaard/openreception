library ort.storage;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:orf/exceptions.dart';
import 'package:orf/model.dart' as model;
import 'package:orf/storage.dart' as storage;
import 'package:ort/support.dart';
import 'package:test/test.dart';

part 'storage/storage-calendar.dart';
part 'storage/storage-contact.dart';
part 'storage/storage-dialplan.dart';
part 'storage/storage-ivr.dart';
part 'storage/storage-message.dart';
part 'storage/storage-message_queue.dart';
part 'storage/storage-organization.dart';
part 'storage/storage-reception.dart';
part 'storage/storage-user.dart';

const String _libraryName = 'storage';

final notFoundError = new TypeMatcher<NotFound>();
final unchangedError = new TypeMatcher<Unchanged>();
