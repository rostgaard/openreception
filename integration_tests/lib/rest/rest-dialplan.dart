part of ort.rest;

_runDialplanTests() {
  Logger log = Logger('$_namespace.dialplan');

  group('rest.Dialplan', () {
    ServiceAgent sa;
    TestEnvironment env;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
    });

    tearDown(() async {
      await env.clear();
    });

    test(
        'CORS headers present (existingUri)',
        () async => isCORSHeadersPresent(
            resource.ReceptionDialplan.list(
                (await env.requestDialplanProcess()).uri),
            log));

    test(
        'CORS headers present (non-existingUri)',
        () async => isCORSHeadersPresent(
            Uri.parse(
                '${(await env.requestDialplanProcess()).uri}/nonexistingpath'),
            log));

    test(
        'Non-existing path',
        () async => nonExistingPath(
            Uri.parse(
                '${(await env.requestDialplanProcess()).uri}/nonexistingpath'
                '?token=${sa.authToken.tokenName}'),
            log));

    // CRUD tests
  });
  group('rest.Dialplan', () {
    ServiceAgent sa;
    TestEnvironment env;

    service.RESTDialplanStore rdpStore;
    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
      rdpStore = (await env.requestDialplanProcess())
          .bindDialplanClient(env.httpClient, sa.authToken);
      sa.dialplanStore = rdpStore;
    });

    tearDown(() async {
      await env.clear();
    });

    test('create', () => storeTest.ReceptionDialplan.create(rdpStore, sa.user));

    test('get', () => storeTest.ReceptionDialplan.get(rdpStore, sa.user));

    test('list', () => storeTest.ReceptionDialplan.list(rdpStore, sa.user));

    test('remove', () => storeTest.ReceptionDialplan.remove(rdpStore, sa.user));

    test('update', () => storeTest.ReceptionDialplan.update(rdpStore, sa.user));
  });

  group('rest.Dialplan', () {
    ServiceAgent sa;
    TestEnvironment env;
    service.RESTDialplanStore rdpStore;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
      rdpStore = (await env.requestDialplanProcess(withRevisioning: true))
          .bindDialplanClient(env.httpClient, sa.authToken);
      sa.dialplanStore = rdpStore;
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

  group('rest.Dialplan', () {
    ServiceAgent sa;
    TestEnvironment env;
    service.RESTDialplanStore rdpStore;

    /**
     * Deploy test.
     */
    service.RESTReceptionStore rStore;
    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();
      rdpStore = (await env.requestDialplanProcess())
          .bindDialplanClient(env.httpClient, sa.authToken);
      rStore = (await env.requestReceptionserverProcess())
          .bindClient(env.httpClient, sa.authToken);
    });

    tearDown(() async {
      await env.clear();
    });

    test('deploy',
        () => serviceTest.ReceptionDialplanStore.deploy(rdpStore, rStore));
  });
}

_runDialplanDeploymentTests() {
  group('DialplanDeployment', () {
    esl.Connection eslClient;
    Logger log = Logger('$_namespace.Call');

    ServiceAgent sa;
    TestEnvironment env;
    process.FreeSwitch fsProcess;
    Socket socket;
    Customer c;

    /// Transient object
    model.ReceptionDialplan rdp;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      fsProcess = await env.requestFreeswitchProcess();

      c = await sa.spawnCustomer();

      final org = await sa.createsOrganization();
      final rec = await sa.createsReception(org);
      rdp = await sa.createsDialplan();
      await sa.deploysDialplan(rdp, rec);

      socket = await Socket.connect(config.eslHost, config.eslPort);

      /// Initilize ESL connection.
      eslClient = esl.Connection(socket);

      Future<Null> authentication =
          esl.authHandler(eslClient, config.eslPassword);

      await authentication;
    });

    tearDown(() async {
      log.finest('FSLOG:\n ${fsProcess.latestLog.readAsStringSync()}');
      await eslClient.exit();
      await socket.destroy();
      await env.clear();
    });

    test(
        'No opening hours',
        () => serviceTest.DialplanDeployment.noHours(
            c, sa.dialplanService, sa.receptionStore, eslClient));

    test(
        'Opening hours - open',
        () => serviceTest.DialplanDeployment.openHoursOpen(
            c, sa.dialplanService, sa.receptionStore, eslClient));

    test(
        'Reception Transfer',
        () => serviceTest.DialplanDeployment.receptionTransfer(
            c, sa.dialplanService, sa.receptionStore, eslClient));
  });
}
