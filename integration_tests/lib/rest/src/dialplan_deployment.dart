part of ort.service;

/**
 * Converts a Dart DateTime WeekDay into a [model.Weekday].
 */
model.WeekDay toWeekDay(int weekday) {
  if (weekday == DateTime.monday) {
    return model.WeekDay.mon;
  } else if (weekday == DateTime.tuesday) {
    return model.WeekDay.tue;
  } else if (weekday == DateTime.wednesday) {
    return model.WeekDay.wed;
  } else if (weekday == DateTime.thursday) {
    return model.WeekDay.thur;
  } else if (weekday == DateTime.friday) {
    return model.WeekDay.fri;
  } else if (weekday == DateTime.saturday) {
    return model.WeekDay.sat;
  } else if (weekday == DateTime.sunday) {
    return model.WeekDay.sun;
  }

  throw RangeError('$weekday not in range');
}

abstract class DialplanDeploymentTest {
  /**
   * TODO: Verify reception-id.
   */
  static noHours(Customer customer, service.RESTDialplanStore rdpStore,
      storage.Reception rStore, esl.Connection eslClient) async {
    final Logger _log = Logger('service.DialplanDeployment.noHours');
    List<esl.Event> events = [];
    eslClient.eventStream.listen(events.add);

    //TODO: event subscriptions.
    model.ReceptionDialplan rdp = model.ReceptionDialplan()
      ..open = []
      ..extension = 'test-${Randomizer.randomPhoneNumber()}'
          '-${DateTime.now().millisecondsSinceEpoch}'
      ..defaultActions = [
        model.Playback('sorry-dude-were-closed'),
        model.Playback('sorry-dude-were-really-closed')
      ]
      ..active = true;

    model.ReceptionDialplan createdDialplan = await rdpStore.create(rdp);
    _log.info('Created dialplan: ${createdDialplan.toJson()}');
    final r = await rStore.create(
        Randomizer.randomReception()
          ..enabled = true
          ..dialplan = createdDialplan.extension,
        null);
    await rdpStore.deployDialplan(rdp.extension, r.id);
    await rdpStore.reloadConfig();

    _log.info('Subscribing for events.');

    await eslClient.event(['CHANNEL_EXECUTE'], format: 'json');

    await customer.dial(rdp.extension);

    _log.info('Awaiting $customer\'s phone to hang up');
    await customer.waitForHangup().timeout(Duration(seconds: 10));
    await Future.delayed(Duration(milliseconds: 100));

    /// Check event queue.
    final int playback1 = events.indexOf(events.firstWhere((event) =>
        event.fields['Application-Data'] != null &&
        event.fields['Application-Data'].contains('sorry-dude-were-closed')));

    final int playback2 = events.indexOf(events.firstWhere((event) =>
        event.fields['Application-Data'] != null &&
        event.fields['Application-Data']
            .contains('sorry-dude-were-really-closed')));

    expect(playback1, lessThan(playback2));

    /// Cleanup.
    _log.info('Test successful. Cleaning up.');

    await rStore.remove(r.id, null);
    await rdpStore.remove(createdDialplan.extension, null);
  }

  /**
   *
   */
  static openHoursOpen(Customer customer, service.RESTDialplanStore rdpStore,
      storage.Reception rStore, esl.Connection eslClient) async {
    final Logger _log = Logger('service.DialplanDeployment.openHoursOpen');
    List<esl.Event> events = [];
    eslClient.eventStream.listen(events.add);

    final DateTime now = DateTime.now();
    model.OpeningHour justNow = model.OpeningHour.empty()
      ..fromDay = toWeekDay(now.weekday)
      ..toDay = toWeekDay(now.weekday)
      ..fromHour = now.hour
      ..toHour = now.hour + 1
      ..fromMinute = now.minute
      ..toMinute = now.minute;

    //TODO: event subscriptions.
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
      ..defaultActions = [model.Playback('sorry-dude-were-closed')]
      ..active = true;

    model.ReceptionDialplan createdDialplan = await rdpStore.create(rdp);
    final r = await rStore.create(
        Randomizer.randomReception()
          ..enabled = true
          ..dialplan = createdDialplan.extension,
        null);
    await rdpStore.deployDialplan(rdp.extension, r.id);
    await rdpStore.reloadConfig();

    _log.info('Subscribing for events.');
    await eslClient.event(['CHANNEL_EXECUTE'], format: 'json');

    await customer.dial(rdp.extension);

    _log.info('Awaiting $customer\'s phone to hang up');
    await customer.waitForHangup().timeout(Duration(seconds: 10));
    await Future.delayed(Duration(milliseconds: 100));

    /// Check event queue.
    final int playback1 = events.indexOf(events.firstWhere((event) =>
        event.fields['Application-Data'] != null &&
        event.fields['Application-Data'].contains('sorry-dude-were-open')));

    final int playback2 = events.indexOf(events.firstWhere((event) =>
        event.fields['Application-Data'] != null &&
        event.fields['Application-Data']
            .contains('sorry-dude-were-really-open')));

    expect(playback1, lessThan(playback2));

    /// Cleanup.
    _log.info('Test successful. Cleaning up.');

    await rStore.remove(r.id, null);
    await rdpStore.remove(createdDialplan.extension, null);
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
      ..fromDay = toWeekDay(now.weekday)
      ..toDay = toWeekDay(now.weekday)
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
          ]
          ..active = true);
    _log.info('Created dialplan: ${firstDialplan.toJson()}');

    final model.ReceptionDialplan secondDialplan =
        await rdpStore.create(model.ReceptionDialplan()
          ..extension = secondDialplanExtension
          ..open = [
            model.HourAction()
              ..hours = [justNow]
              ..actions = [model.Playback(secondDialplanGreeting)],
          ]
          ..active = true);

    model.ReceptionReference r = await rStore.create(
        Randomizer.randomReception()
          ..enabled = true
          ..dialplan = firstDialplan.extension,
        null);
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

    await rStore.remove(r.id, null);
    await rdpStore.remove(firstDialplan.extension, null);
    await rdpStore.remove(secondDialplan.extension, null);
  }
}
