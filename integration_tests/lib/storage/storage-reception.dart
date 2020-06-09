part of ort.storage;

class Reception {
  static Logger _log = Logger('$_libraryName.Reception');

  /// Test server behaviour when trying to aquire a reception event object that
  /// does not exist.
  ///
  /// The expected behaviour is that the server should return a Not Found error.
  static Future nonExistingReception(ServiceAgent sa) async {
    _log.info('Checking server behaviour on a non-existing reception.');

    expect(sa.receptionStore.get(-1), throwsA(TypeMatcher<NotFound>()));
  }

  /// Test server behaviour when trying to aquire a reception event object that
  /// exists.
  ///
  /// The expected behaviour is that the server should return the
  /// Reception object.
  static Future existingReception(ServiceAgent sa) async {
    final org = await sa.createsOrganization();
    final rec = Randomizer.randomReception()..oid = org.id;
    final created = await sa.createsReception(org, rec);

    expect(created.id != model.noId, isTrue);
    expect(rec.addresses, equals(created.addresses));
    expect(rec.alternateNames, equals(created.alternateNames));
    //expect(rec.attributes, equals(created.attributes));
    expect(rec.bankingInformation, equals(created.bankingInformation));
    expect(rec.customerTypes, equals(created.customerTypes));
    expect(rec.emailAddresses, equals(created.emailAddresses));
    expect(rec.dialplan, equals(created.dialplan));

    expect(rec.greeting, equals(created.greeting));
    expect(rec.handlingInstructions, equals(created.handlingInstructions));
    expect(rec.openingHours, equals(created.openingHours));
    expect(rec.otherData, equals(created.otherData));
    expect(rec.product, equals(created.product));
    expect(rec.salesMarketingHandling, equals(created.salesMarketingHandling));
    expect(rec.shortGreeting, equals(created.shortGreeting));
    expect(rec.phoneNumbers, equals(created.phoneNumbers));
    expect(rec.vatNumbers, equals(created.vatNumbers));
    expect(rec.websites, equals(created.websites));
    expect(rec.name, equals(created.name));
  }

  /// Test server behaviour when trying to aquire a list of reception objects
  ///
  /// The expected behaviour is that the server should return a list of
  /// Reception objects.
  static Future listReceptions(ServiceAgent sa) async {
    _log.info('Checking server behaviour on list of receptions.');
    final org1 = await sa.createsOrganization();
    final org2 = await sa.createsOrganization();

    {
      final rRefs = await sa.receptionStore.list();
      expect(rRefs.length, equals(0));
    }

    final rec1 = await sa.createsReception(org1);
    {
      final rRefs = await sa.receptionStore.list();
      expect(rRefs.length, equals(1));
      expect(rRefs.any((ref) => ref.id == rec1.id), isTrue);
    }

    final rec2 = await sa.createsReception(org1);
    {
      final rRefs = await sa.receptionStore.list();
      expect(rRefs.length, equals(2));
      expect(rRefs.any((ref) => ref.id == rec1.id), isTrue);
      expect(rRefs.any((ref) => ref.id == rec2.id), isTrue);
    }

    final rec3 = await sa.createsReception(org2);
    {
      final rRefs = await sa.receptionStore.list();
      expect(rRefs.length, equals(3));
      expect(rRefs.any((ref) => ref.id == rec1.id), isTrue);
      expect(rRefs.any((ref) => ref.id == rec2.id), isTrue);
      expect(rRefs.any((ref) => ref.id == rec3.id), isTrue);
    }

    await sa.removesReception(rec1);
    {
      final rRefs = await sa.receptionStore.list();
      expect(rRefs.length, equals(2));
      expect(rRefs.any((ref) => ref.id == rec1.id), isFalse);
      expect(rRefs.any((ref) => ref.id == rec2.id), isTrue);
      expect(rRefs.any((ref) => ref.id == rec3.id), isTrue);
    }
  }

  /// Test server behaviour when trying to create a reception.
  ///
  /// The expected behaviour is that the server should return the created
  /// Reception object.
  static Future create(ServiceAgent sa) async {
    final org = await sa.createsOrganization();
    final rec = Randomizer.randomReception()..oid = org.id;
    await sa.createsReception(org, rec);
  }

  /**
   *
   */
  static Future createAfterLastRemove(ServiceAgent sa) async {
    final org = await sa.createsOrganization();
    final rec = await sa.createsReception(org);

    await sa.removesReception(rec);
    await sa.createsReception(org);
  }

  /// Test server behaviour when trying to update a reception object that
  /// do not exists.
  ///
  /// The expected behaviour is that the server should return Not Found error
  static Future updateNonExisting(ServiceAgent sa) async {
    final rec = Randomizer.randomReception()..id = -1;
    expect(sa.receptionStore.update(rec, sa.user),
        throwsA(TypeMatcher<NotFound>()));
  }

