part of ort.storage;

abstract class User {
  static final Logger _log = Logger('$_libraryName.User');

  /// Test server behaviour when trying to aquire a user object that does
  /// not exist.
  ///
  /// The expected behaviour is that the server should return a Not Found error.
  static void nonExisting(ServiceAgent sa) {
    _log.info('Checking server behaviour on a non-existing user.');

    expect(sa.userStore.get(-1), throwsA(notFoundError));
  }

  /// Test server behaviour when trying to aquire a user object that exists.
  ///
  /// The expected behaviour is that the server should return the
  /// User object.
  static Future existing(ServiceAgent sa) async {
    _log.info('Checking server behaviour on an existing user.');

    final model.User created = await sa.createsUser();

    final model.User fetched = await sa.userStore.get(created.id);

    expect(created.address, equals(fetched.address));
    expect(created.id, equals(fetched.id));
    expect(created.name, equals(fetched.name));
    expect(created.extension_, equals(fetched.extension_));
    expect(created.portrait, equals(fetched.portrait));
    expect(created.groups, equals(fetched.groups));
    expect(created.identities, equals(fetched.identities));
  }

  static Future create(ServiceAgent sa) async {
    _log.info('Checking server behaviour on an user creation.');

    final model.User newUser = Randomizer.randomUser();
    final model.UserReference uRef =
        await sa.userStore.create(newUser, sa.user);

    final model.User created = await sa.userStore.get(uRef.id);

    expect(created.address, equals(newUser.address));
    expect(created.id, isNotNull);
    expect(created.id, greaterThan(model.noId));
    expect(created.name, equals(newUser.name));
    expect(created.extension_, equals(newUser.extension_));
    expect(created.portrait, equals(newUser.portrait));
    expect(created.groups, equals(newUser.groups));
    expect(created.identities, equals(newUser.identities));
  }

  static Future createAfterLastRemove(ServiceAgent sa) async {
    final model.User user = await sa.createsUser();

    await sa.removesUser(user);
    await await sa.createsUser();
  }

  static Future update(ServiceAgent sa) async {
    _log.info('Checking server behaviour on an user updating.');

    final model.User created = await sa.createsUser();

    final model.User changed = Randomizer.randomUser()..id = created.id;
    final uRef = await sa.userStore.update(changed, sa.user);
    final model.User fetched = await sa.userStore.get(uRef.id);

    expect(changed.address, equals(fetched.address));
    expect(changed.id, equals(fetched.id));
    expect(changed.name, equals(fetched.name));
    expect(changed.extension_, equals(fetched.extension_));
    expect(changed.portrait, equals(fetched.portrait));
    expect(changed.groups, equals(fetched.groups));
    expect(changed.identities, equals(fetched.identities));
  }

  static Future remove(ServiceAgent sa) async {
    _log.info('Checking server behaviour on an user removal.');

    model.User created = await sa.createsUser();
    expect(created.id, greaterThan(model.noId));

    await sa.userStore.remove(created.id, sa.user);

    return expect(
        sa.userStore.get(created.id), throwsA(TypeMatcher<NotFound>()));
  }

  /// Test server behaviour when trying to aquire a list of user objects
  ///
  /// The expected behaviour is that the server should return a list of
  /// User objects.
  static Future list(ServiceAgent sa) async {
    _log.info('Checking server behaviour on list of users.');

    Iterable<model.UserReference> uRefs = await sa.userStore.list();

    expect(uRefs.length, equals(1));
    expect(uRefs.any((ref) => ref.id == sa.user.id), isTrue);

    {
      Iterable<model.UserReference> uRefs = await sa.userStore.list();

      expect(uRefs.length, equals(1));
      expect(uRefs.any((ref) => ref.id == sa.user.id), isTrue);
    }

    final user1 = await sa.createsUser();
    {
      Iterable<model.UserReference> uRefs = await sa.userStore.list();

      expect(uRefs.length, equals(2));
      expect(uRefs.any((ref) => ref.id == user1.id), isTrue);
    }

    final user2 = await sa.createsUser();
    {
      Iterable<model.UserReference> uRefs = await sa.userStore.list();

      expect(uRefs.length, equals(3));
      expect(uRefs.any((ref) => ref.id == user2.id), isTrue);
    }

    await sa.removesUser(user1);
    {
      Iterable<model.UserReference> uRefs = await sa.userStore.list();

      expect(uRefs.length, equals(2));
      expect(uRefs.any((ref) => ref.id == user1.id), isFalse);
    }
  }

