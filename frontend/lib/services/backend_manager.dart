import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendManager {
  //單例
  static final BackendManager _singleton = BackendManager._internal();
  factory BackendManager() => _singleton;
  BackendManager._internal();
  //設置端口
  static const String defaultHost = '127.0.0.1';
  static const int defaultPort = 8000;
  //設置狀態參數
  bool _ready = false;
  Timer? _healthTimer;
  Process? _backendProcess;

  String get host => defaultHost;
  int get port => defaultPort;
  String get baseUrl => 'http://$host:$port';
  bool get isReady => _ready;

  final _readyController = StreamController<bool>.broadcast();
  Stream<bool> get onReady => _readyController.stream;
  //啟用後端服務
  Future<void> start() async {
    if (_ready) return;

    if (await _healthCheck()) {
      _setReady(true);
      return;
    }

    await _spawnBackend();

    _beginBackgroundCheck();
  }
  //啟用後端服務的具體實現，會根據不同平台選擇不同的啟動方式
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
    //使用poetry跟uvicorn啟動後端服務，根據不同平台選擇不同的命令
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
  //查找後段可能的位置
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
  //嘗試啟用linux/mac平台的後端服務
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
  //嘗試啟用win平台的後端服務
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
  //查找後端目錄
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
  //後端程式尚未準備好時，讓 Flutter 前端進行「輪詢 (Polling)」直到連線成功的機制
  void _beginBackgroundCheck() {
    //在啟動計時器之前，先取消可能已經存在的舊計時器。這可以避免因為重複呼叫
    _healthTimer?.cancel();
    //週期性執行：這會建立一個計時器，每隔 2 秒 就會執行一次
    _healthTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (await _healthCheck()) {
        _setReady(true);
        //一旦確認後端已經活著，就必須「停止」這個計時器，否則它會無止盡地每 2 秒發送一次請求
        _healthTimer?.cancel();
        debugPrint('[Backend] Backend is now ready.');
      }
    });
  }
  //檢測是否已經啟動
  void _setReady(bool value) {
    if (_ready == value) return;
    _ready = value;
    _readyController.add(value);
  }
  //停止後端服務
  Future<void> stop() async {
    _healthTimer?.cancel();
    _ready = false;
    _killProcess();
  }
  //關閉後端服務
  Future<void> shutdown() async {
    _healthTimer?.cancel();
    _ready = false;
    try {
      //嘗試向後端發送關閉請求，並設定超時時間為 300 毫秒
      await http.post(Uri.parse('$baseUrl/shutdown')).timeout(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('[Backend] Shutdown request failed: $e');
    }
    _killProcess();
  }
  //殺掉後端進程
  void _killProcess() {
    _backendProcess?.kill();
    _backendProcess = null;
  }
  //檢查後端服務是否健康
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
