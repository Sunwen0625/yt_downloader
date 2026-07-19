import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'services/youtube_api.dart';
import 'services/backend_manager.dart';

class YTDownloaderApp extends StatefulWidget {
  const YTDownloaderApp({super.key});

  @override
  State<YTDownloaderApp> createState() => _YTDownloaderAppState();
}

class _YTDownloaderAppState extends State<YTDownloaderApp> with WidgetsBindingObserver, WindowListener {
  int _currentIndex = 0;
  ThemeMode _themeMode = ThemeMode.light;
  String _character = '星奈';
  bool _backendReady = false;
  StreamSubscription<bool>? _backendSub;

  @override
  void initState() {
    super.initState();
    // 註冊生命週期監聽
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 註冊視窗監聽
      windowManager.addListener(this);
    }

    //訂閱後端狀態的 Stream，當後端從「未就緒」變為「就緒」時會觸發
    _backendSub = BackendManager().onReady.listen((ready) {
      //檢查後端是否已就緒，並確保當前 Widget 仍存在於畫面樹中
      if (ready && mounted) {
        setState(() => _backendReady = true);
        _loadSettings();
      }
    });

    // 檢查當前狀態（處理「訂閱發生前，後端其實已經就緒」的邊緣情況）
    // 因為監聽器只會收到「變化」的訊號，如果不做這個檢查，
    // 若後端在畫面載入前就已經準備好了，UI 可能永遠不會切換成「就緒」狀態。
    if (BackendManager().isReady) {
      _backendReady = true;
      _loadSettings();
    }
  }

  @override
  void dispose() {
    _backendSub?.cancel();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    // 移除，避免記憶體洩漏
    WidgetsBinding.instance.removeObserver(this);
    BackendManager().dispose();
    super.dispose();
  }

  //關閉視窗
  @override
  void onWindowClose() async {
    //先傳輸關閉訊號給後端
    await BackendManager().shutdown();
    //再關閉應用程式
    exit(0);
  }

  //生命週期死亡時，關閉後端
  @override
  void didChangeAppLifecycleState(AppLifecycleState state)async{
    if (state == AppLifecycleState.detached) {
      BackendManager().stop();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final data = await YoutubeApi.getSettings();
      if (mounted) {
        setState(() {
          _themeMode = data['dark_mode'] == true ? ThemeMode.dark : ThemeMode.light;
          _character = data['character'] ?? '星奈';
        });
      }
    } catch (_) {}
  }
  //從後端的介面的配置，設置狀態
  void _onToggleTheme(bool isDark) {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void _onCharacterChanged(String name) {
    setState(() => _character = name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YT Downloader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: _backendReady ? _mainScaffold() : _loadingScreen(),
    );
  }

  //轉圈元件，後端尚未就緒時顯示
  Widget _loadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              '正在啟動後端...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  //主畫面
  Widget _mainScaffold() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(character: _character),
          SettingsScreen(
            isDarkMode: _themeMode == ThemeMode.dark,
            onToggle: _onToggleTheme,
            character: _character,
            onCharacterChanged: _onCharacterChanged,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
