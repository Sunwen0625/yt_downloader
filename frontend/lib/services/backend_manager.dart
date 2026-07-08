import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class BackendManager {
  static final BackendManager _singleton = BackendManager._internal();
  factory BackendManager() => _singleton;
  BackendManager._internal();

  static const String defaultHost = '127.0.0.1';
  static const int defaultPort = 8000;

  Process? _process;
  String _backendPath = '';
  String get host => defaultHost;
  int get port => defaultPort;
  String get baseUrl => 'http://$host:$port';

  bool get isRunning => _process != null;

  /// Try to find the backend executable bundled with the app
  String _findBackendExecutable() {
    final candidates = [
      // Bundled with Flutter app (same directory)
      Platform.isWindows
          ? 'yt-downloader-backend.exe'
          : 'yt-downloader-backend',
      // Development: poetry
      '',
    ];

    for (final name in candidates) {
      if (name.isEmpty) continue;
      final file = File(name);
      if (file.existsSync()) {
        return file.absolute.path;
      }
      // Also check in the app's data directory
      final inDataDir = File('${Platform.script.toFilePath()}/../$name');
      if (inDataDir.existsSync()) {
        return inDataDir.absolute.path;
      }
    }

    return '';
  }

  /// Start the backend process
  Future<bool> start({String? customPath}) async {
    if (_process != null) return true;

    // Check if backend is already running (e.g. user started it manually)
    if (await _healthCheck()) {
      return true;
    }

    String executable = customPath ?? _findBackendExecutable();

    if (executable.isNotEmpty && File(executable).existsSync()) {
      // Production mode: start bundled backend executable
      try {
        _process = await Process.start(executable, [], runInShell: true);
        _process!.stdout.transform(utf8.decoder).listen((data) {
          stdout.write('[backend] $data');
        });
        _process!.stderr.transform(utf8.decoder).listen((data) {
          stderr.write('[backend] $data');
        });
        _process!.exitCode.then((code) {
          print('Backend process exited with code: $code');
          _process = null;
        });
      } catch (e) {
        print('Failed to start backend executable: $e');
        return false;
      }
    }

    // Wait for backend to be ready
    for (int i = 0; i < 30; i++) {
      if (await _healthCheck()) {
        print('Backend is ready!');
        return true;
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    print('Backend did not start in time.');
    return false;
  }

  /// Stop the backend process
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

  /// Check if backend is responding
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
