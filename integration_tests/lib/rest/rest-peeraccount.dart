part of ort.rest;

_runPeerAccountTests() {
  group('$_namespace.PeerAccount', () {
    Logger log = Logger('$_namespace.PeerAccount');
    TestEnvironment env;
    ServiceAgent sa;
    service.PeerAccount paService;
    process.DialplanServer dpServer;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      dpServer = await env.requestDialplanProcess();

      paService = dpServer.bindPeerAccountClient(env.httpClient, sa.authToken);
    });

    tearDown(() async {
      await env.clear();
    });

    test(
        'CORS headers present (existingUri)',
        () async =>
            isCORSHeadersPresent(resource.PeerAccount.list(dpServer.uri), log));

    test(
        'CORS headers present (non-existingUri)',
        () async => isCORSHeadersPresent(
            Uri.parse('${dpServer.uri}/nonexistingpath'), log));

    test(
        'Non-existing path',
        () async => nonExistingPath(
            Uri.parse('${dpServer.uri}/nonexistingpath'
                '?token=${sa.authToken.tokenName}'),
            log));

    test('list', () => serviceTest.PeerAccountService.list(paService));

    test('remove',
        () => serviceTest.PeerAccountService.remove(sa.user, paService));

    test('deploy',
        () => serviceTest.PeerAccountService.deploy(sa.user, paService));
  });

  group('$_namespace.PeerAccount', () {
    TestEnvironment env;
    ServiceAgent sa;
    service.PeerAccount paService;
    process.DialplanServer dpServer;

    service.CallFlowControl callFlow;
    service.RESTDialplanStore dpStore;

    setUp(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      dpServer = await env.requestDialplanProcess();

      paService = dpServer.bindPeerAccountClient(env.httpClient, sa.authToken);

      callFlow = (await env.requestCallFlowProcess())
          .bindClient(env.httpClient, sa.authToken);

      dpStore = (await env.requestDialplanProcess())
          .bindDialplanClient(env.httpClient, sa.authToken);
    });

    tearDown(() async {
      await env.clear();
    });

    test(
        'deployAndRegister',
        () => serviceTest.PeerAccountService.deployAndRegister(
            sa.user, paService, callFlow, dpStore, env.envConfig.externalIp));
  });
}
