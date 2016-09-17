part of ort.process;

class MessageDispatcher implements ServiceProcess {
  final Logger _log = new Logger('$_namespace.MessageDispatcher');
  Process _process;

  final String path;
  final String storePath;
  final int servicePort;
  final String bindAddress;
  final Uri authUri;
  final Uri notificationUri;

  final Completer _ready = new Completer();
  bool get ready => _ready.isCompleted;
  Future get whenReady => _ready.future;

  MessageDispatcher(this.path, this.storePath,
      {this.servicePort: 4070,
      this.bindAddress: '0.0.0.0',
      this.authUri,
      this.notificationUri}) {
    _init();
  }

  Future _init() async {
    final Stopwatch initTimer = new Stopwatch()..start();
    whenReady.whenComplete(() {
      initTimer.stop();
      _log.info('Process initialization time was: '
          '${initTimer.elapsedMilliseconds}ms');
    });

    final arguments = [
      '$path/bin/messagedispatcher.dart',
      '--filestore',
      storePath,
      '--port',
      servicePort.toString(),
      '--host',
      bindAddress
    ];

    if (authUri != null) {
      arguments.addAll(['--auth-uri', authUri.toString()]);
    }

    if (notificationUri != null) {
      arguments.addAll(['--notification-uri', notificationUri.toString()]);
    }

    _log.fine('Starting process /usr/bin/dart ${arguments.join(' ')}');

    _process = await Process.start('/usr/bin/dart', arguments,
        workingDirectory: path)
      ..stdout
          .transform(new Utf8Decoder())
          .transform(new LineSplitter())
          .listen((String line) {
        _log.finest(line);
        if (!ready && line.contains('Ready to handle requests')) {
          _log.info('Ready');
          _ready.complete();
        }
      })
      ..stderr
          .transform(new Utf8Decoder())
          .transform(new LineSplitter())
          .listen(_log.warning);

    _log.finest('Started message dispatcher process (pid: ${_process.pid})');
    _launchedProcesses.add(_process);

    /// Protect from hangs caused by process crashes.
    _process.exitCode.then((int exitCode) {
      if (exitCode != 0 && !ready) {
        _ready.completeError(new StateError('Failed to launch process. '
            'Exit code: $exitCode'));
      }
    });
  }

  Future terminate() async {
    _process.kill();
    await _process.exitCode;
  }

  String toString() => '$runtimeType,pid:${_process.pid}';
}
