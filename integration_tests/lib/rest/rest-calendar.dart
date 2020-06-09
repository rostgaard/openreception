part of ort.rest;

void _runCalendarTests() {
  group('$_namespace.Calendar', () {
    Logger log = Logger('$_namespace.Calendar');

    ServiceAgent sa;
    TestEnvironment env;
    process.CalendarServer cProcess;
    model.BaseContact contact;
    model.Owner owner;
    service.RESTCalendarStore calendarStore;

    setUpAll(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
      contact = await sa.createsContact();

      owner = model.OwningContact(contact.id);

      cProcess = await env.requestCalendarserverProcess();

      calendarStore = cProcess.bindClient(env.httpClient, sa.authToken);
    });

    tearDownAll(() async {
      await env.clear();
    });

    test(
        'CORS headers present (existingUri)',
        () async => isCORSHeadersPresent(Uri.parse('${cProcess.uri}/ping'),
            log));

    test(
        'CORS headers present (non-existingUri)',
        () async => isCORSHeadersPresent(
            Uri.parse(
                '${(await env.requestCalendarserverProcess()).uri}/nonexistingpath'),
            log));

    test(
        'Non-existing path',
        () async => nonExistingPath(
            Uri.parse(
                '${(await env.requestCalendarserverProcess()).uri}/nonexistingpath'
                '?token=${sa.authToken.tokenName}'),
            log));

    test('get (non-existing)',
        () => storeTest.Calendar.getNonExistingEntry(calendarStore));

    /**
     * Basic CRUD tests for contact owner.
     */
    test('create (contact owner)',
        () => storeTest.Calendar.create(owner, calendarStore, sa.user));

    test(
        'create after last is removed (contact owner)',
        () => storeTest.Calendar.createAfterLastRemove(
            owner, calendarStore, sa.user));

    test('get (contact owner)',
        () => storeTest.Calendar.get(owner, calendarStore, sa.user));

    test('update (contact owner)',
        () => storeTest.Calendar.update(owner, calendarStore, sa.user));

    test('list (contact owner)',
        () => storeTest.Calendar.list(owner, calendarStore, sa.user));

    test('remove (contact owner)',
        () => storeTest.Calendar.remove(owner, calendarStore, sa.user));

    test('create (event presence)',
        () => serviceTest.Calendar.createEvent(sa, owner, calendarStore));

    test('update (event presence)',
        () => serviceTest.Calendar.updateEvent(sa, owner, calendarStore));

    test('remove (event presence)',
        () => serviceTest.Calendar.deleteEvent(sa, owner, calendarStore));
  });

  group('$_namespace.Calendar', () {
    ServiceAgent sa;
    TestEnvironment env;
    process.CalendarServer cProcess;
    model.BaseContact contact;

    model.Owner owner;
    service.RESTCalendarStore calendarStore;

    setUpAll(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
      contact = await sa.createsContact();

      owner = model.OwningContact(contact.id);

      cProcess = await env.requestCalendarserverProcess(withRevisioning: true);

      calendarStore = cProcess.bindClient(env.httpClient, sa.authToken);
    });

    tearDownAll(() async {
      await env.clear();
    });

    test('change listing on create (contact owner)',
        () => storeTest.Calendar.changeOnCreate(owner, calendarStore, sa.user));

    test(
        'latest change on create (contact owner)',
        () => storeTest.Calendar.latestChangeOnCreate(
            owner, calendarStore, sa.user));

    test('change listing on update (contact owner)',
        () => storeTest.Calendar.changeOnUpdate(owner, calendarStore, sa.user));

    test(
        'latest change on update (contact owner)',
        () => storeTest.Calendar.latestChangeOnUpdate(
            owner, calendarStore, sa.user));

    test('change listing on remove (contact owner)',
        () => storeTest.Calendar.changeOnRemove(owner, calendarStore, sa.user));

    test(
        'latest change on remove (contact owner)',
        () => storeTest.Calendar.latestChangeOnRemove(
            owner, calendarStore, sa.user));
  });

  // Setup/teardown Basic CRUD tests for reception owner.
  group('$_namespace.Calendar', () {
    ServiceAgent sa;
    TestEnvironment env;
    process.CalendarServer cProcess;
    model.Reception reception;
    model.Owner owner;
    service.RESTCalendarStore calendarStore;

    setUpAll(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
      await env.receptionStore.ready;

      reception = await sa.createsReception(await sa.createsOrganization());

      owner = model.OwningReception(reception.id);

      cProcess = await env.requestCalendarserverProcess();

      calendarStore = cProcess.bindClient(env.httpClient, sa.authToken);
      sa.calendarStore = calendarStore;
    });

    tearDownAll(() async {
      await env.clear();
    });

    test('get (reception owner)',
        () => storeTest.Calendar.get(owner, calendarStore, sa.user));

    test('create (reception owner)',
        () => storeTest.Calendar.create(owner, calendarStore, sa.user));

    test(
        'create after last is removed (reception owner)',
        () => storeTest.Calendar.createAfterLastRemove(
            owner, calendarStore, sa.user));

    test('list (reception owner)',
        () => storeTest.Calendar.list(owner, calendarStore, sa.user));

    test('remove (reception owner)',
        () => storeTest.Calendar.remove(owner, calendarStore, sa.user));

    test('update (reception owner)',
        () => storeTest.Calendar.update(owner, calendarStore, sa.user));
  });

  group('$_namespace.Calendar', () {
    ServiceAgent sa;
    TestEnvironment env;
    process.CalendarServer cProcess;
    model.Reception reception;
    model.Owner owner;
    service.RESTCalendarStore calendarStore;

    setUpAll(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
      await env.receptionStore.ready;

      reception = await sa.createsReception(await sa.createsOrganization());

      owner = model.OwningReception(reception.id);

      cProcess = await env.requestCalendarserverProcess(withRevisioning: true);

      calendarStore = cProcess.bindClient(env.httpClient, sa.authToken);
      sa.calendarStore = calendarStore;
    });

    tearDownAll(() async {
      await env.clear();
    });

    test('change listing on create (reception owner)',
        () => storeTest.Calendar.changeOnCreate(owner, calendarStore, sa.user));

    test(
        'latest change on create (reception owner)',
        () => storeTest.Calendar.latestChangeOnCreate(
            owner, calendarStore, sa.user));

    test('change listing on update (reception owner)',
        () => storeTest.Calendar.changeOnUpdate(owner, calendarStore, sa.user));

    test(
        'latest change on update (reception owner)',
        () => storeTest.Calendar.latestChangeOnUpdate(
            owner, calendarStore, sa.user));

    test('change listing on remove (reception owner)',
        () => storeTest.Calendar.changeOnRemove(owner, calendarStore, sa.user));

    test(
        'latest change on remove (reception owner)',
        () => storeTest.Calendar.latestChangeOnRemove(
            owner, calendarStore, sa.user));
  });
}
