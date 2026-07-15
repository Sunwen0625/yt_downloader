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
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
    }

    _backendSub = BackendManager().onReady.listen((ready) {
      if (ready && mounted) {
        setState(() => _backendReady = true);
        _loadSettings();
      }
    });

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
    WidgetsBinding.instance.removeObserver(this);
    BackendManager().dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await BackendManager().shutdown();
    await windowManager.destroy();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state)async{
    if (state == AppLifecycleState.detached) {
      BackendManager().shutdown();
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
