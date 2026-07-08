import 'package:flutter/material.dart';
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

class _YTDownloaderAppState extends State<YTDownloaderApp> with WidgetsBindingObserver {
  int _currentIndex = 0;
  ThemeMode _themeMode = ThemeMode.light;
  String _character = '星奈';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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

  void _onToggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _onCharacterChanged(String name) {
    setState(() {
      _character = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YT Downloader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: Scaffold(
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
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '首頁',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '設定',
            ),
          ],
        ),
      ),
    );
  }
}
