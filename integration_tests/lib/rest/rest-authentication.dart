part of ort.rest;

void _runAuthServerTests() {
  group('$_namespace.Authentication', () {
    Logger log = Logger('$_namespace.Authentication');

    ServiceAgent sa;
    TestEnvironment env;
    process.AuthServer aProcess;

    setUpAll(() async {
      env = TestEnvironment();
      sa = await env.createsServiceAgent();

      aProcess = await env.requestAuthserverProcess();

      sa.authService = aProcess.bindClient(env.httpClient, sa.authToken);
      await aProcess.whenReady;
    });

    tearDownAll(() async {
      await env.clear();
    });

    test(
        'CORS headers present (existingUri)',
        () => isCORSHeadersPresent(
            resource.Authentication.validate(aProcess.uri, ''), log));

    test(
        'CORS headers present (non-existingUri)',
        () => isCORSHeadersPresent(
            Uri.parse('${aProcess.uri}/nonexistingpath'), log));

    test(
        'Non-existing path',
        () =>
            nonExistingPath(Uri.parse('${aProcess.uri}/nonexistingpath'), log));

    test('Non-existing token',
        () => serviceTest.AuthService.nonExistingToken(sa));

    test('Validate non-existing token',
        () => serviceTest.AuthService.validateNonExistingToken(sa));

    test('Existing token', () => serviceTest.AuthService.existingToken(sa));

    test('Validate existing token',
        () => serviceTest.AuthService.validateExistingToken(sa));
  });
}
