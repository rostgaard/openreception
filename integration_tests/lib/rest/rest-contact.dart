part of ort.rest;

void _runContactTests() {
  group('$_namespace.Contact', () {
    Logger log = Logger('$_namespace.Contact');

    ServiceAgent sa;
    TestEnvironment env;
    process.ContactServer cProcess;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      cProcess = await env.requestContactserverProcess();

      sa.contactStore = cProcess.bindClient(env.httpClient, sa.authToken);
    });

    tearDown(() async {
      await env.clear();
    });

    test('CORS headers present (existingUri)',
        () => isCORSHeadersPresent(resource.User.list(cProcess.uri), log));

    test(
        'CORS headers present (non-existingUri)',
        () => isCORSHeadersPresent(
            Uri.parse('${cProcess.uri}/nonexistingpath'), log));

    test(
        'Non-existing path',
        () => nonExistingPath(
            Uri.parse('${cProcess.uri}/nonexistingpath'
                '?token=${sa.authToken.tokenName}'),
            log));

    test('get contact receptionAttributes',
        () => storeTest.Contact.getByReception(sa));

    test('list contacts of organization',
        () => storeTest.Contact.organizationContacts(sa));

    test('list organizations of contact',
        () => storeTest.Contact.organizations(sa));

    test('list receptions of contact', () => storeTest.Contact.receptions(sa));

    test('list', () => storeTest.Contact.list(sa));

    test('get', () => storeTest.Contact.get(sa));

    test('create', () => storeTest.Contact.create(sa));

    test('update', () => storeTest.Contact.update(sa));

    test('remove', () => storeTest.Contact.remove(sa));

    test('get (not found)', () => storeTest.Contact.nonExistingContact(sa));

    test('List contacts by reception',
        () => storeTest.Contact.listByReception(sa));
    test('List contacts by Non-existing reception',
        () => storeTest.Contact.listContactsByNonExistingReception(sa));

    test('endpoint listing', () => storeTest.Contact.endpoints(sa));
    test('endpoint create', () => storeTest.Contact.endpointCreate(sa));
    test('endpoint update', () => storeTest.Contact.endpointUpdate(sa));
    test('endpoint remove', () => storeTest.Contact.endpointRemove(sa));

    test('phone listing', () => storeTest.Contact.phones(sa));

    test('add receptionAttributes', () => storeTest.Contact.addToReception(sa));

    test('update receptionAttributes',
        () => storeTest.Contact.updateInReception(sa));

    test('delete receptionAttributes',
        () => storeTest.Contact.deleteFromReception(sa));

    test('create (event presence)', () => serviceTest.Contact.createEvent(sa));

    test('update (event presence)', () => serviceTest.Contact.updateEvent(sa));

    test('remove (event presence)', () => serviceTest.Contact.deleteEvent(sa));
  });
  group('$_namespace.Contact', () {
    ServiceAgent sa;
    TestEnvironment env;
    process.ContactServer cProcess;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      cProcess = await env.requestContactserverProcess(withRevisioning: true);

      sa.contactStore = cProcess.bindClient(env.httpClient, sa.authToken);
    });

    tearDown(() async {
      await env.clear();
    });

    test(
        'change listing on create', () => storeTest.Contact.changeOnCreate(sa));

    test(
        'change listing on update', () => storeTest.Contact.changeOnUpdate(sa));

    test(
        'change listing on remove', () => storeTest.Contact.changeOnRemove(sa));

    test('change listing on reception add',
        () => storeTest.Contact.addToReceptionChange(sa));

    test('change listing on reception update',
        () => storeTest.Contact.updateInReceptionChange(sa));

    test('change listing on reception delete',
        () => storeTest.Contact.deleteFromReceptionChange(sa));
  });
}
