part of ort.process;

class DatastoreServer implements ServiceProcess {
  final Logger _log = Logger('$_namespace.DatastoreServer');
  Process _process;
  final String path;
  final String storePath;

  final int servicePort;
  final String bindAddress;
  final String fsConfPath;
  final Uri authUri;
  final Uri notificationUri;
  final bool enableRevisioning;
  final String playbackPrefix;
  final String eslHostname;
  final String eslPassword;
  final int eslPort;

  final Completer _ready = Completer();
  bool get ready => _ready.isCompleted;
  Future get whenReady => _ready.future;

  /**
   *
   */
  DatastoreServer(this.path, this.storePath, this.fsConfPath,
      {this.servicePort: 4090,
      this.bindAddress: '0.0.0.0',
      this.authUri: null,
      this.notificationUri,
      this.playbackPrefix: '',
      this.eslHostname: null,
      this.eslPort: null,
      this.eslPassword: null,
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

    final arguments = [
      '$path/bin/datastore.dart',
      '--filestore',
      storePath,
      '--port',
      servicePort.toString(),
      '--host',
      bindAddress,
      '--freeswitch-conf-path',
      fsConfPath,
      '--playback-prefix',
      playbackPrefix
    ];

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

    if (enableRevisioning) {
      arguments.add('--experimental-revisioning');
    } else {
      arguments.add('--no-experimental-revisioning');
    }

    _log.fine('Starting process /usr/local/bin/dart ${arguments.join(' ')}');
    _process = await Process.start('/usr/local/bin/dart', arguments,
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

    _log.finest('Started datastore process (pid: ${_process.pid})');
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
   * Constructs a [service.CallFlowControl] based on the launch
   * parametersof the process.
   */
  service.Datastore bindClient(service.Client client, AuthToken token,
      {Uri connectUri: null}) {
    if (connectUri == null) {
      connectUri = this.uri;
    }

    return service.Datastore(connectUri, token.tokenName, client);
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
