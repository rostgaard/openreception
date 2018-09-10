part of ort.storage;

class Organization {
  static Logger _log = Logger('$_libraryName.Organization');

  /// Test server behaviour when trying to aquire a organization object that
  /// exists.
  ///
  /// The expected behaviour is that the server should return the
  /// Organization object.
  static Future existingOrganization(ServiceAgent sa) async {
    _log.info('Checking server behaviour on an existing organization.');
    _log.info('Creating organization');

    final model.Organization newOrg = Randomizer.randomOrganization();
    final model.OrganizationReference newOrgRef =
        await sa.organizationStore.create(newOrg, sa.user);

    _log.info('Fetching organization');

    final model.Organization org = await sa.organizationStore.get(newOrgRef.id);

    _log.info('Asserting properties');
    expect(org, isNotNull);
    expect(org.id, isNotNull);
    expect(org.id, isNot(equals(model.Organization.noId)));
    expect(org.name, isNotEmpty);
    expect(org.name, newOrg.name);
    expect(org.notes, newOrg.notes);

    _log.info('Test OK. Cleaning up');
    await sa.organizationStore.remove(newOrgRef.id, sa.user);
  }

  /// Test server behaviour when trying to aquire a mappings of
  /// reception ID -> reception name + organization name
  ///
  /// The expected behaviour is that the server should return these mappings.
  static Future receptionMap(ServiceAgent sa) async {
    final org1 = await sa.createsOrganization();
    final org2 = await sa.createsOrganization();

    final rec1 = await sa.createsReception(org1);
    final rec2 = await sa.createsReception(org2);

    final orgStore = sa.env.organizationStore;

    Map recMap = await orgStore.receptionMap();

    expect(recMap.length, equals(2));

    Map rec1map = recMap[rec1.id.toString()];
    Map rec2map = recMap[rec2.id.toString()];

    expect(rec1map['reception'], equals(rec1.name));
    expect(rec2map['reception'], equals(rec2.name));
    expect(rec1map['organization'], equals(org1.name));
    expect(rec2map['organization'], equals(org2.name));
  }

  /// Test server behaviour when trying to aquire a list of organization objects
  ///
  /// The expected behaviour is that the server should return a list of
  /// Organization objects.
  static Future list(ServiceAgent sa) async {
    _log.info('Checking server behaviour on list of organizations.');
    final org1 = await sa.createsOrganization();
    final org2 = await sa.createsOrganization();

    final orgRefs = await sa.organizationStore.list();

    expect(orgRefs.length, equals(2));

    expect(orgRefs.any((ref) => ref.id == org1.id), isTrue);
    expect(orgRefs.any((ref) => ref.id == org2.id), isTrue);
  }

  /// Test server behaviour when trying to list contacts associated with
  /// a given organization.
  ///
  /// The expected behaviour is that the server should return a list of
  /// BaseContact objects.
  static Future existingOrganizationContacts(ServiceAgent sa) async {
    final con1 = await sa.createsContact();
    final con2 = await sa.createsContact();
    final con3 = await sa.createsContact();
    final con4 = await sa.createsContact();

    final org1 = await sa.createsOrganization();
    final org2 = await sa.createsOrganization();

    final rec1 = await sa.createsReception(org1);
    final rec2 = await sa.createsReception(org1);
    final rec3 = await sa.createsReception(org2);

    await sa.addsContactToReception(con1, rec1);

    {
      final cRefs = await sa.organizationStore.contacts(org1.id);
      expect(cRefs.length, equals(1));
      expect(cRefs.any((ref) => ref.id == con1.id), isTrue);
    }

    await sa.addsContactToReception(con2, rec1);

    {
      final cRefs = await sa.organizationStore.contacts(org1.id);
      expect(cRefs.length, equals(2));
      expect(cRefs.any((ref) => ref.id == con2.id), isTrue);
    }

    await sa.addsContactToReception(con3, rec2);

    {
      final cRefs = await sa.organizationStore.contacts(org1.id);
      expect(cRefs.length, equals(3));
      expect(cRefs.any((ref) => ref.id == con3.id), isTrue);
    }

    await sa.addsContactToReception(con4, rec3);

    {
      final cRefs = await sa.organizationStore.contacts(org1.id);
      expect(cRefs.length, equals(3));
      expect(cRefs.any((ref) => ref.id == con4.id), isFalse);
    }
    {
      final cRefs = await sa.organizationStore.contacts(org2.id);
      expect(cRefs.length, equals(1));
      expect(cRefs.any((ref) => ref.id == con4.id), isTrue);
    }

    await sa.removesContactFromReception(con1, rec1);
    {
      final cRefs = await sa.organizationStore.contacts(org1.id);
      expect(cRefs.length, equals(2));
      expect(cRefs.any((ref) => ref.id == con1.id), isFalse);
    }
  }

