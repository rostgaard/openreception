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
        () => isCORSHeadersPresent(resource.Config.get(cProcess.uri), log));

    test(
        'CORS headers present (non-existingUri)',
        () => isCORSHeadersPresent(
            Uri.parse('${cProcess.uri}/nonexistingpath'), log));

    test(
        'Non-existing path',
        () =>
            nonExistingPath(Uri.parse('${cProcess.uri}/nonexistingpath'), log));

    test(
        'Get',
        () => sa.configService
                .clientConfig()
                .then((model.ClientConfiguration configuration) {
              expect(configuration, isNotNull);
              expect(configuration.authServerUri, const TypeMatcher<Uri>());
              expect(configuration.callFlowServerUri, const TypeMatcher<Uri>());
              expect(configuration.contactServerUri, const TypeMatcher<Uri>());
              expect(configuration.messageServerUri, const TypeMatcher<Uri>());
              expect(configuration.notificationSocketUri,
                  const TypeMatcher<Uri>());
              expect(
                  configuration.receptionServerUri, const TypeMatcher<Uri>());
              expect(configuration.systemLanguage, const TypeMatcher<String>());
            }));
  });
}
