part of ort.support;

class ServiceAgent {
  final Directory runpath;
  final TestEnvironment env;
  final model.User user;
  final Logger _log = Logger('ServiceAgent');
  AuthToken get authToken => AuthToken(user);
  Transport.WebSocketClient _ws;
  Service.CallFlowControl callflow;
  Service.RESTConfiguration configService;
  Service.Authentication authService;
  Service.NotificationService _notificationService;
  Service.NotificationSocket _notificationSocket;

  /**
   *
   */
  Future<Stream<event.Event>> get notifications async =>
      (await notificationSocket).onEvent;

  /**
   *
   */
  Future<Service.NotificationService> get notificationService async {
    if (_notificationService == null) {
      final client = env.httpClient;
      _notificationService = (await env.requestNotificationserverProcess())
          .bindClient(client, authToken);
    }

    return _notificationService;
  }

  /**
   *
   */
  Future<Service.NotificationSocket> get notificationSocket async {
    if (_notificationSocket == null) {
      _ws = env.requestWebsocket();

      _notificationSocket = await (await env.requestNotificationserverProcess())
          .bindWebsocketClient(_ws, authToken);
    }

    return _notificationSocket;
  }

  /**
   *
   */
  storage.User _userStore;

  void set userStore(storage.User uStore) {
    _userStore = uStore;
  }

  /**
   *
   */
  Future<model.IvrMenu> createsIvrMenu() async {
    final menu = await ivrStore.create(Randomizer.randomIvrMenu(), user);

    return ivrStore.get(menu.name);
  }

  /**
   *
   */
  Future<model.IvrMenu> updatesIvrMenu(model.IvrMenu menu) async {
    final updated = await ivrStore.update(
        Randomizer.randomIvrMenu()..name = menu.name, user);

    return ivrStore.get(updated.name);
  }

  /**
   *
   */
  Future deletesIvrMenu(model.IvrMenu menu) async {
    await ivrStore.remove(menu.name, user);
  }

  storage.User get userStore {
    if (_userStore == null) {
      _userStore = env.userStore;
    }

    return _userStore;
  }

  /**
   *
   */
  storage.Ivr _ivrStore;
  void set ivrStore(storage.Ivr ivrs) {
    _ivrStore = ivrs;
  }

  storage.Ivr get ivrStore {
    if (_ivrStore == null) {
      _ivrStore = env.ivrStore;
    }

    return _ivrStore;
  }

  /**
   *
   */
  storage.ReceptionDialplan _dialplanStore;
  void set dialplanStore(storage.ReceptionDialplan dps) {
    _dialplanStore = dps;
  }

  storage.ReceptionDialplan get dialplanStore {
    if (_dialplanStore == null) {
      _dialplanStore = env.dialplanStore;
    }

    return _dialplanStore;
  }

  /**
   *
   */
  storage.Calendar _calendarStore;
  storage.Calendar get calendarStore => _calendarStore;
  void set calendarStore(storage.Calendar cs) {
    _calendarStore = cs;
  }

  /**
   *
   */
  storage.Contact _contactStore;

  void set contactStore(storage.Contact cStore) {
    _contactStore = cStore;
  }

  storage.Contact get contactStore {
    if (_contactStore == null) {
      _contactStore = env.contactStore;
    }

    return _contactStore;
  }

  /**
   *
   */
  storage.Message _messageStore;

  void set messageStore(storage.Message mStore) {
    _messageStore = mStore;
  }

  storage.Message get messageStore {
    if (_messageStore == null) {
      _messageStore = env.messageStore;
    }

    return _messageStore;
  }

  /**
   *
   */
  storage.MessageQueue _messageQueue;
  void set messageQueue(storage.MessageQueue mq) {
    _messageQueue = mq;
  }

  storage.MessageQueue get messageQueue {
    if (_messageQueue == null) {
      _messageQueue = env.messageQueue;
    }

    return _messageQueue;
  }

  /**
   *
   */
  storage.Reception _receptionStore;

  void set receptionStore(storage.Reception rStore) {
    _receptionStore = rStore;
  }