  /// Test server behaviour when trying to list contacts associated with
  /// a non-existing organization.
  ///
  /// The expected behaviour is that the server should return an empty list.
  static Future nonExistingOrganizationContacts(ServiceAgent sa) async {
    final int organizationId = -1;

    _log.info('Looking up contact list for organization $organizationId.');

    return sa.organizationStore
        .contacts(organizationId)
        .then((Iterable<model.BaseContact> contacts) {
      expect(contacts, isEmpty);
      expect(contacts, isNotNull);
    });
  }

  /// Test server behaviour when trying to list contacts associated with
  /// a non-existing organization.
  ///
  /// The expected behaviour is that the server should return an empty list.
  static Future nonExistingOrganization(ServiceAgent sa) async {
    const int organizationId = -1;

    _log.info('Looking up organization $organizationId.');

    expect(sa.organizationStore.get(organizationId),
        throwsA(const TypeMatcher<NotFound>()));
  }

  /// Test server behaviour when trying to list receptions associated with
  /// a given organization.
  ///
  /// The expected behaviour is that the server should return a list of
  /// BaseContact objects.
  static Future existingOrganizationReceptions(ServiceAgent sa) async {
    final org1 = await sa.createsOrganization();
    final org2 = await sa.createsOrganization();
    final rec1 = await sa.createsReception(org1);
    final rec2 = await sa.createsReception(org1);
    final rec3 = await sa.createsReception(org2);

    {
      final rRefs = await sa.organizationStore.receptions(org1.id);
      expect(rRefs.length, equals(2));
      expect(rRefs.any((ref) => ref.id == rec1.id), isTrue);
      expect(rRefs.any((ref) => ref.id == rec2.id), isTrue);
    }

    {
      final rRefs = await sa.organizationStore.receptions(org2.id);
      expect(rRefs.length, equals(1));
      expect(rRefs.any((ref) => ref.id == rec3.id), isTrue);
    }
  }

  /// Test server behaviour when trying to list receptions associated with
  /// a non-existing organization.
  ///
  /// The expected behaviour is that the server should return an empty list.
  static Future nonExistingOrganizationReceptions(ServiceAgent sa) async {
    const int organizationId = -1;

    _log.info('Looking up contact list for organization $organizationId.');

    final Iterable rRefs =
        await sa.organizationStore.receptions(organizationId);
    expect(rRefs, isEmpty);
    expect(rRefs, isNotNull);
  }

  /// Test server behaviour when trying to create a empty organization
  /// which is invalid.
  ///
  /// The expected behaviour is that the server should return an error.
  static void createEmpty(ServiceAgent sa) {
    model.Organization organization = model.Organization.empty()..id = null;

    _log.info('Creating a empty/invalid organization ${organization.toJson()}');

    return expect(sa.organizationStore.create(organization, sa.user),
        throwsA(const TypeMatcher<ClientError>()));
  }

  /**
   *
   */
  static Future createAfterLastRemove(ServiceAgent sa) async {
    final org = await sa.createsOrganization();

    await sa.deletesOrganization(org);
    await sa.createsOrganization();
  }

  /// Test server behaviour when trying to create a organization.
  ///
  /// The expected behaviour is that the server should return the created
  /// Organization object.
  static Future create(ServiceAgent sa) async {
    _log.info('Checking server behaviour on an existing organization.');
    _log.info('Creating organization');

    final model.Organization newOrg = Randomizer.randomOrganization();
    final model.OrganizationReference newOrgRef =
        await sa.organizationStore.create(newOrg, sa.user);

    _log.info('Fetching organization');

    final model.Organization org = await sa.organizationStore.get(newOrgRef.id);

    _log.info('Asserting properties');
    expect(org, isNotNull);
    expect(org.id, isNotNull);
    expect(org.id, isNot(equals(model.Organization.noId)));
    expect(org.name, isNotEmpty);
    expect(org.notes, isNotNull);
    expect(org.name, newOrg.name);
    expect(org.notes, newOrg.notes);

    _log.info('Test OK. Cleaning up');
  }

