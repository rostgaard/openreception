part of ort.storage;

abstract class Calendar {
  static final Logger _log = Logger('$_libraryName.Calendar');

  /**
   *
   */
  static create(model.Owner owner, storage.Calendar calendarStore,
      model.User creator) async {
    await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);
  }

  /**
   *
   */
  static createAfterLastRemove(model.Owner owner,
      storage.Calendar calendarStore, model.User creator) async {
    final entry = await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);

    await calendarStore.remove(entry.id, owner, creator);
    await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);
  }

  /**
   *
   */
  static update(model.Owner owner, storage.Calendar calendarStore,
      model.User creator) async {
    model.CalendarEntry createdEntry = await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);

    {
      model.CalendarEntry changes = Randomizer.randomCalendarEntry()
        ..id = createdEntry.id;
      createdEntry = changes;
    }

    await calendarStore.update(createdEntry, owner, creator);
  }

  /// Test server behaviour when trying to list calendar events associated with
  /// a given owner.
  ///
  /// The expected behaviour is that the server should return a list of
  /// CalendarEntry objects.
  static Future get(model.Owner owner, storage.Calendar calendarStore,
      model.User creator) async {
    model.CalendarEntry created = await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);

    model.CalendarEntry fetched = await calendarStore.get(created.id, owner);
    _log.finest('Created:');
    _log.finest(created.toJson());
    _log.finest('Fetched:');
    _log.finest(fetched.toJson());
    final oneMs = Duration(milliseconds: 1);

    expect(created.id, equals(fetched.id));
    expect(created.start.difference(fetched.start), lessThan(oneMs));
    expect(created.stop.difference(fetched.stop), lessThan(oneMs));
    expect(created.content, equals(fetched.content));
  }

  /// Test server behaviour when trying to aquire a calendar event object that
  /// is non-existing.
  ///
  /// The expected behaviour is that the server should return "Not Found".
  static Future getNonExistingEntry(storage.Calendar calendarStore) async {
    try {
      await calendarStore.get(-1, model.OwningReception(1));
      fail('Expected NotFound exception');
    } on NotFound {
      // Successs
      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  /**
   *
   */
  static list(model.Owner owner, storage.Calendar calendarStore,
      model.User creator) async {
    model.CalendarEntry created = await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);

    Iterable<model.CalendarEntry> listing = await calendarStore.list(owner);

    model.CalendarEntry fetched =
        listing.firstWhere((entry) => entry.id == created.id);

    final oneMs = Duration(milliseconds: 1);

    expect(created.id, equals(fetched.id));
    expect(created.start.difference(fetched.start), lessThan(oneMs));
    expect(created.stop.difference(fetched.stop), lessThan(oneMs));
    expect(created.content, equals(fetched.content));
  }

  /**
   *
   */
  static remove(model.Owner owner, storage.Calendar calendarStore,
      model.User creator) async {
    model.CalendarEntry created = await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);

    _log.info('Removing calendar entry');
    await calendarStore.remove(created.id, owner, creator);

    _log.info('Asserting that the created entry is no longer found');
    expect(
        calendarStore.get(created.id, owner), throwsA(TypeMatcher<NotFound>()));
  }

  /// Test server behaviour with regards to calendar changes.
  /// This function creates an entry and asserts that a change is also present.
  static Future changeOnCreate(model.Owner owner,
      storage.Calendar calendarStore, model.User creator) async {
    model.CalendarEntry created = await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);

    _log.info('Creating a calendar event for owner $owner.');

    Iterable<model.Commit> commits = await calendarStore.changes(owner);

    _log.info('Listing changes and validating.');

    expect(commits.length, equals(1));
    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(creator.address));
    expect(commits.first.uid, equals(creator.id));

    expect(commits.first.changes.length, equals(1));
    final model.CalendarChange change = commits.first.changes.first;

    expect(change.changeType, model.ChangeType.add);
    expect(change.eid, created.id);
  }

  /**
   *
   */
  static Future latestChangeOnCreate(model.Owner owner,
      storage.Calendar calendarStore, model.User creator) async {
    model.CalendarEntry created = await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);

    _log.info('Creating a calendar event for owner $owner.');

    model.Commit latestCommit =
        (await calendarStore.changes(owner, created.id)).first;

    _log.info('Listing changes and validating.');

    expect(latestCommit.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(latestCommit.authorIdentity, equals(creator.address));
    expect(latestCommit.uid, equals(creator.id));

    final model.CalendarChange change = latestCommit.changes.first;

    expect(change.changeType, model.ChangeType.add);
    expect(change.eid, created.id);
  }

  /// Test server behaviour with regards to calendar changes.
  /// This function update an entry and asserts that another change is present.
  static Future changeOnUpdate(model.Owner owner,
      storage.Calendar calendarStore, model.User creator) async {
    model.CalendarEntry created = await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);

    _log.info('Creating a calendar event for owner $owner.');

    model.CalendarEntry changed = Randomizer.randomCalendarEntry()
      ..id = created.id;

    Iterable<model.Commit> commitsBefore = await calendarStore.changes(owner);
    await calendarStore.update(changed, owner, creator);
    Iterable<model.Commit> commits = await calendarStore.changes(owner);

    _log.info('Listing changes and validating.');

    expect(commits.length, equals(commitsBefore.length + 1));

    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(creator.address));

    expect(commits.last.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.last.authorIdentity, equals(creator.address));

    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(creator.address));
    expect(commits.first.uid, equals(creator.id));

    expect(commits.first.changes.length, equals(1));
    expect(commits.last.changes.length, equals(1));
    final model.CalendarChange latestChange = commits.first.changes.first;
    final model.CalendarChange oldestChange = commits.last.changes.first;

    expect(latestChange.changeType, model.ChangeType.modify);
    expect(latestChange.eid, created.id);

    expect(oldestChange.changeType, model.ChangeType.add);
    expect(oldestChange.eid, created.id);
  }

  /**
   *
   */
  static Future latestChangeOnUpdate(model.Owner owner,
      storage.Calendar calendarStore, model.User creator) async {
    model.CalendarEntry created = await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);

    _log.info('Creating a calendar event for owner $owner.');

    model.CalendarEntry changed = Randomizer.randomCalendarEntry()
      ..id = created.id;

    await calendarStore.update(changed, owner, creator);
    model.Commit latestCommit =
        (await calendarStore.changes(owner, created.id)).first;

    _log.info('Listing changes and validating.');

    expect(latestCommit.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(latestCommit.authorIdentity, equals(creator.address));
    expect(latestCommit.uid, equals(creator.id));

    final model.CalendarChange change = latestCommit.changes.first;

    expect(change.changeType, model.ChangeType.modify);
    expect(change.eid, created.id);
  }

  /// Test server behaviour with regards to calendar changes.
  /// This function removes an entry and asserts that no changes are present.
  static Future changeOnRemove(model.Owner owner,
      storage.Calendar calendarStore, model.User creator) async {
    model.CalendarEntry created = await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);

    _log.info('Removing calendar event for owner $owner.');

    Iterable<model.Commit> commitsBefore = await calendarStore.changes(owner);
    await calendarStore.remove(created.id, owner, creator);
    Iterable<model.Commit> commits = await calendarStore.changes(owner);

    _log.info('Listing changes and validating.');

    expect(commits.length, equals(commitsBefore.length + 1));

    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(creator.address));

    expect(commits.last.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.last.authorIdentity, equals(creator.address));

    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(creator.address));
    expect(commits.first.uid, equals(creator.id));

    expect(commits.first.changes.length, equals(1));
    expect(commits.last.changes.length, equals(1));
    final model.CalendarChange latestChange = commits.first.changes.first;
    final model.CalendarChange oldestChange = commits.last.changes.first;

    expect(latestChange.changeType, model.ChangeType.delete);
    expect(latestChange.eid, created.id);

    expect(oldestChange.changeType, model.ChangeType.add);
    expect(oldestChange.eid, created.id);
  }

  /// Test what happens when the last object of a kind is removed.
  /// The motivation for this test is that the git-tracked filestore will
  /// clean out empty folders, potentially leaving the filestore in an
  /// inconsistent state that will make every subsequent creation fail.
  /// This test asserts that subsequent creates do not fail after removal of
  /// the last object.
  static Future latestChangeOnRemove(model.Owner owner,
      storage.Calendar calendarStore, model.User creator) async {
    model.CalendarEntry created = await calendarStore.create(
        Randomizer.randomCalendarEntry(), owner, creator);

    _log.info('Removing calendar event for owner $owner.');

    await calendarStore.remove(created.id, owner, creator);
    model.Commit latestCommit =
        (await calendarStore.changes(owner, created.id)).first;

    _log.info('Listing changes and validating.');

    expect(latestCommit.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(latestCommit.authorIdentity, equals(creator.address));
    expect(latestCommit.uid, equals(creator.id));

    final model.CalendarChange change = latestCommit.changes.first;

    expect(change.changeType, model.ChangeType.delete);
    expect(change.eid, created.id);
  }
}
