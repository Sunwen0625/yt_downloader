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

  Process? _process;
  bool _ready = false;
  Timer? _healthTimer;

  String get host => defaultHost;
  int get port => defaultPort;
  String get baseUrl => 'http://$host:$port';
  bool get isReady => _ready;

  /// Notified when backend becomes ready (or after initial check)
  final _readyController = StreamController<bool>.broadcast();
  Stream<bool> get onReady => _readyController.stream;

  String get _appDir {
    try {
      return File(Platform.resolvedExecutable).parent.path;
    } catch (_) {
      return Directory.current.path;
    }
  }

  String _findBackendExecutable() {
    final exeName = Platform.isWindows
        ? 'yt-downloader-backend.exe'
        : 'yt-downloader-backend';

    final sameDir = File('${_appDir}\\$exeName');
    if (sameDir.existsSync()) {
      debugPrint('[Backend] Found at: ${sameDir.absolute.path}');
      return sameDir.absolute.path;
    }

    final cwd = File(exeName);
    if (cwd.existsSync()) {
      debugPrint('[Backend] Found at: ${cwd.absolute.path}');
      return cwd.absolute.path;
    }

    debugPrint('[Backend] Executable not found.');
    return '';
  }

  /// Start backend and wait up to [timeout] for it to respond.
  /// UI shows immediately after timeout; backend continues starting in background.
  Future<void> start({Duration timeout = const Duration(seconds: 5)}) async {
    if (_process != null || _ready) return;

    // Check if already running (e.g. development mode)
    if (await _healthCheck()) {
      _setReady(true);
      return;
    }

    final executable = _findBackendExecutable();
    if (executable.isEmpty || !File(executable).existsSync()) {
      debugPrint('[Backend] No bundled backend, assuming development mode.');
      _beginBackgroundCheck();
      return;
    }

    try {
      _process = await Process.start(executable, [], runInShell: true);
      _process!.stdout.transform(utf8.decoder).listen((data) {
        debugPrint('[backend] $data');
      });
      _process!.stderr.transform(utf8.decoder).listen((data) {
        debugPrint('[backend] $data');
      });
      _process!.exitCode.then((code) {
        debugPrint('[Backend] Process exited with code: $code');
        _process = null;
        _ready = false;
      });
    } catch (e) {
      debugPrint('[Backend] Failed to start: $e');
    }

    // Wait for readiness up to timeout
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await _healthCheck()) {
        _setReady(true);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint('[Backend] Timeout waiting for backend, continuing in background.');
    _beginBackgroundCheck();
  }

  void _beginBackgroundCheck() {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (await _healthCheck()) {
        _setReady(true);
        _healthTimer?.cancel();
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
    if (_process != null) {
      _process!.kill();
      await _process!.exitCode.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          _process!.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
      _process = null;
    }
    _ready = false;
  }

  Future<bool> _healthCheck() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/settings'))
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _healthTimer?.cancel();
    _readyController.close();
  }
}
