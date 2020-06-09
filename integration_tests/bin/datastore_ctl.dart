import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:orf/exceptions.dart';
import 'package:orf/filestore.dart' as filestore;
import 'package:orf/model.dart' as model;
import 'package:ort/support.dart' show Randomizer;

//import 'package:args/args.dart';

Random _rand = Random(DateTime.now().millisecondsSinceEpoch);

/// Returns a random element from [pool].
dynamic randomChoice(List pool) {
  if (pool.isEmpty) {
    throw ArgumentError('Cannot find a random value in an empty list');
  }

  int index = _rand.nextInt(pool.length);

  return pool[index];
}

final model.User _systemUser = model.User()..name = 'datastore_ctl';

/**
 * Logs [record] to STDOUT | STDERR depending on [record] level.
 */
void logEntryDispatch(LogRecord record) {
  final String error = '${record.error != null ? ' - ${record.error}' : ''}'
      '${record.stackTrace != null ? ' - ${record.stackTrace}' : ''}';

  if (record.level.value > Level.INFO.value) {
    stderr.writeln('${record.time} - ${record}$error');
  } else {
    stdout.writeln('${record.time} - ${record}$error');
  }
}

/// Mock object generation command.
class _GenerateCommand extends Command {
  @override
  final name = 'generate';
  final description = 'Generate mock objects and store them in the datastore.\n'
      'If the store is reused, the existing objects will count towards the total '
      'and cause the generation count to be lower.';

  final Logger _log = Logger('generate');

  _GenerateCommand() {
    // [argParser] is automatically created by the parent class.
    argParser
      ..addOption('filestore',
          abbr: 'f', help: 'Path to where the filestore is created')
      ..addFlag('reuse-store', negatable: false)
      ..addOption('organizations', help: 'Generates this many organizations.')
      ..addOption('receptions', help: 'Generates this many receptions.')
      ..addOption('contacts', help: 'Generates this many contacts.')
      ..addOption('reception-attr',
          help: 'Generates this many reception attribute sets.')
      ..addOption('users', help: 'Generates this many users.')
      ..addOption('dialplans', help: 'Generates this many dialplans.')
      ..addOption('ivrs', help: 'Generates this many ivr menus.');
  }

  model.ReceptionDialplan _generateDialplan() {
    final DateTime now = DateTime.now();

    model.OpeningHour justNow = model.OpeningHour.empty()
      ..fromDay = model.toWeekDay(now.weekday)
      ..toDay = model.toWeekDay(now.weekday)
      ..fromHour = now.hour
      ..toHour = now.hour + 1
      ..fromMinute = now.minute
      ..toMinute = now.minute;

    model.ReceptionDialplan rdp = model.ReceptionDialplan()
      ..open = [
        model.HourAction()
          ..hours = [justNow]
          ..actions = [
            model.Notify('call-offer'),
            model.Ringtone(1),
            model.Playback('non-existing-file.wav'),
            model.Enqueue('waitqueue')
          ]
      ]
      ..extension = 'test-${Randomizer.randomPhoneNumber()}'
          '-${DateTime.now().millisecondsSinceEpoch}'
      ..defaultActions = [model.Playback('sorry-dude-were-closed')];

    return rdp;
  }

  String get fileStorePath {
    final String value = argResults['filestore'];

    if (value == null || value.isEmpty) {
      throw UsageException('filestore parameter must be supplied', '');
    }

    return value;
  }

  bool get reuseStore => argResults['reuse-store'];

  /// Casts the value of [argumentName] to an integer.
  ///
  /// Returns 0 if the [argumentName] is not supplied, and throws
  /// a [UsageException] if the argument value is not a valid integer.
  int _argToInt(ArgResults argResults, String argName) {
    if (argResults[argName] == null) {
      return 0;
    }

    try {
      return int.parse(argResults[argName]);
    } on FormatException {
      throw UsageException(
          'Agument value for \'$argName\' is not a valid integer', '');
    }
  }