  /// Test server behaviour when trying to list all available groups
  ///
  /// The expected behaviour is that the server should return a list of
  /// UserGroup objects.
  static Future listAllGroups(ServiceAgent sa) async {
    _log.info('Looking up group list.');

    Iterable<String> groups = await sa.userStore.groups();
    expect(groups, isNotNull);
    expect(groups, isNotEmpty);
    expect(groups, contains(model.UserGroups.administrator));
    expect(groups, contains(model.UserGroups.receptionist));
    expect(groups, contains(model.UserGroups.serviceAgent));
  }

  /// Test server behaviour when trying to list all available groups
  ///
  /// The expected behaviour is that the server should return a list of
  /// UserGroup objects.
  static Future userGroups(ServiceAgent sa) async {
    final model.User user = await sa.createsUser();
    if (user.groups.isNotEmpty) {
      user.groups.clear();
      await sa.userStore.update(user, sa.user);
    }

    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.groups, isEmpty);
    }
  }

  /// Add a user to a group.
  static Future joinGroup(ServiceAgent sa) async {
    final model.User user = await sa.createsUser();
    _log.info('Clearing user groups');
    if (user.groups.isNotEmpty) {
      user.groups = [];
      await sa.userStore.update(user, sa.user);
    }

    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.groups, isEmpty);
    }

    final admin = model.UserGroups.administrator;
    _log.info('Adding user groups to $admin group');
    user.groups.add(admin);
    await sa.userStore.update(user, sa.user);

    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.groups.length, equals(1));
    }

    _log.info('Re-adding user groups to ${admin} group');
    user.groups.add(admin);

    try {
      await sa.userStore.update(user, sa.user);
      fail('Expected storage.Unchanged');
    } on Unchanged {
      _log.info('Got expected exception');
    }
    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.groups.length, equals(1));
    }

    final saGroup = model.UserGroups.serviceAgent;
    _log.info('Adding user to $saGroup group');
    user.groups.add(saGroup);
    await sa.userStore.update(user, sa.user);
    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.groups.length, equals(2));
    }
  }

  /// Remove a user from a group.
  static Future leaveGroup(ServiceAgent sa) async {
    final model.User user = await sa.createsUser();
    _log.info('Clearing user groups');
    if (user.groups.isNotEmpty) {
      user.groups = [];
      await sa.userStore.update(user, sa.user);
    }

    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.groups, isEmpty);
    }

    final saGroup = model.UserGroups.serviceAgent;
    final admin = model.UserGroups.administrator;
    _log.info('Adding user groups to $admin and $saGroup group');
    user.groups.addAll([admin, saGroup]);
    await sa.userStore.update(user, sa.user);

    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.groups.length, equals(2));
    }

    _log.info('Removing user from $admin group');
    user.groups.remove(admin);
    await sa.userStore.update(user, sa.user);
    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.groups.length, equals(1));
    }

    _log.info('Removing user from $admin group again');
    user.groups.remove(admin);
    try {
      await sa.userStore.update(user, sa.user);
      fail('Expected storage.Unchanged');
    } on Unchanged {
      _log.info('Got expected exception');
    }
    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.groups.length, equals(1));
    }
  }

  /// Add an identity to a user.
  static Future getUserByIdentity(ServiceAgent sa) async {
    final model.User created = await sa.createsUser();
    _log.info('Clearing user identities');
    if (created.identities.isNotEmpty) {
      created.identities = [];
      await sa.userStore.update(created, sa.user);
    }

    {
      final fetched = await sa.userStore.get(created.id);
      expect(fetched.identities, isEmpty);
    }

    final identity = Randomizer.randomGmail();

    _log.info('Adding user identity $identity');
    created.identities.add(identity);
    await sa.userStore.update(created, sa.user);

    {
      final fetched = await sa.userStore.get(created.id);
      expect(fetched.identities.length, equals(1));
    }

    final fetched = await sa.userStore.getByIdentity(identity);
    expect(created.address, equals(fetched.address));
    expect(created.id, equals(fetched.id));
    expect(created.name, equals(fetched.name));
    expect(created.extension_, equals(fetched.extension_));
    expect(created.portrait, equals(fetched.portrait));
    expect(created.groups, equals(fetched.groups));
    expect(created.identities, equals(fetched.identities));
  }

  /// Add an identity to a user.
  static Future addUserIdentity(ServiceAgent sa) async {
    final model.User user = await sa.createsUser();
    _log.info('Clearing user identities');
    if (user.identities.isNotEmpty) {
      user.identities = [];
      await sa.userStore.update(user, sa.user);
    }

    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.identities, isEmpty);
    }

    final adminIdentity = 'admin@world.com';
    _log.info('Adding user identity $adminIdentity');
    user.identities.add(adminIdentity);
    await sa.userStore.update(user, sa.user);

    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.identities.length, equals(1));
    }

    _log.info('Adding user identity $adminIdentity');
    user.identities.add(adminIdentity);

    try {
      await sa.userStore.update(user, sa.user);
      fail('Expected storage.Unchanged');
    } on Unchanged {
      _log.info('Got expected exception');
    }
    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.identities.length, equals(1));
    }

    final otherIdentity = 'non-admin@nowhere.com';
    _log.info('Adding identity $otherIdentity');
    user.identities.add(otherIdentity);
    await sa.userStore.update(user, sa.user);
    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.identities.length, equals(2));
    }
  }

  /// Remove an identity from a user.
  static Future removeUserIdentity(ServiceAgent sa) async {
    final model.User user = await sa.createsUser();
    _log.info('Clearing user identities');
    if (user.identities.isNotEmpty) {
      user.identities = [];
      await sa.userStore.update(user, sa.user);
    }

    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.identities, isEmpty);
    }

    final adminIdentity = 'admin@world.com';
    final otherIdentity = 'non-admin@nowhere.com';

    _log.info('Adding identities $adminIdentity and $otherIdentity');
    user.identities.addAll([adminIdentity, otherIdentity]);
    await sa.userStore.update(user, sa.user);

    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.identities.length, equals(2));
    }

    _log.info('Removing identity $adminIdentity');
    user.identities.remove(adminIdentity);
    await sa.userStore.update(user, sa.user);
    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.identities.length, equals(1));
    }

    _log.info('Removing identity $adminIdentity again');
    user.identities.remove(adminIdentity);
    try {
      await sa.userStore.update(user, sa.user);
      fail('Expected storage.Unchanged');
    } on Unchanged {
      _log.info('Got expected exception');
    }
    {
      final fetched = await sa.userStore.get(user.id);
      expect(fetched.identities.length, equals(1));
    }
  }

  /**
   *
   */
  static Future changeOnCreate(ServiceAgent sa) async {
    final model.User created = await sa.createsUser();

    Iterable<model.Commit> commits = await sa.userStore.changes(created.id);

    _log.info('Listing changes and validating.');

    expect(commits.length, equals(1));
    expect(commits.first.changedAt.millisecondsSinceEpoch,
        lessThan(DateTime.now().millisecondsSinceEpoch));
    expect(commits.first.authorIdentity, equals(sa.user.address));
    expect(commits.first.uid, equals(sa.user.id));

    expect(commits.first.changes.length, equals(1));
    final model.UserChange change = commits.first.changes.first;

    expect(change.changeType, model.ChangeType.add_);
    expect(change.uid, created.id);
  }

  /**
   *
   */
  static Future changeOnUpdate(ServiceAgent sa) async {
    final model.User created = await sa.createsUser();

    await sa.updatesUser(created);

    Iterable<model.Commit> commits = await sa.userStore.changes(created.id);

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
    final model.UserChange latestChange = commits.first.changes.first;
    final model.UserChange oldestChange = commits.last.changes.first;

    expect(latestChange.changeType, model.ChangeType.modify_);
    expect(latestChange.uid, created.id);

    expect(oldestChange.changeType, model.ChangeType.add_);
    expect(oldestChange.uid, created.id);
  }

  /**
   *
   */
  static Future changeOnRemove(ServiceAgent sa) async {
    final model.User created = await sa.createsUser();

    await sa.removesUser(created);

    Iterable<model.Commit> commits = await sa.userStore.changes(created.id);

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
    final model.UserChange latestChange = commits.first.changes.first;
    final model.UserChange oldestChange = commits.last.changes.first;

    expect(latestChange.changeType, model.ChangeType.delete_);
    expect(latestChange.uid, created.id);

    expect(oldestChange.changeType, model.ChangeType.add_);
    expect(oldestChange.uid, created.id);
  }
}
