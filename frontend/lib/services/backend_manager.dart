import 'dart:async';
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

  String get host => defaultHost;
  int get port => defaultPort;
  String get baseUrl => 'http://$host:$port';
  bool get isReady => _ready;

  final _readyController = StreamController<bool>.broadcast();
  Stream<bool> get onReady => _readyController.stream;

  /// Try to connect to the backend. If running in dev mode (started
  /// manually by the user or via the launcher batch file), the backend
  /// will already be listening. In production, the launcher batch file
  /// starts the backend before opening the Flutter window.
  Future<void> start() async {
    if (_ready) return;

    if (await _healthCheck()) {
      _setReady(true);
      return;
    }

    // Backend not ready yet; poll in background
    _beginBackgroundCheck();
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