  Future run() async {
    print(argResults.arguments);
    final int receptionCount = _argToInt(argResults, 'receptions');
    final int organizationCount = _argToInt(argResults, 'organizations');
    final int receptionAttrCount = _argToInt(argResults, 'reception-attr');
    final int dialplanCount = _argToInt(argResults, 'dialplans');
    final int contactCount = _argToInt(argResults, 'contacts');
    final int ivrCount = _argToInt(argResults, 'ivrs');
    final int userCount = _argToInt(argResults, 'users');

    final Directory fsDir = Directory(fileStorePath);
    if (fsDir.existsSync() && !reuseStore) {
      throw UsageException(
          'Filestore path already exist. '
              'Please supply a non-existing path or use the --reuse-store flag.',
          '');
    }

    final datastore = filestore.DataStore(fileStorePath);

    // Create users.
    if (userCount > 0) {
      _log.info('Creating  ${userCount} test-users');
      (await Future.wait(List(userCount).map((_) async {
        final randUser = Randomizer.randomUser();
        final org = await datastore.userStore.create(randUser, _systemUser);

        _log.info('Created user ${org.name}');
      })))
          .toList(growable: false);
    }

    // Create organizations.
    if (organizationCount > 0) {
      _log.info('Creating  ${organizationCount} test-organizations');
      (await Future.wait(List(organizationCount).map((_) async {
        final randOrg = Randomizer.randomOrganization();
        final org =
            await datastore.organizationStore.create(randOrg, _systemUser);

        _log.info('Created organization ${org.name}');
      })))
          .toList(growable: false);
    }

    // Load the current list of organizations.
    final List<model.OrganizationReference> orgs =
        (await datastore.organizationStore.list()).toList(growable: false);

    // Create receptions.
    if (receptionCount > 0 && orgs.isEmpty) {
      throw UsageException(
          'Cannot create receptions in datastore with no organizations',
          'Please create at least one organization before creating reception.');
    }

    if (receptionCount > 0) {
      _log.info('Creating  ${receptionCount} test-receptions');
      await Future.wait(List(receptionCount).map((_) async {
        final org = await randomChoice(orgs);
        final randRec = Randomizer.randomReception()..oid = org.id;

        final rec = await datastore.receptionStore.create(randRec, _systemUser);

        _log.info('Created reception ${rec.name} owned by ${org.name}');

        return rec;
      }));
    }

    // Load the current list of receptions.
    final List<model.ReceptionReference> recs =
        (await datastore.receptionStore.list()).toList(growable: false);

    // Create contacts.
    if (contactCount > 0) {
      _log.info('Creating  ${contactCount} test-contacts');
      await Future.wait(List(contactCount).map((_) async {
        final newContact = Randomizer.randomBaseContact();

        final con =
            await datastore.contactStore.create(newContact, _systemUser);

        _log.info('Created contact ${con.name}');
        return con;
      }));
    }

    // Load the current list of contacts.
    final List<model.BaseContact> cons =
        (await datastore.contactStore.list()).toList(growable: false);

    // Create reception attributes.
    if (receptionAttrCount > 0 && cons.isEmpty) {
      throw UsageException(
          'Cannot create reception attributes in datastore with no contacts',
          'Please create at least one contact before creating reception'
              'attribute sets .');
    }

    // Generate reception attribute sets.
    await Future.wait(List(receptionAttrCount).map((_) async {
      final con = randomChoice(cons);
      final rec = randomChoice(recs);

      try {
        await datastore.contactStore.data(con.id, rec.id);
        _log.warning(
            'Skipping adding contact ${con.name} to reception ${rec.name}.'
            ' Contact already exist in reception.');
      } on NotFound {
        final attributes = Randomizer.randomAttributes();
        attributes
          ..cid = con.id
          ..receptionId = rec.id;

        await datastore.contactStore.addData(attributes, _systemUser);

        _log.info('Adding contact ${con.name} to reception ${rec.name}');
      } on ClientError {
        _log.warning(
            'Failed Adding contact ${con.name} to reception ${rec.name}');
      }
    }));

    // Create dialplans
    if (dialplanCount > 0) {
      _log.info('Creating  ${dialplanCount} test-dialplans');
      await Future.wait(List(dialplanCount).map((_) async {
        final dp = _generateDialplan();

        await datastore.receptionDialplanStore.create(dp, _systemUser);
        _log.info('Created dialplan ${dp.extension}');
        return dp;
      }));
    }

    // Create IVR menus
    if (ivrCount > 0) {
      _log.info('Creating  ${ivrCount} test-ivr-menus');
      await Future.wait(List(ivrCount).map((_) async {
        final menu = Randomizer.randomIvrMenu();

        await datastore.ivrStore.create(menu, _systemUser);
        _log.info('Created IVR menu ${menu.name}');
        return menu;
      }));
    }
  }
}

