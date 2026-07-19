import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'services/backend_manager.dart';
import 'dart:io';

void main() async {
  //確保初始化
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    //設置窗口選項
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(700, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: "YouTube Downloader",
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    //攔截視窗關閉訊號 避免前端關閉後端沒關閉
    await windowManager.setPreventClose(true);
  }

  //啟動後端管理器
  BackendManager().start();

  runApp(const YTDownloaderApp());
}