  /// Test server behaviour when trying to update a reception object that
  /// exists but with invalid data.
  ///
  /// The expected behaviour is that the server should return Server Error
  static Future updateInvalid(ServiceAgent sa) async {
    final rec = Randomizer.randomReception()..id = model.noId;
    expect(sa.receptionStore.update(rec, sa.user),
        throwsA(TypeMatcher<ClientError>()));
  }

  /// Test server behaviour when trying to update a reception event object that
  /// exists.
  ///
  /// The expected behaviour is that the server should return the updated
  /// Reception object.
  static Future update(ServiceAgent sa) async {
    final org = await sa.createsOrganization();
    final created = await sa.createsReception(org);

    final updated = Randomizer.randomReception()
      ..id = created.id
      ..oid = created.oid;

    final fetched = await sa.updateReception(updated);

    expect(fetched.id != model.noId, isTrue);
    expect(updated.addresses, equals(fetched.addresses));
    expect(updated.alternateNames, equals(fetched.alternateNames));
    //expect(updated.attributes, equals(fetched.attributes));
    expect(updated.bankingInformation, equals(fetched.bankingInformation));
    expect(updated.customerTypes, equals(fetched.customerTypes));
    expect(updated.emailAddresses, equals(fetched.emailAddresses));
    expect(updated.dialplan, equals(fetched.dialplan));

    expect(updated.greeting, equals(fetched.greeting));
    expect(updated.handlingInstructions, equals(fetched.handlingInstructions));
    expect(updated.openingHours, equals(fetched.openingHours));
    expect(updated.otherData, equals(fetched.otherData));
    expect(updated.product, equals(fetched.product));
    expect(
        updated.salesMarketingHandling, equals(fetched.salesMarketingHandling));
    expect(updated.shortGreeting, equals(fetched.shortGreeting));
    expect(updated.phoneNumbers, equals(fetched.phoneNumbers));
    expect(updated.vatNumbers, equals(fetched.vatNumbers));
    expect(updated.websites, equals(fetched.websites));
    expect(updated.name, equals(fetched.name));
  }

  /// Test server behaviour when trying to delete an reception that exists.
  ///
  /// The expected behaviour is that the server should succeed.
  static Future remove(ServiceAgent sa) async {
    final org = await sa.createsOrganization();
    final rec = await sa.createsReception(org);

    await sa.receptionStore.get(rec.id);
    await sa.removesReception(rec);

    expect(sa.receptionStore.get(rec.id), throwsA(TypeMatcher<NotFound>()));
  }

  /**
   *
   */
  static Future changeOnCreate(ServiceAgent sa) async {
    final model.Reception created =
        await sa.createsReception(await sa.createsOrganization());

    Iterable<model.Commit> commits =
        await sa.receptionStore.changes(created.id);

    _log.info('Listing changes and validating.');

    expect(commits.length, equals(1));
    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(sa.user.address));
    expect(commits.first.uid, equals(sa.user.id));

    expect(commits.first.changes.length, equals(1));
    final model.ReceptionChange change = commits.first.changes.first;

    expect(change.changeType, model.ChangeType.add_);
    expect(change.rid, created.id);
  }

  /**
   *
   */
  static Future changeOnUpdate(ServiceAgent sa) async {
    final model.Reception created =
        await sa.createsReception(await sa.createsOrganization());
    await sa.updatesReception(created);

    Iterable<model.Commit> commits =
        await sa.receptionStore.changes(created.id);

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
    final model.ReceptionChange latestChange = commits.first.changes.first;
    final model.ReceptionChange oldestChange = commits.last.changes.first;

    expect(latestChange.changeType, model.ChangeType.modify_);
    expect(latestChange.rid, created.id);

    expect(oldestChange.changeType, model.ChangeType.add_);
    expect(oldestChange.rid, created.id);
  }

  /**
   *
   */
  static Future changeOnRemove(ServiceAgent sa) async {
    final model.Reception created =
        await sa.createsReception(await sa.createsOrganization());
    await sa.removesReception(created);

    Iterable<model.Commit> commits =
        await sa.receptionStore.changes(created.id);

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
    final model.ReceptionChange latestChange = commits.first.changes.first;
    final model.ReceptionChange oldestChange = commits.last.changes.first;

    expect(latestChange.changeType, model.ChangeType.delete_);
    expect(latestChange.rid, created.id);

    expect(oldestChange.changeType, model.ChangeType.add_);
    expect(oldestChange.rid, created.id);
  }
}
