part of ort.filestore;

_runUserTests() {
  group('$_namespace.User', () {
    ServiceAgent sa;
    TestEnvironment env;

    setUp(() async {
      env = TestEnvironment();
      await env.contactStore.ready;
      await env.receptionStore.ready;
      await env.userStore.ready;

      sa = await env.createsServiceAgent();
    });

    tearDown(() async {
      await env.clear();
    });

    test('get', () => storeTest.User.existing(sa));

    test('get (not found)', () => storeTest.User.nonExisting(sa));

    test('create', () => storeTest.User.create(sa));

    test('create after last is removed',
        () => storeTest.User.createAfterLastRemove(sa));

    test('update', () => storeTest.User.update(sa));

    test('remove', () => storeTest.User.update(sa));

    test('list', () => storeTest.User.list(sa));

    test('get (by identity)', () => storeTest.User.getUserByIdentity(sa));
  });

  group('$_namespace.User', () {
    ServiceAgent sa;
    TestEnvironment env;
    setUp(() async {
      env = TestEnvironment(enableRevisions: true);
      await env.contactStore.ready;
      await env.receptionStore.ready;
      await env.userStore.ready;

      sa = await env.createsServiceAgent();
    });

    tearDown(() async {
      await env.clear();
    });

    test('groups', () => storeTest.User.listAllGroups(sa));

    test('groups of (known user)', () => storeTest.User.userGroups(sa));

    test('group join', () => storeTest.User.joinGroup(sa));

    test('group leave', () => storeTest.User.leaveGroup(sa));

    test('identity add', () => storeTest.User.addUserIdentity(sa));

    test('identity remove', () => storeTest.User.removeUserIdentity(sa));

    test('change listing on create', () => storeTest.User.changeOnCreate(sa));

    test('change listing on update', () => storeTest.User.changeOnUpdate(sa));

    test('change listing on remove', () => storeTest.User.changeOnRemove(sa));
  });
}
