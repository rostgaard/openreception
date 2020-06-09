part of ort.rest;

void _runMessageTests() {
  group('$_namespace.Message', () {
    Logger log = Logger('$_namespace.Message');

    ServiceAgent sa;
    TestEnvironment env;
    process.MessageServer mProcess;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      mProcess = await env.requestMessageserverProcess();

      sa.messageStore = mProcess.bindClient(env.httpClient, sa.authToken);
    });

    tearDown(() async {
      await env.clear();
    });

    test(
        'CORS headers present (existingUri)',
            () async => isCORSHeadersPresent(Uri.parse('${mProcess.uri}/ping'),
            log));

    test(
        'CORS headers present (non-existingUri)',
        () => isCORSHeadersPresent(
            Uri.parse('${mProcess.uri}/nonexistingpath'), log));

    test(
        'Non-existing path',
        () => nonExistingPath(
            Uri.parse('${mProcess.uri}/nonexistingpath'
                '?token=${sa.authToken.tokenName}'),
            log));

    test('message (non-existing ID)', () => storeTest.Message.getNotFound(sa));

    test('get', () => storeTest.Message.get(sa));

    test('remove', () => storeTest.Message.remove(sa));

    test('create', () => storeTest.Message.create(sa));

    test('update', () => storeTest.Message.update(sa));

    test('update (event presence)', () => serviceTest.Message.updateEvent(sa));

    test('create (event presence)', () => serviceTest.Message.createEvent(sa));

    test('remove (event presence)', () => serviceTest.Message.removeEvent(sa));
  });

  group('$_namespace.Message', () {
    ServiceAgent sa;
    TestEnvironment env;
    process.MessageServer mProcess;
    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      mProcess = await env.requestMessageserverProcess(withRevisioning: true);

      sa.messageStore = mProcess.bindClient(env.httpClient, sa.authToken);
    });

    tearDown(() async {
      await env.clear();
    });

    test(
        'change listing on create', () => storeTest.Message.changeOnCreate(sa));

    test(
        'change listing on update', () => storeTest.Message.changeOnUpdate(sa));

    test(
        'change listing on remove', () => storeTest.Message.changeOnRemove(sa));
  });
}
