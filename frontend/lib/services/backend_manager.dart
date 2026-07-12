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
  String get host => defaultHost;
  int get port => defaultPort;
  String get baseUrl => 'http://$host:$port';

  bool get isRunning => _process != null;

  /// Directory containing the current executable
  String get _appDir {
    try {
      return File(Platform.resolvedExecutable).parent.path;
    } catch (_) {
      return Directory.current.path;
    }
  }

  /// Find the backend executable bundled with the app
  String _findBackendExecutable() {
    final exeName = Platform.isWindows
        ? 'yt-downloader-backend.exe'
        : 'yt-downloader-backend';

    // 1) Same directory as the Flutter executable
    final sameDir = File('${_appDir}\\$exeName');
    if (sameDir.existsSync()) {
      debugPrint('[BackendManager] Found at: ${sameDir.absolute.path}');
      return sameDir.absolute.path;
    }

    // 2) Current working directory
    final cwd = File(exeName);
    if (cwd.existsSync()) {
      debugPrint('[BackendManager] Found at: ${cwd.absolute.path}');
      return cwd.absolute.path;
    }

    // 3) Search PATH
    final pathEnv = Platform.environment['PATH'] ?? '';
    for (final dir in pathEnv.split(';')) {
      if (dir.isEmpty) continue;
      try {
        final candidate = File('$dir\\$exeName');
        if (candidate.existsSync()) {
          debugPrint('[BackendManager] Found on PATH: ${candidate.absolute.path}');
          return candidate.absolute.path;
        }
      } catch (_) {}
    }

    debugPrint('[BackendManager] Backend executable not found.');
    return '';
  }

  /// Start the backend process (non-blocking for UI)
  Future<bool> start({String? customPath}) async {
    if (_process != null) return true;

    if (await _healthCheck()) {
      debugPrint('[BackendManager] Backend already running.');
      return true;
    }

    final executable = customPath ?? _findBackendExecutable();
    if (executable.isEmpty || !File(executable).existsSync()) {
      debugPrint('[BackendManager] No backend executable found, skipping auto-start.');
      return false;
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
        debugPrint('[BackendManager] Process exited with code: $code');
        _process = null;
      });
    } catch (e) {
      debugPrint('[BackendManager] Failed to start: $e');
      return false;
    }

    // Wait briefly for backend to be ready
    for (int i = 0; i < 10; i++) {
      if (await _healthCheck()) {
        debugPrint('[BackendManager] Backend is ready.');
        return true;
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    debugPrint('[BackendManager] Backend started but not responding yet.');
    return true;
  }

  Future<void> stop() async {
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
}
