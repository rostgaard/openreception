part of ort.rest;

void _runConfigTests() {
  group('$_namespace.Config', () {
    Logger log = Logger('$_namespace.Config');

    ServiceAgent sa;
    TestEnvironment env;
    process.ConfigServer cProcess;

    setUpAll(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      cProcess = await env.requestConfigServerProcess();

      sa.configService = cProcess.createClient(env.httpClient);
      await Future.wait([cProcess.whenReady]);
    });

    tearDownAll(() async {
      await env.clear();
    });

    test('CORS headers present (existingUri)',
        () => isCORSHeadersPresent(Uri.parse('${cProcess.uri}/config'), log));

    test(
        'CORS headers present (non-existingUri)',
        () => isCORSHeadersPresent(
            Uri.parse('${cProcess.uri}/nonexistingpath'), log));

    test(
        'Non-existing path',
        () =>
            nonExistingPath(Uri.parse('${cProcess.uri}/nonexistingpath'), log));

    test(
        'Update config',
            () {
          sa.configService.register(service.ServerType.calendar, sa.configService.host);
          
          
            });
    
    test(
        'Get',
        () => sa.configService
                .clientConfig()
                .then((model.Configuration configuration) {
              expect(configuration, isNotNull);
              expect(configuration.authServerUri, const TypeMatcher<String>());
              expect(configuration.callFlowServerUri, const TypeMatcher<String>());
              expect(configuration.contactServerUri, const TypeMatcher<String>());
              expect(configuration.messageServerUri, const TypeMatcher<String>());
              expect(configuration.notificationSocketUri,
                  const TypeMatcher<String>());
              expect(
                  configuration.receptionServerUri, const TypeMatcher<String>());
              expect(configuration.systemLanguage, const TypeMatcher<String>());
            }));
  });
}
