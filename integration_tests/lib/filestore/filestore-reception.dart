part of ort.filestore;

void _runReceptionTests() {
  group('$_namespace.Reception', () {
    ServiceAgent sa;
    TestEnvironment env;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
    });

    tearDown(() async {
      await env.clear();
    });

    test('create', () => storeTest.Reception.create(sa));

    test('create after last is removed',
        () => storeTest.Reception.createAfterLastRemove(sa));

    test('update', () => storeTest.Reception.update(sa));
    test('update (not found)', () => storeTest.Reception.updateNonExisting(sa));
    test('update (invalid)', () => storeTest.Reception.updateInvalid(sa));
    test('remove', () => storeTest.Reception.remove(sa));

    test('get', () => storeTest.Reception.existingReception(sa));
    test('get (not found)', () => storeTest.Reception.nonExistingReception(sa));
    test('list', () => storeTest.Reception.listReceptions(sa));
  });

  group('$_namespace.Reception', () {
    ServiceAgent sa;
    TestEnvironment env;
    setUp(() async {
      env = TestEnvironment(enableRevisions: true);
      sa = await env.createsServiceAgent();
    });

    tearDown(() async {
      await env.clear();
    });
    test('change listing on create',
        () => storeTest.Reception.changeOnCreate(sa));

    test('change listing on update',
        () => storeTest.Reception.changeOnUpdate(sa));

    test('change listing on remove',
        () => storeTest.Reception.changeOnRemove(sa));
  });
}
