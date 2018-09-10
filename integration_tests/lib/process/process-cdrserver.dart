part of ort.process;

class CdrServer implements ServiceProcess {
  final Uri authUri;
  final String path;
  final int servicePort;
  final String bindAddress;

  final Logger _log = Logger('$_namespace.CdrServer');
  Process _process;

  final Completer _ready = Completer();
  bool get ready => _ready.isCompleted;
  Future get whenReady => _ready.future;

  /**
   *
   */
  CdrServer(
    this.path, {
    this.servicePort: 4090,
    this.bindAddress: '0.0.0.0',
    this.authUri: null,
  }) {
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
      '$path/bin/cdrserver.dart',
      '--port',
      servicePort.toString(),
      '--host',
      bindAddress
    ];

    if (authUri != null) {
      arguments.addAll(['--auth-uri', authUri.toString()]);
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

    _log.finest('Started cdrserver process (pid: ${_process.pid})');
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
