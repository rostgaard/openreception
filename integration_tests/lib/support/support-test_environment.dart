part of ort.support;

int _currentInternalPeerName = 1100;
String get _nextInternalPeerName {
  String peername = _currentInternalPeerName.toString();
  _currentInternalPeerName++;
  return peername;
}

int _currentExternalPeerName = 1200;
String get _nextExternalPeerName {
  String peername = _currentExternalPeerName.toString();
  _currentExternalPeerName++;
  return peername;
}

process.FreeSwitch _freeswitch;

class TestEnvironmentConfig {
  String externalIp;
  or_conf.EslConfig eslConf;

  Future load() async {
    final nics = await NetworkInterface.list();
    externalIp = nics.first.addresses.first.address;

    eslConf = or_conf.EslConfig(
        hostname: config.eslHost,
        password: config.eslPassword,
        port: config.eslPort);
  }

  String toString() => '''
Test environment:
  External IP: $externalIp
  EslConfig: ${eslConf.toDsn()}''';
}

TestEnvironmentConfig _envConfig = TestEnvironmentConfig();

class CircularCounter {
  final int _start;
  int _count;
  final int _max;

  int get nextInt {
    final int count = _count;

    if (_count == _max) {
      _count = _start;
    } else {
      _count = _count + 1;
    }

    return count;
  }

  CircularCounter(this._start, this._max) {
    _count = _start;
  }
}

CircularCounter _networkPortCounter = CircularCounter(9000, 11000);

class TestEnvironment {
  Logger _log = Logger('TestEnvironment');
  model.User _user = model.User()
    ..id = 0
    ..name = 'System User'
    ..address = 'openreception@localhost';

  TestEnvironmentConfig get envConfig => _envConfig;
  final PhonePool phonePool = PhonePool.empty(_networkPortCounter);
  final Directory runpath;
  bool _isTmpDir = true;

  final bool enableRevisions;

  /// Processes
  process.AuthServer _authProcess;
  process.CalendarServer _calendarServer;
  process.CallFlowControl _callflowProcess;
  process.ContactServer _contactServer;
  process.DialplanServer _dialplanProcess;
  process.ConfigServer _configProcess;
  process.CdrServer _cdrProcess;
  process.MessageDispatcher _messageDispatcher;
  process.MessageServer _messageProcess;
  process.NotificationServer _notificationProcess;
  process.ReceptionServer _receptionServer;
  process.UserServer _userServer;

  service.Client _httpClient;

  List<service.WebSocketClient> _allocatedWebSockets = [];

  /**
   *
   */
  service.Client get httpClient =>
      _httpClient != null ? _httpClient : service.Client();

  int get nextNetworkport => _networkPortCounter.nextInt;

  List<Receptionist> allocatedReceptionists = [];
  List<Customer> allocatedCustomers = [];

  /**
   *
   */
  Future<process.FreeSwitch> requestFreeswitchProcess() async {
    if (_freeswitch == null) {
      _freeswitch = process.FreeSwitch(
          '/usr/local/freeswitch/bin/freeswitch',
          Directory('/tmp').createTempSync('freeswitch-').path,
          Directory('conf'),
          Directory('sounds'));
    }
    await _freeswitch.whenReady;
    return _freeswitch;
  }

  /**
   *
   */
  service.WebSocketClient requestWebsocket() {
    final ws = service.WebSocketClient();
    _allocatedWebSockets.add(ws);

    return ws;
  }

  /**
   *
   */
  Future<process.ConfigServer> requestConfigServerProcess() async {
    if (_configProcess == null) {
      _configProcess = process.ConfigServer(config.serverStackPath,
          bindAddress: envConfig.externalIp, servicePort: nextNetworkport);
    }

    await _configProcess.whenReady;

    return _configProcess;
  }

  /// Spawn a CDR server process within the current evironment.
  Future<process.CdrServer> requestCdrServerProcess() async {
    if (_cdrProcess == null) {
      _cdrProcess = process.CdrServer(config.serverStackPath,
          bindAddress: envConfig.externalIp,
          servicePort: nextNetworkport,
          authUri: (await requestAuthserverProcess()).uri);
    }

    await _cdrProcess.whenReady;

    return _cdrProcess;
  }

  /**
   *
   */
  Future<process.ContactServer> requestContactserverProcess(
      {bool withRevisioning: false}) async {
    if (_contactServer == null) {
      _contactServer = process.ContactServer(
          config.serverStackPath, runpath.path,
          bindAddress: envConfig.externalIp,
          servicePort: nextNetworkport,
          authUri: (await requestAuthserverProcess()).uri,
          notificationUri: (await requestNotificationserverProcess()).uri,
          enableRevisioning: withRevisioning);
    }

    await _contactServer.whenReady;

    return _contactServer;
  }

