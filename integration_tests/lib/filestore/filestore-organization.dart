part of ort.filestore;

void _runOrganizationTests() {
  group('$_namespace.Organization', () {
    ServiceAgent sa;
    TestEnvironment env;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
      await env.organizationStore.ready;
    });

    tearDown(() async {
      await env.clear();
    });

    test('create', () => storeTest.Organization.create(sa));
    test('create (empty)', () => storeTest.Organization.createEmpty(sa));

    test('create after last is removed',
        () => storeTest.Organization.createAfterLastRemove(sa));

    test('update', () => storeTest.Organization.update(sa));
    test('update (invalid)', () => storeTest.Organization.updateInvalid(sa));

    test('remove', () => storeTest.Organization.remove(sa));
    test('remove (non-existing)',
        () => storeTest.Organization.removeNonExisting(sa));

    test('get', () => storeTest.Organization.existingOrganization(sa));

    test('get (non-existing)',
        () => storeTest.Organization.nonExistingOrganization(sa));

    test('list', () => storeTest.Organization.list(sa));

    test('Contact list',
        () => storeTest.Organization.existingOrganizationContacts(sa));

    test('Contact list (non-existing organization)',
        () => storeTest.Organization.nonExistingOrganizationContacts(sa));

    test('Reception listing',
        () => storeTest.Organization.existingOrganizationReceptions(sa));

    test('Reception map', () => storeTest.Organization.receptionMap(sa));

    test('Reception listing Non-existing organization',
        () => storeTest.Organization.nonExistingOrganizationReceptions(sa));
  });

  group('$_namespace.Organization', () {
    ServiceAgent sa;
    TestEnvironment env;
    setUp(() async {
      env = TestEnvironment(enableRevisions: true);
      sa = await env.createsServiceAgent();
      await env.organizationStore.ready;
    });

    tearDown(() async {
      await env.clear();
    });

    test('change listing on create',
        () => storeTest.Organization.changeOnCreate(sa));

    test('change listing on update',
        () => storeTest.Organization.changeOnUpdate(sa));

    test('change listing on remove',
        () => storeTest.Organization.changeOnRemove(sa));
  });
}
