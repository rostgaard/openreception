part of ort.rest;

void _runOrganizationTests() {
  group('$_namespace.Organization', () {
    ServiceAgent sa;
    TestEnvironment env;
    process.ReceptionServer rProcess;

    setUpAll(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      rProcess = await env.requestReceptionserverProcess();
      sa.receptionStore = rProcess.bindClient(env.httpClient, sa.authToken);
      sa.organizationStore =
          rProcess.bindOrgClient(env.httpClient, sa.authToken);
    });

    tearDownAll(() async {
      await env.clear();
    });

    test('create', () => storeTest.Organization.create(sa));
    test('create (empty)', () => storeTest.Organization.createEmpty(sa));

    test('update', () => storeTest.Organization.update(sa));
    test('update (invalid)', () => storeTest.Organization.updateInvalid(sa));

    test('remove', () => storeTest.Organization.remove(sa));
    test('remove (non-existing)',
        () => storeTest.Organization.removeNonExisting(sa));

    test('get', () => storeTest.Organization.existingOrganization(sa));

    test('get (non-existing)',
        () => storeTest.Organization.nonExistingOrganization(sa));

    test('list', () => storeTest.Organization.list(sa));

    test('contacts',
            () => storeTest.Organization.existingOrganizationContacts(sa));

    test('contacts (not-found organization)',
            () => storeTest.Organization.nonExistingOrganizationContacts(sa));

    test('receptions',
            () => storeTest.Organization.existingOrganizationReceptions(sa));

    test('receptions (not-found organization)',
            () => storeTest.Organization.nonExistingOrganizationReceptions(sa));

    test('create (event presence)',
            () => serviceTest.Organization.createEvent(sa));

    test('update (event presence)',
            () => serviceTest.Organization.updateEvent(sa));

    test('remove (event presence)',
            () => serviceTest.Organization.deleteEvent(sa));

    //FIXME: disabled for now.
    //test('Reception map', () => storeTest.Organization.receptionMap(sa));
  });

  group('$_namespace.Organization', () {
    ServiceAgent sa;
    TestEnvironment env;
    process.ReceptionServer rProcess;

    setUpAll(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      rProcess = await env.requestReceptionserverProcess(withRevisioning: true);
      sa.receptionStore = rProcess.bindClient(env.httpClient, sa.authToken);
      sa.organizationStore =
          rProcess.bindOrgClient(env.httpClient, sa.authToken);
    });

    tearDownAll(() async {
      await env.clear();
    });
//
//    test('change listing on create',
//        () => storeTest.Organization.changeOnCreate(sa));
//
//    test('change listing on update',
//        () => storeTest.Organization.changeOnUpdate(sa));
//
//    test('change listing on remove',
//        () => storeTest.Organization.changeOnRemove(sa));
  });
}