  /**
   *
   */
  Future<process.MessageDispatcher> requestMessagedispatcherProcess(
      {bool withRevisioning: false}) async {
    if (_messageDispatcher == null) {
      _messageDispatcher = process.MessageDispatcher(
          config.serverStackPath, runpath.path,
          bindAddress: envConfig.externalIp,
          servicePort: nextNetworkport,
          authUri: (await requestAuthserverProcess()).uri,
          notificationUri: (await requestNotificationserverProcess()).uri);
    }

    await _messageDispatcher.whenReady;

    return _messageDispatcher;
  }

  /**
   *
   */
  Future<process.MessageServer> requestMessageserverProcess(
      {bool withRevisioning: false}) async {
    if (_messageProcess == null) {
      _messageProcess = process.MessageServer(
          config.serverStackPath, runpath.path,
          bindAddress: envConfig.externalIp,
          servicePort: nextNetworkport,
          enableRevisioning: withRevisioning,
          authUri: (await requestAuthserverProcess()).uri,
          notificationUri: (await requestNotificationserverProcess()).uri);
    }

    await _messageProcess.whenReady;

    return _messageProcess;
  }

  /**
   *
   */
  Future<process.CalendarServer> requestCalendarserverProcess(
      {bool withRevisioning: false}) async {
    if (_calendarServer == null) {
      _calendarServer = process.CalendarServer(
          config.serverStackPath, runpath.path,
          bindAddress: envConfig.externalIp,
          servicePort: nextNetworkport,
          authUri: (await requestAuthserverProcess()).uri,
          notificationUri: (await requestNotificationserverProcess()).uri,
          enableRevisioning: withRevisioning);
    }

    await _calendarServer.whenReady;

    return _calendarServer;
  }

  /**
   *
   */
  Future<process.AuthServer> requestAuthserverProcess() async {
    if (_authProcess == null) {
      _authProcess = process.AuthServer(config.serverStackPath, runpath.path,
          initialTokens: [AuthToken(_user)]..addAll(await userTokens),
          bindAddress: envConfig.externalIp,
          servicePort: nextNetworkport);
    }

    await _authProcess.whenReady;

    return _authProcess;
  }

  /**
   *
   */
  Future<process.DialplanServer> requestDialplanProcess(
      {bool withRevisioning: false}) async {
    if (_dialplanProcess == null) {
      _dialplanProcess = process.DialplanServer(config.serverStackPath,
          runpath.path, (await requestFreeswitchProcess()).confPath,
          authUri: (await requestAuthserverProcess()).uri,
          bindAddress: envConfig.externalIp,
          servicePort: nextNetworkport,
          eslHostname: envConfig.eslConf.hostname,
          eslPassword: envConfig.eslConf.password,
          eslPort: envConfig.eslConf.port,
          enableRevisioning: withRevisioning);
    }

    await _dialplanProcess.whenReady;

    return _dialplanProcess;
  }

  /**
   *
   */
  Future<process.CallFlowControl> requestCallFlowProcess() async {
    if (_callflowProcess == null) {
      _callflowProcess = process.CallFlowControl(
          config.serverStackPath, runpath.path,
          bindAddress: envConfig.externalIp,
          servicePort: nextNetworkport,
          notificationUri: (await requestNotificationserverProcess()).uri,
          authUri: (await requestAuthserverProcess()).uri,
          eslHostname: envConfig.eslConf.hostname,
          eslPassword: envConfig.eslConf.password,
          eslPort: envConfig.eslConf.port);
    }

    await _callflowProcess.whenReady;

    return _callflowProcess;
  }

  /**
   *
   */
  Future<process.NotificationServer> requestNotificationserverProcess() async {
    if (_notificationProcess == null) {
      _notificationProcess = process.NotificationServer(
          config.serverStackPath, runpath.path,
          bindAddress: envConfig.externalIp,
          servicePort: nextNetworkport,
          authUri: (await requestAuthserverProcess()).uri);
    }

    await _notificationProcess.whenReady;

    return _notificationProcess;
  }

  /**
   *
   */
  Future<process.ReceptionServer> requestReceptionserverProcess(
      {bool withRevisioning: false}) async {
    if (_receptionServer == null) {
      _receptionServer = process.ReceptionServer(
          config.serverStackPath, runpath.path,
          bindAddress: envConfig.externalIp,
          servicePort: nextNetworkport,
          authUri: (await requestAuthserverProcess()).uri,
          notificationUri: (await requestNotificationserverProcess()).uri,
          enableRevisioning: withRevisioning);
    }

    await _receptionServer.whenReady;

    return _receptionServer;
  }

