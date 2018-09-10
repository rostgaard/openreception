part of ort.process;

class CalendarServer implements ServiceProcess {
  final Logger _log = Logger('$_namespace.CalendarServer');
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

  /**
   *
   */
  CalendarServer(this.path, this.storePath,
      {this.servicePort: 4060,
      this.bindAddress: '0.0.0.0',
      this.authUri: null,
      this.notificationUri,
      this.enableRevisioning: false}) {
    _init();
  }

  /**
   *
   */
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
      processName = '${config.buildPath}/calendarserver';
    } else {
      processName = config.dartPath;
      arguments.add('${config.serverStackPath}/bin/calendarserver.dart');
    }

    arguments.addAll([
      '--filestore',
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

    _log.finest('Started calendarserver process (pid: ${_process.pid})');
    _launchedProcesses.add(_process);

    /// Protect from hangs caused by process crashes.
    _process.exitCode.then((int exitCode) {
      if (exitCode != 0 && !ready) {
        _ready.completeError(StateError('Failed to launch process. '
            'Exit code: $exitCode'));
      }
    });
  }

  /**
   * Constructs a [service.RESTCalendarStore] based on the launch
   * parameters of the process.
   */
  service.RESTCalendarStore bindClient(service.Client client, AuthToken token,
      {Uri connectUri: null}) {
    if (connectUri == null) {
      connectUri = this.uri;
    }

    return service.RESTCalendarStore(connectUri, token.tokenName, client);
  }

  /**
   *
   */
  Uri get uri => Uri.parse('http://$bindAddress:$servicePort');

  /**
   *
   */
  Future terminate() async {
    _process.kill();
    await _process.exitCode;
  }

  String toString() => '$runtimeType,pid:${_process.pid}:uri$uri';
}
