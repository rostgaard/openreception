part of ort.service;

abstract class ReceptionDialplanStore {
  /**
   *
   */
  static Future create(storage.ReceptionDialplan rdpStore,
      [model.User user]) async {
    model.ReceptionDialplan rdp = Randomizer.randomDialplan();

    model.ReceptionDialplan createdDialplan = await rdpStore.create(rdp, user);

    expect(createdDialplan, isNotNull);
    expect(createdDialplan.extension, isNotEmpty);

    await rdpStore.remove(createdDialplan.extension, user);
  }

  /**
   *
   */
  static Future deploy(service.RESTDialplanStore rdpStore,
      service.RESTReceptionStore receptionStore,
      [model.User user]) async {
    model.ReceptionDialplan rdp = Randomizer.randomDialplan(excludeMenus: true);

    model.ReceptionDialplan createdDialplan = await rdpStore.create(rdp, user);
    model.ReceptionReference rRef = await receptionStore.create(
        Randomizer.randomReception()..dialplan = rdp.extension, user);

    await rdpStore.deployDialplan(rdp.extension, rRef.id);

    await receptionStore.remove(rRef.id, user);
    await rdpStore.remove(createdDialplan.extension, user);
  }

  /**
   *
   */
  static Future get(storage.ReceptionDialplan rdpStore,
      [model.User user]) async {
    model.ReceptionDialplan rdp = Randomizer.randomDialplan();

    model.ReceptionDialplan createdDialplan = await rdpStore.create(rdp, user);

    expect(
        (await rdpStore.get(createdDialplan.extension)).extension, isNotEmpty);

    await rdpStore.remove(createdDialplan.extension, user);
  }

  /**
   *
   */
  static Future list(storage.ReceptionDialplan rdpStore,
      [model.User user]) async {
    expect((await rdpStore.list()), TypeMatcher<Iterable>());
  }

  /**
   *
   */
  static Future remove(storage.ReceptionDialplan rdpStore,
      [model.User user]) async {
    model.ReceptionDialplan rdp = Randomizer.randomDialplan();

    model.ReceptionDialplan createdDialplan = await rdpStore.create(rdp, user);

    await rdpStore.remove(createdDialplan.extension, user);
    await expect(rdpStore.get(createdDialplan.extension),
        throwsA(TypeMatcher<NotFound>()));
  }

  /**
   *
   */
  static Future update(storage.ReceptionDialplan rdpStore,
      [model.User user]) async {
    model.ReceptionDialplan rdp = Randomizer.randomDialplan();

    model.ReceptionDialplan createdDialplan = await rdpStore.create(rdp, user);

    expect(createdDialplan, isNotNull);
    expect(createdDialplan.extension, isNotEmpty);

    {
      model.ReceptionDialplan changed = Randomizer.randomDialplan();
      changed.extension = createdDialplan.extension;

      createdDialplan = changed;
    }

    await rdpStore.update(createdDialplan, user);
    await rdpStore.remove(createdDialplan.extension, user);
  }
}