  /**
   *
   */
  Future<process.UserServer> requestUserserverProcess(
      {bool withRevisioning: false}) async {
    if (_userServer == null) {
      _userServer = process.UserServer(config.serverStackPath, runpath.path,
          bindAddress: envConfig.externalIp,
          servicePort: nextNetworkport,
          authUri: (await requestAuthserverProcess()).uri,
          notificationUri: (await requestNotificationserverProcess()).uri,
          enableRevisioning: withRevisioning);
    }

    await _userServer.whenReady;

    return _userServer;
  }

  /**
   *
   */
  filestore.User _userStore;
  filestore.User get userStore {
    if (_userStore == null) {
      final String path = '${runpath.path}/user';
      _log.fine('Creating user store from $path');
      _userStore = filestore.User(path,
          enableRevisions ? filestore.GitEngine(path, logStdout: true) : null);
    }

    return _userStore;
  }

  /**
   *
   */
  filestore.Ivr _ivrStore;
  filestore.Ivr get ivrStore {
    if (_ivrStore == null) {
      final String path = '${runpath.path}/ivr';
      _log.fine('Creating ivr store from $path');
      _ivrStore = filestore.Ivr(path,
          enableRevisions ? filestore.GitEngine(path, logStdout: true) : null);
    }

    return _ivrStore;
  }

  /**
   *
   */
  filestore.ReceptionDialplan _dpStore;
  filestore.ReceptionDialplan get dialplanStore {
    if (_dpStore == null) {
      final String path = '${runpath.path}/dialplan';
      _log.fine('Creating dialplan store from $path');

      _dpStore = filestore.ReceptionDialplan(path,
          enableRevisions ? filestore.GitEngine(path, logStdout: true) : null);
    }

    return _dpStore;
  }

  /**
   *
   */
  filestore.Contact _contactStore;
  filestore.Contact get contactStore {
    if (_contactStore == null) {
      final String path = '${runpath.path}/contact';
      _log.fine('Creating calendar store from $path');

      _contactStore = filestore.Contact(receptionStore, path,
          enableRevisions ? filestore.GitEngine(path, logStdout: true) : null);
    }

    return _contactStore;
  }

  /**
   *
   */
  filestore.Message _messageStore;
  filestore.Message get messageStore {
    if (_messageStore == null) {
      final String path = '${runpath.path}/message';
      _log.fine('Creating message store from $path');

      _messageStore = filestore.Message(path,
          enableRevisions ? filestore.GitEngine(path, logStdout: true) : null);
    }

    return _messageStore;
  }

  /**
   *
   */
  filestore.MessageQueue _messageQueue;
  filestore.MessageQueue get messageQueue {
    if (_messageQueue == null) {
      final String path = '${runpath.path}/message_queue';
      _log.fine('Creating message queue store from $path');

      _messageQueue = filestore.MessageQueue(path);
    }

    return _messageQueue;
  }

  /**
   *
   */
  filestore.Reception _receptionStore;
  filestore.Reception get receptionStore {
    if (_receptionStore == null) {
      final String path = '${runpath.path}/reception';
      _log.fine('Creating reception store from $path');

      _receptionStore = filestore.Reception(path,
          enableRevisions ? filestore.GitEngine(path, logStdout: true) : null);
    }

    return _receptionStore;
  }

  /**
   *
   */
  filestore.Organization _organizationStore;
  filestore.Organization get organizationStore {
    if (_organizationStore == null) {
      final String path = '${runpath.path}/organization';
      _log.fine('Creating organization store from $path');

      _organizationStore = filestore.Organization(
          contactStore,
          receptionStore,
          path,
          enableRevisions ? filestore.GitEngine(path, logStdout: true) : null);
    }

    return _organizationStore;
  }

  /**
   *
   */
  TestEnvironment({String path: '', this.enableRevisions: false})
      : runpath = path.isEmpty
            ? Directory.systemTemp.createTempSync('filestore-')
            : Directory(path) {
    _isTmpDir = path.isEmpty;
    _log.fine('New test environment created in directory $runpath');
  }

  /**
   *
   */
  Future _clearWebsockets() async {
    await Future.forEach(_allocatedWebSockets,
        (service.WebSocketClient ws) async {
      try {
        await ws.close();
      } catch (e, s) {
        _log.warning('Failed to close websocket', e, s);
      }
    });
  }

