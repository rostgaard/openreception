part of ort.rest;

/// TODO: Add tests for both broadcast, send and FIFO message ordering.
void _runNotificationTests() {
  group('$_namespace.Notification', () {
    Logger log = Logger('$_namespace.Notification');

    List<ServiceAgent> sas = List<ServiceAgent>();
    TestEnvironment env;
    process.NotificationServer nProcess;
    service.NotificationService nService;

    setUpAll(() async {
      env = TestEnvironment();
      sas = [];
      await Future.forEach(List.generate(10, (i) => i),
          (_) async => sas.add(await env.createsServiceAgent()));

      nProcess = await env.requestNotificationserverProcess();

      nService = nProcess.bindClient(env.httpClient, sas.first.authToken);

      await Future.wait(sas.map((sa) => sa.notificationSocket));
    });

    tearDownAll(() async {
      await env.clear();
    });

    test(
        'CORS headers present (existingUri)',
        () async => isCORSHeadersPresent(
            resource.Notification.clientConnections(nProcess.uri), log));

    test(
        'CORS headers present (non-existingUri)',
        () async => isCORSHeadersPresent(
            Uri.parse('${nProcess.uri}/nonexistingpath'), log));

    test(
        'Event broadcast',
        () async => serviceTest.NotificationService.eventBroadcast(
            await Future.wait(sas.map((sa) => sa.notificationSocket)),
            nService));

    test('Event send',
        () => serviceTest.NotificationService.eventSend(sas, nService));

    test(
        'ConnectionState listing',
        () async =>
            serviceTest.NotificationService.connectionStateList(sas, nService));

    test('ConnectionState get',
        () => serviceTest.NotificationService.connectionState(sas, nService));
  });
}
