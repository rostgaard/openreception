part of ort.service;

abstract class DialplanDeployment {
  /**
   *
   */
  static noHours(Customer customer, service.RESTDialplanStore rdpStore,
      storage.Reception rStore, esl.Connection eslClient) async {
    final Logger _log = Logger('$_namespace.DialplanDeployment.noHours');
    List<esl.Event> events = [];
    eslClient.eventStream.listen(events.add);

    model.ReceptionDialplan rdp = model.ReceptionDialplan()
      ..open = []
      ..extension = 'test-${Randomizer.randomPhoneNumber()}'
          '-${DateTime.now().millisecondsSinceEpoch}'
      ..defaultActions = [
        model.Playback('sorry-dude-were-closed'),
        model.Playback('sorry-dude-were-really-closed')
      ];

    model.ReceptionDialplan createdDialplan = await rdpStore.create(rdp);
    _log.info('Created dialplan: ${createdDialplan.toJson()}');
    model.ReceptionReference r = await rStore.create(
        Randomizer.randomReception()
          ..enabled = true
          ..dialplan = createdDialplan.extension,
        model.User());
    await rdpStore.deployDialplan(rdp.extension, r.id);
    await rdpStore.reloadConfig();

    _log.info('Subscribing for events.');

    await eslClient.event(['CHANNEL_EXECUTE'], format: 'json');

    await customer.dial(rdp.extension);

    _log.info('Awaiting $customer\'s phone to hang up');
    await customer.waitForHangup().timeout(Duration(seconds: 10));
    await Future.delayed(Duration(milliseconds: 100));

    /// Check event queue.
    final int playback1 = events.indexOf(events.firstWhere((esl.Event event) =>
        event.fields['Application-Data'] != null &&
        event.fields['Application-Data'].contains('sorry-dude-were-closed')));

    final int playback2 = events.indexOf(events.firstWhere((event) =>
        event.fields['Application-Data'] != null &&
        event.fields['Application-Data']
            .contains('sorry-dude-were-really-closed')));

    expect(playback1, lessThan(playback2));

    /// Cleanup.
    _log.info('Test successful. Cleaning up.');

    await rStore.remove(r.id, model.User());
  }

  /**
   *
   */
  static openHoursOpen(Customer customer, service.RESTDialplanStore rdpStore,
      storage.Reception rStore, esl.Connection eslClient) async {
    final Logger _log = Logger('$_namespace.DialplanDeployment.openHoursOpen');
    List<esl.Event> events = [];
    eslClient.eventStream.listen(events.add);

    final DateTime now = DateTime.now();
    model.OpeningHour justNow = model.OpeningHour.empty()
      ..fromDay = model.toWeekDay(now.weekday)
      ..toDay = model.toWeekDay(now.weekday)
      ..fromHour = now.hour
      ..toHour = now.hour + 1
      ..fromMinute = now.minute
      ..toMinute = now.minute;

    model.ReceptionDialplan rdp = model.ReceptionDialplan()
      ..open = [
        model.HourAction()
          ..hours = [justNow]
          ..actions = [
            model.Playback('sorry-dude-were-open'),
            model.Playback('sorry-dude-were-really-open')
          ]
      ]
      ..extension = 'test-${Randomizer.randomPhoneNumber()}'
          '-${DateTime.now().millisecondsSinceEpoch}'
      ..defaultActions = [model.Playback('sorry-dude-were-closed')];

    model.ReceptionDialplan createdDialplan = await rdpStore.create(rdp);
    model.ReceptionReference r = await rStore.create(
        Randomizer.randomReception()
          ..enabled = true
          ..dialplan = createdDialplan.extension,
        model.User());
    await rdpStore.deployDialplan(rdp.extension, r.id);
    await rdpStore.reloadConfig();

    _log.info('Subscribing for events.');
    await eslClient.event(['CHANNEL_EXECUTE'], format: 'json');

    await customer.dial(rdp.extension);

    _log.info('Awaiting $customer\'s phone to hang up');
    await customer.waitForHangup().timeout(Duration(seconds: 10));
    await Future.delayed(Duration(milliseconds: 100));

    /// Check event queue.
    final int playback1 = events.indexOf(events.firstWhere((esl.Event event) =>
        event.fields['Application-Data'] != null &&
        event.fields['Application-Data'].contains('sorry-dude-were-open')));

    final int playback2 = events.indexOf(events.firstWhere((esl.Event event) =>
        event.fields['Application-Data'] != null &&
        event.fields['Application-Data']
            .contains('sorry-dude-were-really-open')));

    expect(playback1, lessThan(playback2));

    /// Cleanup.
    _log.info('Test successful. Cleaning up.');

    await rStore.remove(r.id, model.User());
  }

