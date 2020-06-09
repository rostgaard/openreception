part of ort.service;

abstract class AuthService {
  static final Logger log = Logger('$_namespace.AuthService');

  /// Test server behaviour when trying to aquire a user object from a token that
  /// does not exist.
  ///
  /// The expected behaviour is that the server should return a Not Found error.
  static Future nonExistingToken(ServiceAgent sa) async {
    const badToken = 'nocandosir';

    log.info('Checking server behaviour on a non-existing token.');

    await expect(
        sa.authService.userOf(badToken), throwsA(TypeMatcher<NotFound>()));
  }

  /// Test server behaviour when trying to aquire a user object from a token
  /// that exists.
  ///
  /// The expected behaviour is that the server should return a User object.
  static Future existingToken(ServiceAgent sa) async {
    log.info('Checking server behaviour on a non-existing token.');

    final model.User user = await sa.authService.userOf(sa.authToken.tokenName);
    expect(user.id, equals(sa.user.id));
    expect(user.name, sa.user.name);
    expect(user.address, sa.user.address);
    expect(user.extension_, sa.user.extension_);
    expect(user.groups, sa.user.groups);
    expect(user.identities, sa.user.identities);

    log.info('Test complete');
  }

  /// Test server behaviour when trying to validae a token that does not exist.
  ///
  /// The expected behaviour is that the server should return a Not Found error.
  static Future validateNonExistingToken(ServiceAgent sa) async {
    const badToken = 'nocandosir';

    log.info('Checking server behaviour on a non-existing token.');

    await expect(
        sa.authService.userOf(badToken), throwsA(TypeMatcher<NotFound>()));
  }

  /// Test server behaviour when trying to validate a token that exists.
  ///
  /// The expected behaviour is that the server should normally.
  static Future validateExistingToken(ServiceAgent sa) async {
    log.info('Checking server behaviour on a non-existing token.');

    await sa.authService.userOf(sa.authToken.tokenName);
  }
}
