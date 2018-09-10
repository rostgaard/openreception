part of ort.process;

class ReceptionServer implements ServiceProcess {
  final Logger _log = Logger('$_namespace.ReceptionServer');
  Process _process;

  final String path;
  final String storePath;
  final int servicePort;
  final String bindAddress;
  final Uri authUri;
  final Uri notificationUri;
  final bool enableRevisioning;

  final Completer _ready = Completer();
  bool get ready => _ready.isCompleted;
  Future get whenReady => _ready.future;

  ReceptionServer(this.path, this.storePath,
      {this.servicePort: 4000,
      this.bindAddress: '0.0.0.0',
      this.authUri: null,
      this.notificationUri,
      this.enableRevisioning: false}) {
    _init();
  }

  Future _init() async {
    final Stopwatch initTimer = Stopwatch()..start();
    whenReady.whenComplete(() {
      initTimer.stop();
      _log.info('Process initialization time was: '
          '${initTimer.elapsedMilliseconds}ms');
    });

    String processName;
    final arguments = <String>[];
    if (config.runNative) {
      processName = '${config.buildPath}/receptionserver';
    } else {
      processName = config.dartPath;
      arguments.add('${config.serverStackPath}/bin/receptionserver.dart');
    }

    arguments.addAll([      '--filestore',
      storePath,
      '--httpport',
      servicePort.toString(),
      '--host',
      bindAddress
    ]);

    if (authUri != null) {
      arguments.addAll(['--auth-uri', authUri.toString()]);
    }

    if (notificationUri != null) {
      arguments.addAll(['--notification-uri', notificationUri.toString()]);
    }

    if (enableRevisioning) {
      arguments.add('--experimental-revisioning');
    } else {
      arguments.add('--no-experimental-revisioning');
    }

    _log.fine('Starting process $processName ${arguments.join(' ')}');
    _process = await Process.start(processName, arguments,
        workingDirectory: path)
      ..stdout
          .transform(Utf8Decoder())
          .transform(LineSplitter())
          .listen((String line) {
        _log.finest(line);
        if (!ready && line.contains('Ready to handle requests')) {
          _log.info('Ready');
          _ready.complete();
        }
      })
      ..stderr
          .transform(Utf8Decoder())
          .transform(LineSplitter())
          .listen(_log.warning);

    _log.finest('Started receptionserver process (pid: ${_process.pid})');
    _launchedProcesses.add(_process);

    /// Protect from hangs caused by process crashes.
    _process.exitCode.then((int exitCode) {
      if (exitCode != 0 && !ready) {
        _ready.completeError(StateError('Failed to launch process. '
            'Exit code: $exitCode'));
      }
    });
  }

  Future terminate() async {
    _process.kill();
    await _process.exitCode;
  }

  /**
   *
   */
  service.RESTReceptionStore bindClient(service.Client client, AuthToken token,
      {Uri connectUri: null}) {
    if (connectUri == null) {
      connectUri = uri;
    }

    return service.RESTReceptionStore(uri, token.tokenName, client);
  }

  /**
   *
   */
  Uri get uri => Uri.parse('http://$bindAddress:$servicePort');

  /**
   *
   */
  service.RESTOrganizationStore bindOrgClient(
      service.Client client, AuthToken token,
      {Uri uri: null}) {
    if (uri == null) {
      uri = Uri.parse('http://${bindAddress}:$servicePort');
    }

    return service.RESTOrganizationStore(uri, token.tokenName, client);
  }

  String toString() => '$runtimeType,pid:${_process.pid}:uri$uri';
}
