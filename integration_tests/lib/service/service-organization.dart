part of ort.service;

abstract class Organization {
  /// Test server behaviour when trying to create a organization.
  ///
  /// The expected behaviour is that the server should return the created
  /// Organization object and send out a OrganizationChange notification.
  static Future createEvent(ServiceAgent sa) async {
    final nextOrgCreateEvent = (await sa.notifications).firstWhere((e) =>
        e is event.OrganizationChange && e.state == event.Change.created);
    final createdOrganization = await sa.createsOrganization();

    final event.OrganizationChange createEvent =
        await nextOrgCreateEvent.timeout(Duration(seconds: 3));

    expect(createEvent.oid, equals(createdOrganization.id));
    expect(createEvent.modifierUid, equals(sa.user.id));
    expect(createEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }

  /// Test server behaviour when trying to update an organization.
  ///
  /// The expected behaviour is that the server should return the created
  /// Organization object and send out a OrganizationChange notification.
  static Future updateEvent(ServiceAgent sa) async {
    final nextOrgUpdateEvent = (await sa.notifications).firstWhere((e) =>
        e is event.OrganizationChange && e.state == event.Change.updated);
    final createdOrganization = await sa.createsOrganization();
    await sa.updatesOrganization(createdOrganization);

    final event.OrganizationChange updateEvent =
        await nextOrgUpdateEvent.timeout(Duration(seconds: 3));

    expect(updateEvent.oid, equals(createdOrganization.id));
    expect(updateEvent.modifierUid, equals(sa.user.id));
    expect(updateEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }

  /// Test server behaviour when trying to delete an organization.
  ///
  /// The expected behaviour is that the server should return the created
  /// Organization object and send out a OrganizationChange notification.
  static Future deleteEvent(ServiceAgent sa) async {
    final nextOrgDeleteEvent = (await sa.notifications).firstWhere((e) =>
        e is event.OrganizationChange && e.state == event.Change.deleted);
    final createdOrganization = await sa.createsOrganization();
    await sa.deletesOrganization(createdOrganization);

    final event.OrganizationChange deleteEvent =
        await nextOrgDeleteEvent.timeout(Duration(seconds: 3));

    expect(deleteEvent.oid, equals(createdOrganization.id));
    expect(deleteEvent.modifierUid, equals(sa.user.id));
    expect(deleteEvent.timestamp.difference(DateTime.now()).inMilliseconds,
        lessThan(0));
  }
}
