part of ort.filestore;

void _runCalendarTests() {
  group('$_namespace.Calendar', () {
    ServiceAgent sa;
    TestEnvironment env;
    model.Owner owner;
    filestore.Calendar calendarStore;

    setUp(() async {
      env = TestEnvironment();

      sa = await env.createsServiceAgent();
      owner = model.OwningContact((await sa.createsContact()).id);

      calendarStore = env.contactStore.calendarStore;
      await calendarStore.ready;
    });

    tearDown(() async {
      await env.clear();
    });

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
  });

  group('$_namespace.Calendar', () {
    ServiceAgent sa;
    TestEnvironment env;
    model.Owner owner;
    filestore.Calendar calendarStore;

    setUp(() async {
      env = TestEnvironment(enableRevisions: true);

      sa = await env.createsServiceAgent();
      owner = model.OwningContact((await sa.createsContact()).id);

      calendarStore = env.contactStore.calendarStore;
      await calendarStore.ready;
    });

    tearDown(() async {
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

  group('$_namespace.Calendar', () {
    ServiceAgent sa;
    TestEnvironment env;
    model.Owner owner;
    filestore.Calendar calendarStore;
    /**
     * Setup/teardown Basic CRUD tests for reception owner.
     */
    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
      await env.receptionStore.ready;

      final reception =
          await sa.createsReception(await sa.createsOrganization());

      owner = model.OwningReception(reception.id);

      calendarStore = env.receptionStore.calendarStore;
      await calendarStore.ready;
    });

    tearDown(() async {
      await env.clear();
    });

    /**
     * Basic CRUD tests for reception owner.
     */
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
    model.Owner owner;
    filestore.Calendar calendarStore;
    /**
     * Setup/teardown Basic CRUD tests for contact owner.
     */
    setUp(() async {
      env = TestEnvironment(enableRevisions: true);
      sa = await env.createsServiceAgent();
      await env.receptionStore.ready;

      final reception =
          await sa.createsReception(await sa.createsOrganization());

      owner = model.OwningReception(reception.id);

      calendarStore = env.receptionStore.calendarStore;
      await calendarStore.ready;
    });

    tearDown(() async {
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
