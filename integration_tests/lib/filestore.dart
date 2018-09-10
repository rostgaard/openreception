library ort.filestore;

import 'package:orf/filestore.dart' as filestore;
import 'package:orf/model.dart' as model;
import 'package:ort/storage.dart' as storeTest;
import 'package:ort/support.dart';
import 'package:test/test.dart';

part 'filestore/filestore-calendar.dart';
part 'filestore/filestore-contact.dart';
part 'filestore/filestore-dialplan.dart';
part 'filestore/filestore-ivr.dart';
part 'filestore/filestore-message.dart';
part 'filestore/filestore-message_queue.dart';
part 'filestore/filestore-organization.dart';
part 'filestore/filestore-reception.dart';
part 'filestore/filestore-user.dart';

const String _namespace = 'filestore';

/// Run all filestore tests.
allTests() {
  _runReceptionTests();
  _runCalendarTests();
  _runContactTests();
  _runDialplanTests();
  _runIvrTests();
  _runOrganizationTests();
  _runUserTests();
  _runMessageTests();
  _runMessageQueueTests();
}
