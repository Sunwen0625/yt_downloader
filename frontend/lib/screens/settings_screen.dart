import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/youtube_api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _downloadPath = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await YoutubeApi.getSettings();
      if (mounted) {
        setState(() {
          _downloadPath = data['download_path'] ?? '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editDownloadPath() async {
    try {
      debugPrint('Opening file picker...');
      String? result = await FilePicker.getDirectoryPath(
        dialogTitle: '選擇下載路徑',
      );
      debugPrint('Picker result: $result');

      if (result != null && result.isNotEmpty) {
        final success = await YoutubeApi.updateSettings(result);
        if (mounted) {
          if (success) {
            setState(() => _downloadPath = result);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('下載路徑已更新'), backgroundColor: Colors.green),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('更新失敗'), backgroundColor: Colors.redAccent),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking directory: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發生錯誤: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('下載路徑'),
                  subtitle: Text(_downloadPath.isNotEmpty ? _downloadPath : '尚未設定'),
                  onTap: _editDownloadPath,
                ),
                const Divider(),
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
