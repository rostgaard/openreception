part of ort.process;

class CallFlowControl implements ServiceProcess {
  final Logger _log = Logger('$_namespace.CallFlowControl');
  Process _process;

  final String path;
  final String storePath;
  final int servicePort;
  final String bindAddress;
  final Uri authUri;
  final Uri notificationUri;
  final String eslHostname;
  final String eslPassword;
  final int eslPort;

  final Completer _ready = Completer();
  bool get ready => _ready.isCompleted;
  Future get whenReady => _ready.future;

  /**
   *
   */
  CallFlowControl(this.path, this.storePath,
      {this.servicePort: 4242,
      this.bindAddress: '0.0.0.0',
      this.authUri: null,
      this.notificationUri: null,
      this.eslHostname: null,
      this.eslPort: null,
      this.eslPassword: null}) {
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
      processName = '${config.buildPath}/callflowcontrol';
    } else {
      processName = config.dartPath;
      arguments.add('${config.serverStackPath}/bin/callflowcontrol.dart');
    }

    arguments.addAll([      '--httpport',
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

    if (eslHostname != null) {
      arguments.addAll(['--esl-hostname', eslHostname.toString()]);
    }

    if (eslPassword != null) {
      arguments.addAll(['--esl-password', eslPassword.toString()]);
    }

    if (eslPort != null) {
      arguments.addAll(['--esl-port', eslPort.toString()]);
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

    _log.finest('Started callflowcontrol process (pid: ${_process.pid})');
    _launchedProcesses.add(_process);

    /// Protect from hangs caused by process crashes.
    _process.exitCode.then((int exitCode) {
      if (exitCode != 0 && !ready) {
        _ready.completeError(StateError('Failed to launch process. '
            'Exit code: $exitCode'));
      }
    });
  }

  /// Constructs a [service.CallFlowControl] based on the launch
  /// parameters of the process.
  service.CallFlowControl bindClient(service.Client client, AuthToken token,
      {Uri connectUri: null}) {
    if (connectUri == null) {
      connectUri = this.uri;
    }

    return service.CallFlowControl(connectUri, token.tokenName, client);
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
