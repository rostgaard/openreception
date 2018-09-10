part of ort.rest;

void _runUserTests() {
  group('$_namespace.User', () {
    Logger log = Logger('$_namespace.User');

    ServiceAgent sa;
    TestEnvironment env;
    process.UserServer uProcess;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      uProcess = await env.requestUserserverProcess();
      sa.userStore = uProcess.bindClient(env.httpClient, sa.authToken);
    });

    tearDown(() async {
      await env.clear();
    });

    test(
        'CORS headers present (existingUri)',
        () async => isCORSHeadersPresent(
            resource.User.list((await env.requestUserserverProcess()).uri),
            log));

    test(
        'CORS headers present (non-existingUri)',
        () async => isCORSHeadersPresent(
            Uri.parse(
                '${(await env.requestUserserverProcess()).uri}/nonexistingpath'),
            log));

    test(
        'Non-existing path',
        () async => nonExistingPath(
            Uri.parse(
                '${(await env.requestUserserverProcess()).uri}/nonexistingpath'
                '?token=${sa.authToken.tokenName}'),
            log));

    test('get', () => storeTest.User.existing(sa));

    test('get (not found)', () => storeTest.User.nonExisting(sa));

    test('create', () => storeTest.User.create(sa));

    test('update', () => storeTest.User.update(sa));

    test('remove', () => storeTest.User.update(sa));

    test('list', () => storeTest.User.list(sa));

    test('groups', () => storeTest.User.listAllGroups(sa));

    test('groups of (known user)', () => storeTest.User.userGroups(sa));

    test('get (by identity)', () => storeTest.User.getUserByIdentity(sa));
  });

  //Service-specific tests.
  group('$_namespace.User', () {
    ServiceAgent sa;
    TestEnvironment env;
    process.UserServer uProcess;
    setUp(() async {
      env = TestEnvironment(enableRevisions: true);
      sa = await env.createsServiceAgent();

      uProcess = await env.requestUserserverProcess();
      sa.userStore = uProcess.bindClient(env.httpClient, sa.authToken);
    });

    tearDown(() async {
      await env.clear();
    });

    test('userState change',
        () => serviceTest.User.stateChange(sa, sa.userStore));

    test('userState change (event)',
        () => serviceTest.User.stateChangeEvent(sa, sa.userStore));

    test('create (event presence)', () => serviceTest.User.createEvent(sa));

    test('update (event presence)', () => serviceTest.User.updateEvent(sa));

    test('remove (event presence)', () => serviceTest.User.deleteEvent(sa));
  });

  group('$_namespace.User', () {
    ServiceAgent sa;
    TestEnvironment env;
    process.UserServer uProcess;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      uProcess = await env.requestUserserverProcess(withRevisioning: true);
      sa.userStore = uProcess.bindClient(env.httpClient, sa.authToken);
    });

    tearDown(() async {
      await env.clear();
    });

    test('identity add', () => storeTest.User.addUserIdentity(sa));

    test('identity remove', () => storeTest.User.removeUserIdentity(sa));

    test('group join', () => storeTest.User.joinGroup(sa));

    test('group leave', () => storeTest.User.leaveGroup(sa));

    test('change listing on create', () => storeTest.User.changeOnCreate(sa));

    test('change listing on update', () => storeTest.User.changeOnUpdate(sa));

    test('change listing on remove', () => storeTest.User.changeOnRemove(sa));
  });
}