  storage.Reception get receptionStore {
    if (_receptionStore == null) {
      _receptionStore = env.receptionStore;
    }

    return _receptionStore;
  }

  /**
   *
   */
  storage.Organization _organizationStore;

  void set organizationStore(storage.Organization oStore) {
    _organizationStore = oStore;
  }

  storage.Organization get organizationStore {
    if (_organizationStore == null) {
      _organizationStore = env.organizationStore;
    }

    return _organizationStore;
  }

  Service.PeerAccount paService;
  Service.RESTDialplanStore dialplanService;

  /**
   *
   */
  ServiceAgent(this.runpath, this.user, this.env) {}

  /**
   *
   */
  Future<Customer> spawnCustomer() async {
    final authProcess = await env.requestAuthserverProcess();

    /// Ensure that the token is available in on the auth server.
    authProcess.addTokens([authToken]);
    if (paService == null) {
      paService = (await env.requestDialplanProcess())
          .bindPeerAccountClient(env.httpClient, authToken);
    }

    if (dialplanService == null) {
      dialplanService = (await env.requestDialplanProcess())
          .bindDialplanClient(env.httpClient, authToken);
    }

    final model.PeerAccount account =
        model.PeerAccount(_nextExternalPeerName, '', 'public');

    _log.fine('Deploying account ${account.toJson()}');
    await paService.deployAccount(account, user.id);
    _log.fine('Reloading config');
    await dialplanService.reloadConfig();

    Phonio.SIPAccount sipAccount = Phonio.SIPAccount(
        account.username, account.password, env.envConfig.externalIp);

    Phonio.SIPPhone sipPhone = await env.phonePool.requestNext();
    sipPhone.addAccount(sipAccount);

    final Customer c = Customer(sipPhone);

    await c.initialize();
    env.allocatedCustomers.add(c);
    return c;
  }

  /**
   *
   */
  Future<Receptionist> createsReceptionist() async {
    final authProcess = await env.requestAuthserverProcess();
    final callflowProcess = await env.requestCallFlowProcess();
    final notificationProcess = await env.requestNotificationserverProcess();

    callflow = callflowProcess.bindClient(env.httpClient, authToken);

    paService = (await env.requestDialplanProcess())
        .bindPeerAccountClient(env.httpClient, authToken);

    dialplanService = (await env.requestDialplanProcess())
        .bindDialplanClient(env.httpClient, authToken);

    /// Ensure that the token is available in on the auth server.
    await authProcess.addTokens([authToken]);

    final rUser = Randomizer.randomUser()
      ..extension = _nextInternalPeerName
      ..groups = Set<String>.from([model.UserGroups.receptionist]);
    await userStore.create(rUser, user);

    final AuthToken userToken = AuthToken(rUser);
    _log.finest('Deploying receptionist token to ${authProcess.uri}');
    await authProcess.addTokens([userToken]);

    final model.PeerAccount account = model.PeerAccount(
        rUser.extension, rUser.name.hashCode.toString(), 'receptions');

    _log.fine('Deploying account ${account.toJson()}');
    await paService.deployAccount(account, user.id);

    _log.fine('Reloading config');
    await dialplanService.reloadConfig();

    Phonio.SIPAccount sipAccount = Phonio.SIPAccount(
        account.username, account.password, env.envConfig.externalIp);

    Phonio.SIPPhone sipPhone = await env.phonePool.requestNext();
    sipPhone.addAccount(sipAccount);
    final Receptionist r = Receptionist(sipPhone, userToken.tokenName, rUser);

    final reloadEvent = (await notificationSocket)
        .onEvent
        .firstWhere((e) => e is event.CallStateReload);

    _log.finest('Reloading callflow state');
    await callflow.stateReload();
    _log.finest('Awaiting reload event');
    await reloadEvent;

    env.allocatedReceptionists.add(r);
    final registerEvent = (await notificationSocket).onEvent.firstWhere((e) =>
        e is event.PeerState &&
        e.peer.name == r.user.extension &&
        e.peer.registered);

    await r.initialize(callflowProcess.uri, notificationProcess.notifyUri);

    await registerEvent;

    return r;
  }

