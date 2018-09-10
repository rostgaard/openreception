part of ort.process;

class AuthServer implements ServiceProcess {
  final String path;
  final String storePath;
  final int servicePort;
  final String bindAddress;
  AuthTokenDir tokenDir;

  final Logger _log = Logger('$_namespace.AuthServer');
  Process _process;

  Completer _ready = Completer();
  bool get ready => _ready.isCompleted;
  Future get whenReady => _ready.future;

  /**
   *
   */
  AuthServer(this.path, this.storePath,
      {Iterable<AuthToken> initialTokens: const [],
      this.servicePort: 4050,
      this.bindAddress: '0.0.0.0'}) {
    _init(initialTokens);
  }

  /**
   *
   */
  Future _init(Iterable<AuthToken> initialTokens) async {
    final Stopwatch initTimer = Stopwatch()..start();
    whenReady.whenComplete(() {
      initTimer.stop();
      _log.fine('Process initialization time was: '
          '${initTimer.elapsedMilliseconds}ms');
    });

    tokenDir = AuthTokenDir(Directory('/tmp').createTempSync(),
        intialTokens: initialTokens);

    String processName;
    final arguments = <String>[];
    if (config.runNative) {
      processName = '${config.buildPath}/authserver';
    } else {
      processName = config.dartPath;
      arguments.add('${config.serverStackPath}/bin/authserver.dart');
    }

    await _writeTokens();
    arguments.addAll([
      '-d',
      tokenDir.dir.absolute.path,
      '--filestore',
      storePath,
      '--httpport',
      servicePort.toString(),
      '--host',
      bindAddress
    ]);
    _log.fine('Starting process $processName ${arguments.join(' ')}');

    _process =
        await Process.start(processName, arguments, workingDirectory: path)
          ..stdout
              .transform(Utf8Decoder())
              .transform(LineSplitter())
              .listen((String line) {
            _log.finest(line);
            if ((!ready && line.contains('Ready to handle requests')) ||
                (!ready && line.contains('Reloaded tokens from disk'))) {
              _log.fine('Ready');
              _ready.complete();
            }
          })
          ..stderr
              .transform(Utf8Decoder())
              .transform(LineSplitter())
              .listen(_log.warning);

    _log.finest('Started authserver process (pid: ${_process.pid})');
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
   *
   */
  Future _writeTokens() async {
    _log.finest('Writing ${tokenDir.tokens.length} tokens '
        'to ${tokenDir.dir.path}');
    await tokenDir.writeTokens();
  }

  /**
   *
   */
  Future addTokens(Iterable<AuthToken> ts) async {
    await whenReady;
    _ready = Completer();

    try {
      tokenDir.tokens.addAll(ts);
      await _writeTokens();
      _process.kill(ProcessSignal.sighup);
    } catch (e, s) {
      _ready.completeError(e, s);
    }

    await whenReady.timeout(Duration(seconds: 10));
  }

  /**
   * Constructs a [service.Autentication] based on the launch parameters
   * of the process.
   */
  service.Authentication bindClient(service.Client client, AuthToken token,
      {Uri connectUri: null}) {
    if (connectUri == null) {
      connectUri = this.uri;
    }

    return service.Authentication(connectUri, token.tokenName, client);
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