  /**
   *
   */
  Future clear() async {
    await _clearProcesses();
    await _clearWebsockets();

    if (_httpClient != null) {
      _httpClient.client.close(force: true);
    }

    if (runpath.existsSync() && _isTmpDir) {
      _log.fine('Clearing test environment created in directory $runpath');
      runpath.deleteSync(recursive: true);
    }

    _userStore = null;
    _dpStore = null;
    _userStore = null;
    _contactStore = null;
    _messageStore = null;
    _messageQueue = null;
    _receptionStore = null;
    _organizationStore = null;

    if (_freeswitch != null) {
      await _freeswitch.cleanConfig();
      _freeswitch.reRollLog();
    }
  }

/**
 *
 */
  Future _clearProcesses() async {
    await Future.wait(allocatedReceptionists.map((r) => r.finalize()));
    allocatedReceptionists = [];
    await Future.wait(allocatedCustomers.map((r) => r.finalize()));
    allocatedCustomers = [];

    if (_callflowProcess != null) {
      _log.fine('Shutting down callflow process $_callflowProcess');
      await _callflowProcess.terminate();
      _callflowProcess = null;
    }

    if (_dialplanProcess != null) {
      _log.fine('Shutting down dialplan server process $_dialplanProcess');
      await _dialplanProcess.terminate();
      _dialplanProcess = null;
    }

    if (_contactServer != null) {
      _log.fine('Shutting down contact server process $_contactServer');
      await _contactServer.terminate();
      _contactServer = null;
    }

    if (_calendarServer != null) {
      _log.fine('Shutting down calendar server process $_calendarServer');
      await _calendarServer.terminate();
      _calendarServer = null;
    }

    if (_receptionServer != null) {
      _log.fine('Shutting down reception server process $_receptionServer');
      await _receptionServer.terminate();
      _receptionServer = null;
    }

    if (_messageProcess != null) {
      _log.fine('Shutting down message server process $_messageProcess');
      await _messageProcess.terminate();
      _messageProcess = null;
    }
    if (_messageDispatcher != null) {
      _log.fine('Shutting down message dispatcher process $_messageDispatcher');
      await _messageDispatcher.terminate();
      _messageDispatcher = null;
    }

    if (_configProcess != null) {
      _log.fine('Shutting down config server process $_configProcess');
      await _configProcess.terminate();
      _configProcess = null;
    }

    if (_userServer != null) {
      _log.fine('Shutting down user server process $_userServer');
      await _userServer.terminate();
      _userServer = null;
    }

    if (_notificationProcess != null) {
      _log.fine(
          'Shutting down notification server process $_notificationProcess');
      await _notificationProcess.terminate();
      _notificationProcess = null;
    }

    if (_authProcess != null) {
      _log.fine('Shutting down authentication server process $_authProcess');
      await _authProcess.terminate();
      _authProcess = null;
    }

    if (_cdrProcess != null) {
      _log.fine('Shutting down cdr server process $_cdrProcess');
      await _cdrProcess.terminate();
      _cdrProcess = null;
    }
  }

  /**
   *
   */
  Future finalize() async {
    await clear();
    if (_freeswitch != null) {
      _log.fine('Terminating FreeSWITCH');
      await _freeswitch.terminate();
      _log.fine('Deleting directory ${_freeswitch.basePath}');
      await Directory(_freeswitch.basePath).deleteSync(recursive: true);
    }

    await Future.forEach(process.launchedProcesses, (Process p) async {
      if (p.kill()) {
        _log.warning('Killing orphan process pid: ${p.pid}');

        await p.exitCode;
      }
    });

    if (_httpClient != null) {
      _log.fine('Terminating HttpClient');
      await _httpClient.client.close(force: true);
    }
  }

  /**
   *
   */
  Future<ServiceAgent> createsServiceAgent([model.User user]) async {
    await userStore.ready;
    model.User sa = (user == null ? Randomizer.randomUser() : user)
      ..groups = [model.UserGroups.serviceAgent];

    if (user == null) {
      sa.id = (await _userStore.create(sa, _user)).id;
    }

    return ServiceAgent(runpath, sa, this);
  }

  /**
   *
   */
  Future<Iterable<AuthToken>> get userTokens async {
    final uRefs = await userStore.list();

    return Future.wait(
        uRefs.map((uRef) async => AuthToken(await userStore.get(uRef.id))));
  }

  /**
   *
   */
  Future removesServiceAgent(model.User serviceAgent) async {
    await _userStore.ready;
    await _userStore.remove(serviceAgent.id, _user);
  }
}