  /**
   *
   */
  Future removesUser(model.User target) async {
    await userStore.remove(target.id, user);
  }

  /**
   *
   */
  Future<model.BaseContact> createsContact({model.BaseContact contact}) async {
    final newContact =
        contact != null ? contact : Randomizer.randomBaseContact();

    final bc = await contactStore.create(newContact, user);

    return contactStore.get(bc.id);
  }

  /**
   * Creates a dialplan with opening hours right now  (based on
   * current time and until one hour in the future). If [mustBeValid] flag
   * is set, then a FreeSWITCH process is spawned in order to aquire the
   * current sound directory path. If all that is needed is a mock dialplan
   * object, then set [mustBeValid] to false. If the dialplan needs to be
   * dialable, then set [mustBeValid] to true.
   */
  Future<model.ReceptionDialplan> createsDialplan({mustBeValid: true}) async {
    final DateTime now = DateTime.now();

    model.OpeningHour justNow = model.OpeningHour.empty()
      ..fromDay = model.toWeekDay(now.weekday)
      ..toDay = model.toWeekDay(now.weekday)
      ..fromHour = now.hour
      ..toHour = now.hour + 1
      ..fromMinute = now.minute
      ..toMinute = now.minute;

    model.ReceptionDialplan rdp = model.ReceptionDialplan()
      ..open = [
        model.HourAction()
          ..hours = [justNow]
          ..actions = [
            model.Notify('call-offer'),
            model.Ringtone(1),
            mustBeValid
                ? model.Playback(
                    (await env.requestFreeswitchProcess()).soundsPath +
                        '/test.wav')
                : model.Playback('non-existing-file.wav'),
            model.Enqueue('waitqueue')
          ]
      ]
      ..extension = 'test-${Randomizer.randomPhoneNumber()}'
          '-${DateTime.now().millisecondsSinceEpoch}'
      ..defaultActions = [model.Playback('sorry-dude-were-closed')];

    _log.fine('Creating dialplan ${rdp.toJson()}');
    await dialplanStore.create(rdp, user);

    return rdp;
  }

  /**
   *
   */
  Future<model.ReceptionDialplan> updatesDialplan(model.ReceptionDialplan rdp,
      {mustBeValid: true}) async {
    final DateTime now = DateTime.now();

    model.OpeningHour justNow = model.OpeningHour.empty()
      ..fromDay = model.toWeekDay(now.weekday)
      ..toDay = model.toWeekDay(now.weekday)
      ..fromHour = now.hour
      ..toHour = now.hour + 2
      ..fromMinute = now.minute
      ..toMinute = now.minute;

    rdp = model.ReceptionDialplan()
      ..open = [
        model.HourAction()
          ..hours = [justNow]
          ..actions = [
            model.Notify('call-offer'),
            model.Ringtone(1),
            mustBeValid
                ? model.Playback(
                    (await env.requestFreeswitchProcess()).soundsPath +
                        '/test.wav')
                : model.Playback('non-existing-file.wav'),
            model.Enqueue('waitqueue')
          ]
      ]
      ..note = rdp.note + ' (updated)'
      ..extension = rdp.extension
      ..defaultActions = [model.Playback('sorry-dude-were-closed')];

    _log.info('Updating dialplan ${rdp.toJson()}');
    await dialplanStore.update(rdp, user);

    return rdp;
  }

  /**
   *
   */
  Future removesDialplan(model.ReceptionDialplan rdp) async {
    await dialplanStore.remove(rdp.extension, user);
  }

  /**
   *
   */
  Future deploysDialplan(
      model.ReceptionDialplan rdp, model.Reception rec) async {
    if (dialplanService == null) {
      dialplanService = (await env.requestDialplanProcess())
          .bindDialplanClient(env.httpClient, authToken);
    }

    await dialplanService.deployDialplan(rdp.extension, rec.id);
    await dialplanService.reloadConfig();
  }

  /**
   *
   */
  Future<model.BaseContact> updatesContact(model.BaseContact contact) async {
    final updatedContact = Randomizer.randomBaseContact()..id = contact.id;
    updatedContact.name = updatedContact.name + ' (updated)';

    await contactStore.update(updatedContact, user);

    return contactStore.get(updatedContact.id);
  }

