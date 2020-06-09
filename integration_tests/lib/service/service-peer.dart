part of ort.service;

abstract class Peer {
  static Logger log = Logger('Test.Peer');

  /// Test for the presence of hangup events when a peer
  /// changes registration status.
  static Future eventPresence(Receptionist receptionist) async {
    String peerName = receptionist.user.extension_;

    log.info('Unregistering peer $peerName to assert state');

    Future unregisterEvent = receptionist.notificationSocket.onEvent
        .firstWhere((event.Event e) =>
            e is event.PeerState &&
            e.peer.name == peerName &&
            !e.peer.registered)
        .timeout(Duration(seconds: 10));

    await receptionist.phone.unregister();
    await unregisterEvent;

    log.info('Flushing event stack');
    receptionist.eventStack.clear();

    log.info('Registering peer $peerName');
    await receptionist.phone.register();
    log.info('Waiting for peer state event');

    event.PeerState peerStateEvent =
        await receptionist.waitForPeerState(receptionist.user.extension_);
    log.info('Got event $peerStateEvent');
    expect(peerStateEvent.peer.registered, isTrue);
    expect(peerStateEvent.peer.name, equals(peerName));

    log.info('Flushing event stack');
    receptionist.eventStack.clear();

    log.info('Unregistering peer $peerName to complete cycle');
    receptionist.phone.unregister();
    log.info('Waiting for peer state event');

    peerStateEvent =
        await receptionist.waitForPeerState(receptionist.user.extension_);

    log.info('Got event $peerStateEvent');
    expect(peerStateEvent.peer.registered, isFalse);
    expect(peerStateEvent.peer.name, equals(peerName));

    log.info('Test done.');
  }

  static Future list(service.CallFlowControl callFlowControl) => callFlowControl
      .peerList()
      .then((Iterable<model.Peer> peers) => expect(peers.length, isPositive));
}
