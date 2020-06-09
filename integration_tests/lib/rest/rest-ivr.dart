part of ort.rest;

_runIvrTests() {
  group('rest.Ivr', () {
    Logger log = Logger('$_namespace.ivr');

    service.RESTIvrStore ivrStore;
    process.DialplanServer ivrServer;
    ServiceAgent sa;
    TestEnvironment env;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
      ivrServer = await env.requestDialplanProcess();
      ivrStore = ivrServer.bindIvrClient(env.httpClient, sa.authToken);
      sa.ivrStore = ivrStore;
    });

    tearDown(() async {
      await env.clear();
    });

    test(
        'CORS headers present (existingUri)',
            () async => isCORSHeadersPresent(Uri.parse('${(await env.requestReceptionserverProcess()).uri}/ping'),
            log));

    test(
        'CORS headers present (non-existingUri)',
        () async => isCORSHeadersPresent(
            Uri.parse(
                '${(await env.requestDialplanProcess()).uri}/nonexistingpath'),
            log));

    test(
        'Non-existing path',
        () async => nonExistingPath(
            Uri.parse(
                '${(await env.requestDialplanProcess()).uri}/nonexistingpath'
                '?token=${sa.authToken.tokenName}'),
            log));

    test('create', () => storeTest.Ivr.create(ivrStore));

    test('get', () => storeTest.Ivr.get(ivrStore));

    test('list', () => storeTest.Ivr.list(ivrStore));

    test('remove', () => storeTest.Ivr.remove(ivrStore));

    test('update', () => storeTest.Ivr.update(ivrStore));
  });

  group('rest.Ivr', () {
    service.RESTIvrStore ivrStore;
    process.DialplanServer ivrServer;
    ServiceAgent sa;
    TestEnvironment env;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
      ivrServer = await env.requestDialplanProcess(withRevisioning: true);
      ivrStore = ivrServer.bindIvrClient(env.httpClient, sa.authToken);
      sa.ivrStore = ivrStore;
    });

    tearDown(() async {
      await env.clear();
    });

    test('change listing on create', () => storeTest.Ivr.changeOnCreate(sa));

    test('change listing on update', () => storeTest.Ivr.changeOnUpdate(sa));

    test('change listing on remove', () => storeTest.Ivr.changeOnRemove(sa));
  });
}
