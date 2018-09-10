part of ort.service;

abstract class Contact {
  static Logger _log = Logger('$_namespace.Contact');

  /**
   *
   */
  static Future createEvent(ServiceAgent sa) async {
    final nextContactCreateEvent = (await sa.notifications).firstWhere(
        (e) => e is event.ContactChange && e.state == event.Change.created);
    final created = await sa.createsContact();

    final event.ContactChange createEvent =
        await nextContactCreateEvent.timeout(Duration(seconds: 3));

    expect(createEvent.cid, equals(created.id));
    expect(createEvent.modifierUid, equals(sa.user.id));
    expect(createEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }

  /**
   *
   */
  static Future updateEvent(ServiceAgent sa) async {
    final nextContactpdateEvent = (await sa.notifications).firstWhere(
        (e) => e is event.ContactChange && e.state == event.Change.updated);
    final created = await sa.createsContact();
    await sa.updatesContact(created);

    final event.ContactChange updateEvent =
        await nextContactpdateEvent.timeout(Duration(seconds: 3));

    expect(updateEvent.cid, equals(created.id));
    expect(updateEvent.modifierUid, equals(sa.user.id));
    expect(updateEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }

  /**
   *
   */
  static Future deleteEvent(ServiceAgent sa) async {
    final nextContactDeleteEvent = (await sa.notifications).firstWhere(
        (e) => e is event.ContactChange && e.state == event.Change.deleted);
    final created = await sa.createsContact();
    await sa.removesContact(created);

    final event.ContactChange deleteEvent =
        await nextContactDeleteEvent.timeout(Duration(seconds: 3));

    expect(deleteEvent.cid, equals(created.id));
    expect(deleteEvent.modifierUid, equals(sa.user.id));
    expect(deleteEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }
}