  /// Test server behaviour when trying to update a organization event object that
  /// exists.
  ///
  /// The expected behaviour is that the server should return the updated
  /// Organization object.
  static Future update(ServiceAgent sa) async {
    _log.info('Checking server behaviour when updating an organization.');
    _log.info('Creating organization');

    final model.Organization newOrg = Randomizer.randomOrganization();
    final model.OrganizationReference newOrgRef =
        await sa.organizationStore.create(newOrg, sa.user);

    _log.info('Fetching organization');

    final model.Organization org = await sa.organizationStore.get(newOrgRef.id);

    _log.info('Asserting properties');
    expect(org, isNotNull);
    expect(org.id, isNotNull);
    expect(org.id, isNot(equals(model.Organization.noId)));
    expect(org.name, isNotEmpty);
    expect(org.notes, isNotNull);
    expect(org.name, newOrg.name);
    expect(org.notes, newOrg.notes);

    final model.Organization updated = Randomizer.randomOrganization()
      ..id = newOrgRef.id;

    updated.name = updated.name + ' - updated';

    await sa.organizationStore.update(updated, sa.user);

    final model.Organization fetched =
        await sa.organizationStore.get(newOrgRef.id);

    _log.info('Asserting properties');

    expect(fetched, isNotNull);
    expect(fetched.id, isNotNull);
    expect(org.id, isNot(equals(model.Organization.noId)));
    expect(fetched.notes, isNotNull);
    expect(updated.id, equals(fetched.id));

    expect(fetched.id == model.Organization.noId, isFalse);
    expect(fetched.name, isNotEmpty);
    expect(updated.name, equals(fetched.name));
    expect(updated.notes, equals(fetched.notes));
  }

  /// Test server behaviour when trying to update a organization object that
  /// exists but with invalid data.
  ///
  /// The expected behaviour is that the server should return an error,
  static Future updateInvalid(ServiceAgent sa) async {
    final org = await sa.createsOrganization();

    org.id = model.Organization.noId;

    expect(sa.organizationStore.update(org, sa.user),
        throwsA(const TypeMatcher<ClientError>()));
  }

  /// Test server behaviour when trying to delete an organization that exists.
  ///
  /// The expected behaviour is that the server should succeed.
  static Future remove(ServiceAgent sa) async {
    final org = await sa.createsOrganization();

    await sa.organizationStore.get(org.id);

    await sa.deletesOrganization(org);

    expect(sa.organizationStore.get(org.id),
        throwsA(const TypeMatcher<NotFound>()));
  }

  /// Test server behaviour when trying to delete an organization that
  /// do not exists.
  ///
  /// The expected behaviour is that the server should return Not Found error.
  static Future removeNonExisting(ServiceAgent sa) async {
    _log.info('Targeting not found organization for removal');

    return expect(sa.organizationStore.remove(-1, sa.user),
        throwsA(const TypeMatcher<NotFound>()));
  }

  /**
   *
   */
  static Future changeOnCreate(ServiceAgent sa) async {
    final model.Organization created = await sa.createsOrganization();

    Iterable<model.Commit> commits =
        await sa.organizationStore.changes(created.id);

    _log.info('Listing changes and validating.');

    expect(commits.length, equals(1));
    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(sa.user.address));
    expect(commits.first.uid, equals(sa.user.id));

    expect(commits.first.changes.length, equals(1));
    final model.OrganizationChange change = commits.first.changes.first;

    expect(change.changeType, model.ChangeType.add);
    expect(change.oid, created.id);
  }

  /**
   *
   */
  static Future changeOnUpdate(ServiceAgent sa) async {
    final model.Organization created = await sa.createsOrganization();
    await sa.updatesOrganization(created);

    Iterable<model.Commit> commits =
        await sa.organizationStore.changes(created.id);

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
    final model.OrganizationChange latestChange = commits.first.changes.first;
    final model.OrganizationChange oldestChange = commits.last.changes.first;

    expect(latestChange.changeType, model.ChangeType.modify);
    expect(latestChange.oid, created.id);

    expect(oldestChange.changeType, model.ChangeType.add);
    expect(oldestChange.oid, created.id);
  }

  /**
   *
   */
  static Future changeOnRemove(ServiceAgent sa) async {
    final model.Organization created = await sa.createsOrganization();
    await sa.deletesOrganization(created);

    Iterable<model.Commit> commits =
        await sa.organizationStore.changes(created.id);

    _log.info('Listing changes and validating.');

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
    final model.OrganizationChange latestChange = commits.first.changes.first;
    final model.OrganizationChange oldestChange = commits.last.changes.first;

    expect(latestChange.changeType, model.ChangeType.delete);
    expect(latestChange.oid, created.id);

    expect(oldestChange.changeType, model.ChangeType.add);
    expect(oldestChange.oid, created.id);
  }
}
