part of ort.service;

abstract class Reception {
  /// Test server behaviour when trying to create a reception.
  ///
  /// The expected behaviour is that the server should return the created
  /// Reception object and send out a ReceptionChange notification.
  static Future createEvent(ServiceAgent sa) async {
    final nextOrgCreateEvent = (await sa.notifications).firstWhere(
        (e) => e is event.ReceptionChange && e.state == event.Change.created);

    final org = await sa.createsOrganization();
    final created = await sa.createsReception(org);

    final event.ReceptionChange createEvent =
        await nextOrgCreateEvent.timeout(Duration(seconds: 3));

    expect(createEvent.rid, equals(created.id));
    expect(createEvent.modifierUid, equals(sa.user.id));
    expect(createEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }

  /// Test server behaviour when trying to update an reception.
  ///
  /// The expected behaviour is that the server should return the created
  /// Reception object and send out a ReceptionChange notification.
  static Future updateEvent(ServiceAgent sa) async {
    final nextOrgUpdateEvent = (await sa.notifications).firstWhere(
        (e) => e is event.ReceptionChange && e.state == event.Change.updated);

    final org = await sa.createsOrganization();
    final created = await sa.createsReception(org);
    await sa.updatesReception(created);

    final event.ReceptionChange updateEvent =
        await nextOrgUpdateEvent.timeout(Duration(seconds: 3));

    expect(updateEvent.rid, equals(created.id));
    expect(updateEvent.modifierUid, equals(sa.user.id));
    expect(updateEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }

  /// Test server behaviour when trying to delete an reception.
  ///
  /// The expected behaviour is that the server should return the created
  /// Reception object and send out a ReceptionChange notification.
  static Future deleteEvent(ServiceAgent sa) async {
    final nextOrgDeleteEvent = (await sa.notifications).firstWhere(
        (e) => e is event.ReceptionChange && e.state == event.Change.deleted);

    final org = await sa.createsOrganization();
    final created = await sa.createsReception(org);
    await sa.removesReception(created);

    final event.ReceptionChange deleteEvent =
        await nextOrgDeleteEvent.timeout(Duration(seconds: 3));

    expect(deleteEvent.rid, equals(created.id));
    expect(deleteEvent.modifierUid, equals(sa.user.id));
    expect(deleteEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }
}