  /**
   *
   */
  static receptionTransfer(
      Customer customer,
      service.RESTDialplanStore rdpStore,
      storage.Reception rStore,
      esl.Connection eslClient) async {
    final Logger _log = Logger('$_namespace.DialplanDeployment.noHours');
    List<esl.Event> events = [];
    eslClient.eventStream.listen(events.add);

    final DateTime now = DateTime.now();
    model.OpeningHour justNow = model.OpeningHour.empty()
      ..fromDay = model.toWeekDay(now.weekday)
      ..toDay = model.toWeekDay(now.weekday)
      ..fromHour = now.hour
      ..toHour = now.hour + 1
      ..fromMinute = now.minute
      ..toMinute = now.minute;

    final String firstDialplanGreeting = 'I-am-the-first-greeting';
    final String firstDialplanExtension =
        'test-${Randomizer.randomPhoneNumber()}'
        '-${DateTime.now().millisecondsSinceEpoch}-1';

    final String secondDialplanGreeting = 'I-am-the-second-greeting';
    final String secondDialplanExtension =
        'test-${Randomizer.randomPhoneNumber()}'
        '-${DateTime.now().millisecondsSinceEpoch}-2';

    final model.ReceptionDialplan firstDialplan =
        await rdpStore.create(model.ReceptionDialplan()
          ..extension = firstDialplanExtension
          ..open = [
            model.HourAction()
              ..hours = [justNow]
              ..actions = [
                model.Playback(firstDialplanGreeting),
                model.ReceptionTransfer(secondDialplanExtension)
              ],
          ]);
    _log.info('Created dialplan: ${firstDialplan.toJson()}');

    final model.ReceptionDialplan secondDialplan =
        await rdpStore.create(model.ReceptionDialplan()
          ..extension = secondDialplanExtension
          ..open = [
            model.HourAction()
              ..hours = [justNow]
              ..actions = [model.Playback(secondDialplanGreeting)],
          ]);

    model.ReceptionReference r = await rStore.create(
        Randomizer.randomReception()
          ..enabled = true
          ..dialplan = firstDialplan.extension,
        model.User());
    await rdpStore.deployDialplan(firstDialplan.extension, r.id);
    await rdpStore.deployDialplan(secondDialplan.extension, r.id);
    await rdpStore.reloadConfig();

    _log.info('Subscribing for events.');

    await eslClient.event(['CHANNEL_EXECUTE'], format: 'json');

    await customer.dial(firstDialplan.extension);

    _log.info('Awaiting $customer\'s phone to hang up');
    await customer.waitForHangup().timeout(Duration(seconds: 10));
    await Future.delayed(Duration(milliseconds: 100));

    /// Check event queue.
    final int playback1 = events.indexOf(events.firstWhere((event) =>
        event.fields['Application-Data'] != null &&
        event.fields['Application-Data'].contains(firstDialplanGreeting)));

    final int playback2 = events.indexOf(events.firstWhere((event) =>
        event.fields['Application-Data'] != null &&
        event.fields['Application-Data'].contains(secondDialplanGreeting)));

    expect(playback1, lessThan(playback2));

    /// Cleanup.
    _log.info('Test successful. Cleaning up.');

    await rStore.remove(r.id, model.User());
  }
}
