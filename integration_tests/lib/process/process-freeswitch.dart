part of ort.process;

class FreeSwitchConfig {}

class FreeSwitch implements ServiceProcess {
  final String binPath;
  final String basePath;
  final Directory confTemplateDir;
  final Directory exampleSoundsDir;

  String get logPath => basePath + '/log';
  String get confPath => basePath + '/conf';
  String get runPath => basePath + '/run';
  String get dbPath => basePath + '/db';
  String get soundsPath => basePath + '/sounds';
  String get ivrPath => confPath + '/ivr_menus';
  String get dialplanPath => confPath + '/dialplan';
  String get receptionDialplanPath => dialplanPath + '/receptions';
  String get userDirectoryPath => confPath + '/directory';
  String get receptionistsPath => userDirectoryPath + '/receptionists';
  String get testCallersPath => userDirectoryPath + '/test-callers';
  String get voicemailPath => userDirectoryPath + '/voicemail';

  final Logger _log = Logger('$_namespace.FreeSwitch');
  Process _process;
  int _childPid;

  final Completer _ready = Completer();
  bool get ready => _ready.isCompleted;
  Future get whenReady => _ready.future;

  FreeSwitch(this.binPath, this.basePath, this.confTemplateDir,
      this.exampleSoundsDir) {
    _init();
  }

  /**
   *
   */
  Future _createDirs() async {
    [
      logPath,
      confPath,
      runPath,
      dbPath,
      soundsPath,
      ivrPath,
      dialplanPath,
      receptionDialplanPath,
      userDirectoryPath,
      receptionistsPath,
      testCallersPath,
      voicemailPath
    ].forEach((path) {
      Directory dir = Directory(path);
      if (!dir.existsSync()) {
        _log.fine('Creating directory ${dir.absolute.path}');
        dir.createSync();
      }
    });
  }

  /**
   *
   */
  Future cleanConfig() async {
    Directory confDir = Directory(confPath);
    confDir.deleteSync(recursive: true);
    confDir.createSync();
    await _createDirs();

    _log.info('Cleaning config in directory ${confDir.absolute.path}');

    final args = ['-r', confTemplateDir.absolute.path, basePath];
    _log.info('Running /bin/cp ${args.join(' ')}');
    final copy = await Process.run('/bin/cp', args, workingDirectory: basePath);
    if (copy.exitCode != 0) {
      _log.shout('Failed to copy files to source dir');

      if (copy.stderr.isNotEmpty) {
        _log.shout(copy.stderr);
      }
      if (copy.stdout.isNotEmpty) {
        _log.shout(copy.stdout);
      }
    }

    _log.info('Copying example sounds from ${exampleSoundsDir.absolute.path}'
        ' to $soundsPath');

    final files = exampleSoundsDir.listSync().where((fse) => fse is File);

    Future.wait(files.map((FileSystemEntity fse) async {
      final File f = fse;
      final String newPath = soundsPath + '/' + basename(f.path);

      _log.finest('Copying "${f.path}" -> "${newPath}"');
      await f.copy(newPath);
    }));
  }

  /**
   *
   */
  void reRollLog() {
    _log.info('Rerolling log');
    _process.kill(ProcessSignal.sighup);
  }

  /**
   *
   */
  void reloadXml() {
    _process.stdin.writeln('reloadxml');
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

    await _createDirs();
    await cleanConfig();
    final arguments = [
      '-nonat',
      '-nonatmap',
      '-ncwait',
      '-log',
      logPath,
      '-conf',
      confPath,
      '-run',
      runPath,
      '-db',
      dbPath
    ];
    _log.fine(
        'Starting process $binPath in path ${basePath} arguments: ${arguments.join(' ')}');
    _process = await Process.start(binPath, arguments)
      ..stdout
          .transform(Utf8Decoder())
          .transform(LineSplitter())
          .listen((String line) {
        if (!ready && line.contains('System Ready')) {
          _childPid = int.parse(line.split(':')[1]);
          _log.info('Ready');
          _ready.complete();
        }
      })
      ..stderr
          .transform(Utf8Decoder())
          .transform(LineSplitter())
          .listen(_log.warning);
    _log.finest('Started process');

    _log.finest('Started freeswitch process (pid: ${_process.pid})');
    _launchedProcesses.add(_process);
  }

  /**
   *
   */
  File get latestLog => File('$logPath/freeswitch.log');

  /**
   *
   */
  Future terminate() async {
    _log.info('terminating freeswitch');
    await Process.start('/usr/local/freeswitch/bin/fs_cli', ['-x', 'shutdown'])
      ..stdout
          .transform(Utf8Decoder())
          .transform(LineSplitter())
          .listen((String line) {
        _log.fine("FS-cli returned: " + line);
      })
      ..stderr
          .transform(Utf8Decoder())
          .transform(LineSplitter())
          .listen(_log.warning);
    _log.info('Freeswitch terminated');
  }
}
