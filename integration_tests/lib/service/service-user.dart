part of ort.service;

abstract class User {
  static Logger _log = Logger('$_namespace.User');

  static Future stateChange(
      ServiceAgent sa, service.RESTUserStore userService) async {
    _log.info('Checking server behaviour on an user state change.');
    model.User createdUser = await sa.createsUser();

    await userService.userStateReady(createdUser.id);
    expect((await userService.userStatus(createdUser.id)).paused, isFalse);
    await userService.userStatePaused(createdUser.id);
    expect((await userService.userStatus(createdUser.id)).paused, isTrue);
    await userService.userStateReady(createdUser.id);
    expect((await userService.userStatus(createdUser.id)).paused, isFalse);
  }

  /**
   *
   */
  static Future stateChangeEvent(
      ServiceAgent sa, service.RESTUserStore uService) async {
    if (!sa.user.groups.contains(model.UserGroups.receptionist)) {
      sa.user.groups.add(model.UserGroups.receptionist);
      await sa.userStore.update(sa.user, sa.user);
    }

    Future expectedEvent = (await sa.notifications).firstWhere((e) =>
        e is event.UserState &&
        e.status.userId == sa.user.id &&
        e.status.paused);

    await uService.userStatePaused(sa.user.id);

    final event.UserState changeEvent = await expectedEvent;

    expect(changeEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }

  /**
   *
   */
  static Future createEvent(ServiceAgent sa) async {
    final nextUserCreateEvent = (await sa.notifications).firstWhere(
        (e) => e is event.UserChange && e.state == event.Change.created);
    final createdUser = await sa.createsUser();

    final event.UserChange createEvent =
        await nextUserCreateEvent.timeout(Duration(seconds: 3));

    expect(createEvent.uid, equals(createdUser.id));
    expect(createEvent.modifierUid, equals(sa.user.id));
    expect(createEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }

  /**
   *
   */
  static Future updateEvent(ServiceAgent sa) async {
    final nextUserUpdateEvent = (await sa.notifications).firstWhere(
        (e) => e is event.UserChange && e.state == event.Change.updated);
    final createdUser = await sa.createsUser();
    await sa.updatesUser(createdUser);

    final event.UserChange updateEvent =
        await nextUserUpdateEvent.timeout(Duration(seconds: 3));

    expect(updateEvent.uid, equals(createdUser.id));
    expect(updateEvent.modifierUid, equals(sa.user.id));
    expect(updateEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }

  /**
   *
   */
  static Future deleteEvent(ServiceAgent sa) async {
    final nextUserDeleteEvent = (await sa.notifications).firstWhere(
        (e) => e is event.UserChange && e.state == event.Change.deleted);
    final created = await sa.createsUser();
    await sa.removesUser(created);

    final event.UserChange deleteEvent =
        await nextUserDeleteEvent.timeout(Duration(seconds: 3));

    expect(deleteEvent.uid, equals(created.id));
    expect(deleteEvent.modifierUid, equals(sa.user.id));
    expect(deleteEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }
}
