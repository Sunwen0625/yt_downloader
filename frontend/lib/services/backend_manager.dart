import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendManager {
  static final BackendManager _singleton = BackendManager._internal();
  factory BackendManager() => _singleton;
  BackendManager._internal();

  static const String defaultHost = '127.0.0.1';
  static const int defaultPort = 8000;

  bool _ready = false;
  Timer? _healthTimer;
  Process? _backendProcess;

  String get host => defaultHost;
  int get port => defaultPort;
  String get baseUrl => 'http://$host:$port';
  bool get isReady => _ready;

  final _readyController = StreamController<bool>.broadcast();
  Stream<bool> get onReady => _readyController.stream;

  Future<void> start() async {
    if (_ready) return;

    if (await _healthCheck()) {
      _setReady(true);
      return;
    }

    await _spawnBackend();

    _beginBackgroundCheck();
  }

  Future<void> _spawnBackend() async {
    if (_backendProcess != null) return;

    final exePath = _findBackendExecutable();
    if (exePath != null) {
      debugPrint('[Backend] Starting backend executable: $exePath');
      await _tryStartExecutable(exePath);
      if (_backendProcess != null) return;
    }

    final backendDir = _findBackendDir();
    if (backendDir == null) {
      debugPrint('[Backend] Could not locate backend directory.');
      return;
    }

    debugPrint('[Backend] Starting backend from: ${backendDir.path}');

    if (Platform.isWindows) {
      await _tryStart(backendDir, 'poetry', ['run', 'uvicorn', 'main:app', '--host', defaultHost, '--port', '$defaultPort']);
      if (_backendProcess != null) return;

      final venvUvicorn = '${backendDir.path}\\.venv\\Scripts\\uvicorn.exe';
      if (File(venvUvicorn).existsSync()) {
        await _tryStart(backendDir, venvUvicorn, ['main:app', '--host', defaultHost, '--port', '$defaultPort']);
        if (_backendProcess != null) return;
      }

      await _tryStart(backendDir, 'uvicorn', ['main:app', '--host', defaultHost, '--port', '$defaultPort']);
    } else {
      await _tryStart(backendDir, 'poetry', ['run', 'uvicorn', 'main:app', '--host', defaultHost, '--port', '$defaultPort']);
      if (_backendProcess != null) return;

      await _tryStart(backendDir, 'uvicorn', ['main:app', '--host', defaultHost, '--port', '$defaultPort']);
      if (_backendProcess != null) return;

      await _tryStart(backendDir, 'python3', ['-m', 'uvicorn', 'main:app', '--host', defaultHost, '--port', '$defaultPort']);
    }
  }

  String? _findBackendExecutable() {
    final exeName = Platform.isWindows ? 'yt-downloader-backend.exe' : 'yt-downloader-backend';
    final scriptDir = Directory.current.path;

    final candidates = [
      '$scriptDir/$exeName',
      '${scriptDir}/../dist/yt-downloader-win64/$exeName',
      '${scriptDir}/../../dist/yt-downloader-win64/$exeName',
      '../backend/dist/$exeName',
      '${scriptDir}/backend/dist/$exeName',
      '${scriptDir}/../backend/dist/$exeName',
    ];

    for (final p in candidates) {
      final file = File(p);
      if (file.existsSync()) {
        return file.resolveSymbolicLinksSync();
      }
    }
    return null;
  }

  Future<void> _tryStartExecutable(String exePath) async {
    try {
      final exeDir = Directory(exePath).parent;
      final process = await Process.start(exePath, [], workingDirectory: exeDir.path, runInShell: false);
      process.stdout.transform(utf8.decoder).listen((data) => debugPrint('[Backend:out] $data'));
      process.stderr.transform(utf8.decoder).listen((data) => debugPrint('[Backend:err] $data'));
      process.exitCode.then((code) {
        debugPrint('[Backend] Process exited with code $code');
        if (_backendProcess == process) {
          _backendProcess = null;
          _ready = false;
        }
      });
      _backendProcess = process;
      debugPrint('[Backend] Started executable: $exePath');
    } catch (e) {
      debugPrint('[Backend] Failed to start executable: $exePath (${e.runtimeType}: $e)');
    }
  }

  Future<void> _tryStart(Directory wd, String cmd, List<String> args) async {
    try {
      final process = await Process.start(cmd, args, workingDirectory: wd.path, runInShell: Platform.isWindows);
      process.stdout.transform(utf8.decoder).listen((data) => debugPrint('[Backend:out] $data'));
      process.stderr.transform(utf8.decoder).listen((data) => debugPrint('[Backend:err] $data'));
      process.exitCode.then((code) {
        debugPrint('[Backend] Process exited with code $code');
        if (_backendProcess == process) {
          _backendProcess = null;
          _ready = false;
        }
      });
      _backendProcess = process;
      debugPrint('[Backend] Started: $cmd ${args.join(' ')}');
    } catch (e) {
      debugPrint('[Backend] Failed: $cmd (${e.runtimeType}: $e)');
    }
  }

  Directory? _findBackendDir() {
    final scriptPath = Platform.script.toFilePath();
    final dirs = [
      Directory('${Directory.current.path}/../backend'),
      Directory('${scriptPath}/../../backend'),
      Directory('${scriptPath}/../backend'),
      Directory('../backend'),
      Directory('backend'),
    ];

    for (final d in dirs) {
      if (d.existsSync()) {
        final mainPy = File('${d.path}/main.py');
        if (mainPy.existsSync()) return d;
      }
    }
    return null;
  }

  void _beginBackgroundCheck() {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (await _healthCheck()) {
        _setReady(true);
        _healthTimer?.cancel();
        debugPrint('[Backend] Backend is now ready.');
      }
    });
  }

  void _setReady(bool value) {
    if (_ready == value) return;
    _ready = value;
    _readyController.add(value);
  }

  Future<void> stop() async {
    _healthTimer?.cancel();
    _ready = false;
    await _killProcess();
  }

  Future<void> shutdown() async {
    _healthTimer?.cancel();
    _ready = false;
    try {
      await http.post(Uri.parse('$baseUrl/shutdown')).timeout(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('[Backend] Shutdown request failed: $e');
    }
    await _killProcess();
  }

  Future<void> _killProcess() async {
    if (_backendProcess != null) {
      _backendProcess!.kill();
      await _backendProcess!.exitCode;
      _backendProcess = null;
    }
  }

  Future<bool> _healthCheck() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/settings')).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _healthTimer?.cancel();
    _readyController.close();
    _killProcess();
  }
}
