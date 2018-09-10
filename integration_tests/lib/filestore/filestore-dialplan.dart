part of ort.filestore;

void _runDialplanTests() {
  group('$_namespace.ReceptionDialplan', () {
    ServiceAgent sa;
    TestEnvironment env;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
      await env.dialplanStore.ready;
    });

    tearDown(() async {
      await env.clear();
    });

    test('create',
        () => storeTest.ReceptionDialplan.create(env.dialplanStore, sa.user));

    test('create after last is removed',
        () => storeTest.ReceptionDialplan.createAfterLastRemove(sa));

    test('get',
        () => storeTest.ReceptionDialplan.get(env.dialplanStore, sa.user));

    test('list',
        () => storeTest.ReceptionDialplan.list(env.dialplanStore, sa.user));

    test('remove',
        () => storeTest.ReceptionDialplan.remove(env.dialplanStore, sa.user));

    test('update',
        () => storeTest.ReceptionDialplan.update(env.dialplanStore, sa.user));
  });

  group('$_namespace.ReceptionDialplan', () {
    ServiceAgent sa;
    TestEnvironment env;
    setUp(() async {
      env = TestEnvironment(enableRevisions: true);
      sa = await env.createsServiceAgent();
      await env.dialplanStore.ready;
    });

    tearDown(() async {
      await env.clear();
    });

    test('change listing on create',
        () => storeTest.ReceptionDialplan.changeOnCreate(sa));

    test('change listing on update',
        () => storeTest.ReceptionDialplan.changeOnUpdate(sa));

    test('change listing on remove',
        () => storeTest.ReceptionDialplan.changeOnRemove(sa));
  });
}
