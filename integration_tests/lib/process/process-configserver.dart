part of ort.process;

class ConfigServer implements ServiceProcess {
  final String path;
  final int servicePort;
  final String bindAddress;

  final Logger _log = Logger('$_namespace.ConfigServer');
  Process _process;

  final Completer _ready = Completer();
  bool get ready => _ready.isCompleted;
  Future get whenReady => _ready.future;

  /**
   *
   */
  ConfigServer(this.path,
      {this.servicePort: 4080, this.bindAddress: '0.0.0.0'}) {
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
      processName = '${config.buildPath}/configserver';
    } else {
      processName = config.dartPath;
      arguments.add('${config.serverStackPath}/bin/configserver.dart');
    }

    arguments.addAll([
      '--httpport',
      servicePort.toString(),
      '--host',
      bindAddress
    ]);

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

    _log.finest('Started configserver process (pid: ${_process.pid})');
    _launchedProcesses.add(_process);

    /// Protect from hangs caused by process crashes.
    _process.exitCode.then((int exitCode) {
      if (exitCode != 0 && !ready) {
        _ready.completeError(StateError('Failed to launch process. '
            'Exit code: $exitCode'));
      }
    });
  }

  /// Constructs a [service.RESTConfiguration] based on the launch parameters
  /// of the process.
  service.RESTConfiguration createClient(service.Client client,
      {Uri uri: null}) {
    if (uri == null) {
      uri = Uri.parse('http://${bindAddress}:$servicePort');
    }

    return service.RESTConfiguration(uri, client);
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