class _ManageCommand extends Command {
  @override
  final name = 'manage';
  final description = 'Manage different configuration setting and global'
      'flags of the datastore.';

  /// The filesystem path to the filestore.
  ///
  /// Throws [UsageException] if the passed value is empty or unsupplied.
  String get fileStorePath {
    final String value = argResults['filestore'];

    if (value == null || value.isEmpty) {
      throw UsageException('filestore parameter must be supplied', '');
    }

    return value;
  }

  _ManageCommand() {
    // [argParser] is automatically created by the parent class.
    argParser
      ..addOption('filestore',
          abbr: 'f',
          help: 'Path to the filestore. '
              'A path is created in ${Directory.systemTemp.path}, '
              'if omitted.')
      ..addFlag('reuse-store', negatable: false)
      ..addOption('add-admin-identity',
          help: 'Add a user with supplied'
              ' admin identity.');
  }

  // [run] may also return a Future.
  Future run() async {
    if (!Directory(fileStorePath).existsSync()) {
      throw UsageException('Path ${fileStorePath} does not exist', '');
    }

    final filestore.DataStore datastore = filestore.DataStore(fileStorePath);

    final String adminIdentity = argResults['add-admin-identity'];

    try {
      await datastore.userStore.getByIdentity(adminIdentity);

      throw UsageException(
          'User with identity ${adminIdentity} already exists', '');
    } on NotFound {
      final user = model.User()
        ..address = adminIdentity
        ..identities = List.from([adminIdentity])
        ..groups = List.from([model.UserGroups.administrator]);

      await datastore.userStore.create(user, _systemUser);
    }
  }
}

class _CreateCommand extends Command {
  @override
  final name = 'create';
  final description = 'Create a filestore'
      'flags of the datastore.';
  final Logger _log = Logger('create');

  String get fileStorePath {
    final String value = argResults['filestore'];

    if (value == null || value.isEmpty) {
      throw UsageException('filestore parameter must be supplied', '');
    }

    return value;
  }

  _CreateCommand() {
    // [argParser] is automatically created by the parent class.
    argParser
      ..addOption('filestore',
          abbr: 'f', help: 'Path to where the filestore is created');
  }

  // [run] may also return a Future.
  Future run() async {
    if (Directory(fileStorePath).existsSync()) {
      throw UsageException('Path $fileStorePath already exists', '');
    } else {
      Directory(fileStorePath).createSync();
    }

    final datastore = filestore.DataStore(fileStorePath);
    _log.info('Created filestore in $fileStorePath');

    final user = model.User()
      ..address = ''
      ..groups = List.from([model.UserGroups.administrator]);

    await datastore.userStore.create(user, _systemUser);
  }
}

