part of ort.filestore;

_runMessageQueueTests() {
  group('$_namespace.MessageQueue', () {
    ServiceAgent sa;
    TestEnvironment env;

    setUp(() async {
      env = TestEnvironment();
      await env.messageStore.ready;

      sa = await env.createsServiceAgent();
    });

    tearDown(() async {
      await env.clear();
    });

    test('list', () => storeTest.MessageQueue.list(sa));
    test('enqueue', () => storeTest.MessageQueue.enqueue(sa));
    test('update', () => storeTest.MessageQueue.update(sa));
    test('remove', () => storeTest.MessageQueue.remove(sa));
  });
}
