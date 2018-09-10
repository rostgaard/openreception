part of ort.storage;

abstract class Ivr {
  /**
   *
   */
  static Future create(storage.Ivr ivrStore, [model.User user]) async {
    model.IvrMenu menu = Randomizer.randomIvrMenu();

    model.IvrMenu createdMenu = await ivrStore.create(menu, user);

    expect(createdMenu, isNotNull);
    expect(createdMenu.name, equals(menu.name));

    await ivrStore.remove(createdMenu.name, user);
  }

  /**
   *
   */
  static Future createAfterLastRemove(ServiceAgent sa) async {
    final menu = await sa.createsIvrMenu();

    await sa.deletesIvrMenu(menu);
    await sa.createsIvrMenu();
  }

  /**
   *
   */
  static Future get(storage.Ivr ivrStore, [model.User user]) async {
    model.IvrMenu menu = Randomizer.randomIvrMenu();

    model.IvrMenu createdMenu = await ivrStore.create(menu, user);

    expect((await ivrStore.get(createdMenu.name)).name, equals(menu.name));

    await ivrStore.remove(createdMenu.name, user);
  }

  /**
   *
   */
  static Future list(storage.Ivr ivrStore, [model.User user]) async {
    expect((await ivrStore.list()), TypeMatcher<Iterable>());
  }

  /**
   *
   */
  static Future remove(storage.Ivr ivrStore, [model.User user]) async {
    model.IvrMenu menu = Randomizer.randomIvrMenu();

    model.IvrMenu createdMenu = await ivrStore.create(menu, user);

    await ivrStore.remove(createdMenu.name, user);
    await expect(
        ivrStore.get(createdMenu.name), throwsA(TypeMatcher<NotFound>()));
  }

  /**
   *
   */
  static Future update(storage.Ivr ivrStore, [model.User user]) async {
    model.IvrMenu menu = Randomizer.randomIvrMenu();

    model.IvrMenu createdMenu = await ivrStore.create(menu, user);

    expect(createdMenu, isNotNull);
    expect(createdMenu.name, equals(menu.name));

    {
      model.IvrMenu changes = Randomizer.randomIvrMenu();
      changes.name = createdMenu.name;
      createdMenu = changes;
    }

    await ivrStore.update(createdMenu, user);
  }

  /**
   *
   */
  static Future changeOnCreate(ServiceAgent sa) async {
    final model.IvrMenu created = await sa.createsIvrMenu();

    Iterable<model.Commit> commits = await sa.ivrStore.changes(created.name);

    expect(commits.length, equals(1));
    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(sa.user.address));
    expect(commits.first.uid, equals(sa.user.id));

    expect(commits.first.changes.length, equals(1));
    final model.IvrChange change = commits.first.changes.first;

    expect(change.changeType, model.ChangeType.add);
    expect(change.menuName, created.name);
  }

  /**
   *
   */
  static Future changeOnUpdate(ServiceAgent sa) async {
    final model.IvrMenu created = await sa.createsIvrMenu();
    await sa.updatesIvrMenu(created);

    Iterable<model.Commit> commits = await sa.ivrStore.changes(created.name);

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
    final model.IvrChange latestChange = commits.first.changes.first;
    final model.IvrChange oldestChange = commits.last.changes.first;

    expect(latestChange.changeType, model.ChangeType.modify);
    expect(latestChange.menuName, created.name);

    expect(oldestChange.changeType, model.ChangeType.add);
    expect(oldestChange.menuName, created.name);
  }

  /**
   *
   */
  static Future changeOnRemove(ServiceAgent sa) async {
    final model.IvrMenu created = await sa.createsIvrMenu();
    await sa.deletesIvrMenu(created);

    Iterable<model.Commit> commits = await sa.ivrStore.changes(created.name);

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
    final model.IvrChange latestChange = commits.first.changes.first;
    final model.IvrChange oldestChange = commits.last.changes.first;

    expect(latestChange.changeType, model.ChangeType.delete);
    expect(latestChange.menuName, created.name);

    expect(oldestChange.changeType, model.ChangeType.add);
    expect(oldestChange.menuName, created.name);
  }
}
