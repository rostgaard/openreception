part of ort.storage;

abstract class ReceptionDialplan {
  /**
   *
   */
  static Future create(
      storage.ReceptionDialplan rdpStore, model.User user) async {
    model.ReceptionDialplan rdp = Randomizer.randomDialplan();

    model.ReceptionDialplan createdDialplan = await rdpStore.create(rdp, user);

    expect(createdDialplan, isNotNull);
    expect(createdDialplan.extension, isNotEmpty);

    await rdpStore.remove(createdDialplan.extension, user);
  }

  /**
   *
   */
  static Future createAfterLastRemove(ServiceAgent sa) async {
    final rdp = await sa.createsDialplan(mustBeValid: false);

    await sa.removesDialplan(rdp);
    await sa.createsDialplan(mustBeValid: false);
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
    expect((await rdpStore.list()), const TypeMatcher<Iterable>());
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
        throwsA(const TypeMatcher<NotFound>()));
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

  /**
   *
   */
  static Future changeOnCreate(ServiceAgent sa) async {
    final model.ReceptionDialplan created =
        await sa.createsDialplan(mustBeValid: false);

    Iterable<model.Commit> commits =
        await sa.dialplanStore.changes(created.extension);

    expect(commits.length, equals(1));
    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(sa.user.address));
    expect(commits.first.uid, equals(sa.user.id));

    expect(commits.first.changes.length, equals(1));
    final model.ReceptionDialplanChange change = commits.first.changes.first;

    expect(change.changeType, model.ChangeType.add_);
    expect(change.extension, created.extension);
  }

  /**
   *
   */
  static Future changeOnUpdate(ServiceAgent sa) async {
    final model.ReceptionDialplan created =
        await sa.createsDialplan(mustBeValid: false);

    await sa.updatesDialplan(created, mustBeValid: false);

    Iterable<model.Commit> commits =
        await sa.dialplanStore.changes(created.extension);

    expect(commits.length, equals(2));

    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(sa.user.address));

    expect(commits.last.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.last.authorIdentity, equals(sa.user.address));

    expect(commits.length, equals(2));
    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(sa.user.address));
    expect(commits.first.uid, equals(sa.user.id));

    expect(commits.first.changes.length, equals(1));
    expect(commits.last.changes.length, equals(1));
    final model.ReceptionDialplanChange latestChange =
        commits.first.changes.first;
    final model.ReceptionDialplanChange oldestChange =
        commits.last.changes.first;

    expect(latestChange.changeType, model.ChangeType.modify_);
    expect(latestChange.extension, created.extension);

    expect(oldestChange.changeType, model.ChangeType.add_);
    expect(oldestChange.extension, created.extension);
  }

  /**
   *
   */
  static Future changeOnRemove(ServiceAgent sa) async {
    final model.ReceptionDialplan created =
        await sa.createsDialplan(mustBeValid: false);

    await sa.removesDialplan(created);

    Iterable<model.Commit> commits =
        await sa.dialplanStore.changes(created.extension);

    expect(commits.length, equals(2));

    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(sa.user.address));

    expect(commits.last.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.last.authorIdentity, equals(sa.user.address));

    expect(commits.length, equals(2));
    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(sa.user.address));
    expect(commits.first.uid, equals(sa.user.id));

    expect(commits.first.changes.length, equals(1));
    expect(commits.last.changes.length, equals(1));
    final model.ReceptionDialplanChange latestChange =
        commits.first.changes.first;
    final model.ReceptionDialplanChange oldestChange =
        commits.last.changes.first;

    expect(latestChange.changeType, model.ChangeType.delete_);
    expect(latestChange.extension, created.extension);

    expect(oldestChange.changeType, model.ChangeType.add_);
    expect(oldestChange.extension, created.extension);
  }
}
