import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('下載路徑'),
            subtitle: const Text('/storage/emulated/0/Download'),
            onTap: () {
              // TODO: 選擇資料夾
            },
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.high_quality),
            title: const Text('優先下載最高畫質'),
            value: true,
            onChanged: (bool value) {
              // TODO: 儲存設定
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('關於'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'YT Downloader',
                applicationVersion: '1.0.0',
              );
            },
          ),
        ],
      ),
    );
  }
}