  /**
   *
   */
  Future removesContact(model.BaseContact contact) async {
    await contactStore.remove(contact.id, user);
  }

  /**
   *
   */
  Future<model.ReceptionAttributes> addsContactToReception(
      model.BaseContact contact, model.Reception rec) async {
    final attributes = Randomizer.randomAttributes();
    attributes
      ..cid = contact.id
      ..receptionId = rec.id;

    await contactStore.addData(attributes, user);
    return contactStore.data(contact.id, rec.id);
  }

  /**
   *
   */
  Future<model.ReceptionAttributes> updatesReceptionAttributes(
      model.ReceptionAttributes attr) async {
    final attributes = Randomizer.randomAttributes()
      ..cid = attr.cid
      ..receptionId = attr.receptionId;

    await contactStore.updateData(attributes, user);

    return attributes;
  }

  /**
   *
   */
  Future removesContactFromReception(
      model.BaseContact contact, model.Reception reception) async {
    await contactStore.removeData(contact.id, reception.id, user);
  }

  /**
   *
   */
  Future<model.Reception> createsReception(model.Organization org,
      [model.Reception rec]) async {
    final randRec = (rec != null ? rec : Randomizer.randomReception())
      ..oid = org.id;
    final bc = await receptionStore.create(randRec, user);

    return receptionStore.get(bc.id);
  }

  /**
   *
   */
  Future<model.Reception> updatesReception(model.Reception rec) async {
    final randRec = Randomizer.randomReception()
      ..oid = rec.oid
      ..id = rec.id;

    final bc = await receptionStore.update(randRec, user);

    return receptionStore.get(bc.id);
  }

  /**
   *
   */
  Future removesReception(model.Reception rec) async {
    await receptionStore.remove(rec.id, user);
  }

  /**
   *
   */
  Future<model.Reception> updateReception(model.Reception rec) async {
    final ref = await receptionStore.update(rec, user);

    return receptionStore.get(ref.id);
  }

  /**
   *
   */
  Future<model.Organization> createsOrganization() async {
    final randOrg = Randomizer.randomOrganization();
    final ref = await organizationStore.create(randOrg, user);

    return organizationStore.get(ref.id);
  }

  /**
   *
   */
  Future deletesOrganization(model.Organization org) async {
    await organizationStore.remove(org.id, user);
  }

  /**
   *
   */
  Future<model.Organization> updatesOrganization(model.Organization org) async {
    final randOrg = Randomizer.randomOrganization()..id = org.id;
    final ref = await organizationStore.update(randOrg, user);

    return organizationStore.get(ref.id);
  }

  /**
   *
   */
  Future<model.User> createsUser([model.User u]) async {
    final model.User newUser = (u == null) ? Randomizer.randomUser() : u;

    newUser.id = (await userStore.create(newUser, user)).id;

    return newUser;
  }

  /**
   *
   */
  Future<model.User> updatesUser(model.User u) async {
    final model.User updated = Randomizer.randomUser()..id = u.id;
    final uRef = await userStore.update(updated, user);

    return userStore.get(uRef.id);
  }

  /**
   *
   */
  Future<model.Message> createsMessage(model.MessageContext context,
      {model.Message msg}) async {
    msg = msg == null ? Randomizer.randomMessage() : msg;

    model.ReceptionAttributes contact =
        await contactStore.data(context.cid, context.rid);

    msg
      ..context = context
      ..recipients = contact.endpoints.toSet()
      ..sender = user;

    return messageStore.create(msg, user);
  }

  /**
   *
   */
  Future<model.Message> updatesMessage(model.Message msg) async {
    msg = Randomizer.randomMessage()
      ..id = msg.id
      ..context = msg.context
      ..recipients = msg.recipients
      ..sender = msg.sender;

    return messageStore.update(msg, user);
  }

  /**
   *
   */
  Future<model.Message> removesMessage(model.Message msg) async {
    await messageStore.remove(msg.id, user);

    return msg;
  }
}
