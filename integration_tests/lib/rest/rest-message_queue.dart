part of ort.rest;

void _runMessageQueueTests() {
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

    // test('CORS headers present (existingUri)',
    //     () => isCORSHeadersPresent(resource.Message.list(mProcess.uri), log));
    //
    // test(
    //     'CORS headers present (non-existingUri)',
    //     () => isCORSHeadersPresent(
    //         Uri.parse('${mProcess.uri}/nonexistingpath'), log));
    //
    // test(
    //     'Non-existing path',
    //     () => nonExistingPath(
    //         Uri.parse('${mProcess.uri}/nonexistingpath'
    //             '?token=${sa.authToken.tokenName}'),
    //         log));
    //
    //
    // test('message (non-existing ID)', () => storeTest.Message.getNotFound(sa));
    //
    // test('get', () => storeTest.Message.get(sa));
    //
    // test('list', () => storeTest.Message.list(sa));
    //
    //
    //  test('remove', () => storeTest.Message.remove(sa));
    //
    //
    //test('create', () => storeTest.Message.create(sa));
    //test('update', () => storeTest.Message.update(sa));
    //
    // test(
    //     'enqueue',
    //     () => MessageStore.enqueue(
    //         messageStore, contactStore, receptionStore, null, null, r));
    //
    //
    // test(
    //     'message enqueue (event presence)',
    //     () => RESTMessageStore.messageEnqueueEvent(
    //         messageStore, contactStore, receptionStore, null, null, r));
    //
    // test(
    //     'message update (event presence)',
    //     () => RESTMessageStore.messageUpdateEvent(
    //         messageStore, contactStore, receptionStore, null, null, r));
    //
    // test(
    //     'message create (event presence)',
    //     () => RESTMessageStore.messageCreateEvent(
    //         messageStore, contactStore, receptionStore, null, null, r));
  });
}
