import 'package:flutter/material.dart';
import 'dart:async';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/backend_manager.dart';

class YTDownloaderApp extends StatefulWidget {
  const YTDownloaderApp({super.key});

  @override
  State<YTDownloaderApp> createState() => _YTDownloaderAppState();
}

class _YTDownloaderAppState extends State<YTDownloaderApp> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _backendReady = false;
  StreamSubscription? _readySubscription;

  final List<Widget> _pages = [
    const HomeScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _readySubscription = BackendManager().onReady.listen((ready) {
      if (mounted) {
        setState(() => _backendReady = ready);
      }
    });
    if (BackendManager().isReady) {
      _backendReady = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _readySubscription?.cancel();
    BackendManager().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      BackendManager().shutdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YT Downloader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
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
        children: _pages,
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
    );
  }
}
