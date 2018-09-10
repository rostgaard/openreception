part of ort.service;

abstract class PeerAccountService {
  static Logger _log = Logger('$_namespace.PeerAccountService');

  /**
   *
   */
  static Future list(service.PeerAccount paService) async {
    expect(await paService.list(), TypeMatcher<List>());
  }

  /**
   *
   */
  static Future deploy(model.User user, service.PeerAccount paService) async {
    final model.PeerAccount pa = Randomizer.randomPeerAccount();
    _log.info('Deploying peer account ${pa.toJson()} for user'
        ' ${user.toJson()}');

    await paService.deployAccount(pa, user.id);
    expect((await paService.list()).contains(pa.username), isTrue);

    await paService.remove(pa.username);
  }

  /**
   *
   */
  static Future remove(model.User user, service.PeerAccount paService) async {
    final model.PeerAccount pa = Randomizer.randomPeerAccount();
    _log.info('Deploying peer account ${pa.toJson()} '
        'for user ${user.toJson()}');

    await paService.deployAccount(pa, user.id);
    await paService.remove(pa.username);
    expect((await paService.list()).contains(pa.username), isFalse);
  }

  /**
   *
   */
  static Future deployAndRegister(
      model.User user,
      service.PeerAccount paService,
      service.CallFlowControl callFlow,
      service.RESTDialplanStore dpStore,
      String externalHostname) async {
    final model.PeerAccount pa = Randomizer.randomPeerAccount();
    _log.info('Deploying peer account ${pa.toJson()} for user'
        ' ${user.toJson()}');

    await paService.deployAccount(pa, user.id);
    await dpStore.reloadConfig();
    await callFlow.stateReload();

    final phonio.SIPAccount account =
        phonio.SIPAccount(pa.username, pa.password, externalHostname);

    final phonio.PJSUAProcess phone = phonio.PJSUAProcess(
        config.simpleClientBinaryPath, config.pjsuaPortAvailablePorts.last);

    phone.addAccount(account);
    await phone.initialize();
    await phone.register();

    await Future.doWhile(() async {
      bool registered = (await callFlow.peerList())
          .firstWhere((peer) => peer.name == pa.username)
          .registered;

      if (!registered) {
        await Future.delayed(Duration(milliseconds: 100));
        return true;
      }
      return false;
    }).timeout(Duration(seconds: 10));

    await phone.unregister();
    await phone.finalize();

    await paService.remove(pa.username);
  }
}