// class _DatastoreCtrlConfig {
//   final bool showHelp;
//   final bool reuseStore;
//   final String datastorePath;
//   final int receptionCount;
//   final int organizationCount;
//   final int receptionDataCount;
//   final int dialplanCount;
//   final int contactCount;
//   final int ivrCount;
//   final int userCount;
//   final ArgParser parser;
//
//   factory _DatastoreCtrlConfig.fromArguments(List<String> args) {
//     var runner = CommandRunner(
//         'datastore_ctl',
//         'OpenReception Datastore'
//         'modification and mock object generation tool');
//
//     // final parser = ArgParser()
//     //   ..addFlag('help', abbr: 'h', help: 'Output this help', negatable: false)
//     //   ..addOption('filestore',
//     //       abbr: 'f',
//     //       help: 'Path to the filestore. '
//     //           'A path is created in ${Directory.systemTemp.path}, '
//     //           'if omitted.')
//     //   ..addFlag('reuse-store', negatable: false)
//     //   ..addCommand('admin', ArgParser())
//     //   ..addCommand(_GenerateCommand());
//     //
//     // final ArgResults parsedArgs = parser.parse(args);
//     // final String fileStorePath =
//     //     parsedArgs['filestore'] != null ? parsedArgs['filestore'] : '';
//     // final bool reuse = parsedArgs['reuse-store'];
//     // final bool help = parsedArgs['help'];
//     final String commandName = '';
//     //parsedArgs.command != null ? parsedArgs.command : '';
//
//     final int rCount = commandName == 'generate'
//         ? int.parse(parsedArgs.command['generate-receptions'])
//         : 0;
//
//     final int oCount = commandName == 'generate'
//         ? int.parse(parsedArgs.command['generate-organizations'])
//         : 0;
//
//     final int rdCount = commandName == 'generate'
//         ? int.parse(parsedArgs.command['generate-reception-data'])
//         : 0;
//     final int dpCount = commandName == 'generate'
//         ? int.parse(parsedArgs.command['generate-dialplans'])
//         : 0;
//     final int cCount = commandName == 'generate'
//         ? int.parse(parsedArgs.command['generate-contacts'])
//         : 0;
//     final int iCount = commandName == 'generate'
//         ? int.parse(parsedArgs.command['generate-ivrs'])
//         : 0;
//     final int uCount = commandName == 'generate'
//         ? int.parse(parsedArgs.command['generate-users'])
//         : 0;
//
//     return _DatastoreCtrlConfig._internal(
//         parser,
//         help,
//         reuse,
//         fileStorePath,
//         rCount,
//         oCount,
//         rdCount,
//         dpCount,
//         cCount,
//         iCount,
//         uCount);
//   }
//
//   _DatastoreCtrlConfig._internal(
//       this.parser,
//       this.showHelp,
//       this.reuseStore,
//       this.datastorePath,
//       this.receptionCount,
//       this.organizationCount,
//       this.receptionDataCount,
//       this.dialplanCount,
//       this.contactCount,
//       this.ivrCount,
//       this.userCount);
// }

/**
 *
 */
Future main(args) async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen(logEntryDispatch);
  // Logger _log = Logger('datastore_ctl');

  var runner =
      CommandRunner("datastore_ctl", 'OpenReception datastore management tool')
        ..addCommand(_ManageCommand())
        ..addCommand(_CreateCommand())
        ..addCommand(_GenerateCommand());

  try {
    await runner.run(args);
  } on UsageException catch (error) {
    print(error);
    print(runner.usage);
    exit(64); // Exit code 64 indicates a usage error.
  } catch (error) {
    print(error);
  }

  // _DatastoreCtrlConfig conf = _DatastoreCtrlConfig.fromArguments(args);
  //
  // if (conf.showHelp) {
  //   print(conf.parser.usage);
  //   exit(1);
  // }
  //
  // final Directory fsDir = Directory(conf.datastorePath);
  // if (fsDir.existsSync() && !conf.reuseStore) {
  //   print('Filestore path already exist. '
  //       'Please supply a non-existing path or use the --reuse-store flag.');
  //   print(conf.parser.usage);
  //   exit(1);
  // }
  //
  // final TestEnvironmentConfig envConfig = TestEnvironment().envConfig;
  // await envConfig.load();
  // TestEnvironment env = TestEnvironment(path: conf.datastorePath);
  //
  // if (conf.datastorePath.isEmpty) {
  //   ServiceAgent sa = await env.createsServiceAgent();
  //
  //   _log.info('Creating  ${conf.organizationCount} test-organizations');
  //   List<model.Organization> orgs = (await Future.wait(
  //           List(conf.organizationCount)
  //               .map((_) async => sa.createsOrganization())))
  //       .toList(growable: false);
  //
  //   if (orgs.isNotEmpty) {
  //     _log.info('Creating  ${conf.receptionCount} test-receptions');
  //     List<model.Reception> recs = (await Future.wait(
  //             List(conf.organizationCount).map(
  //                 (_) async => sa.createsReception(await randomChoice(orgs)))))
  //         .toList(growable: false);
  //
  //     _log.info('Creating  ${conf.organizationCount} organizations');
  //     List(40)
  //         .map((_) async => sa.addsContactToReception(
  //             await sa.createsContact(), await randomChoice(recs)))
  //         .toList();
  //
  //     List(10)
  //         .map((_) async => await sa.createsDialplan(mustBeValid: true));
  //
  //     List(10).map((_) async => await sa.createsIvrMenu());
  //   }
  // }
}
