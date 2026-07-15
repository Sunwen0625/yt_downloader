import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/youtube_api.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggle;
  final String character;
  final ValueChanged<String> onCharacterChanged;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggle,
    required this.character,
    required this.onCharacterChanged,
  });

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
        final success = await YoutubeApi.updateSettings(
          downloadPath: result,
          darkMode: widget.isDarkMode,
          character: widget.character,
        );
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

  Future<void> _toggleDarkMode(bool value) async {
    widget.onToggle(value);
    if (_downloadPath.isNotEmpty) {
      await YoutubeApi.updateSettings(
        downloadPath: _downloadPath,
        darkMode: value,
        character: widget.character,
      );
    }
  }

  Future<void> _toggleCharacter(String name) async {
    widget.onCharacterChanged(name);
    if (_downloadPath.isNotEmpty) {
      await YoutubeApi.updateSettings(
        downloadPath: _downloadPath,
        darkMode: widget.isDarkMode,
        character: name,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  leading: Icon(
                    widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: colorScheme.primary,
                  ),
                  title: const Text('黑夜模式'),
                  trailing: Switch(
                    value: widget.isDarkMode,
                    onChanged: _toggleDarkMode,
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      const Text(
                        '切換下載角色',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/${widget.character}.gif',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('星奈'),
                            selected: widget.character == '星奈',
                            onSelected: (_) => _toggleCharacter('星奈'),
                            selectedColor: colorScheme.primaryContainer,
                          ),
                          const SizedBox(width: 16),
                          ChoiceChip(
                            label: const Text('彩奈'),
                            selected: widget.character == '彩奈',
                            onSelected: (_) => _toggleCharacter('彩奈'),
                            selectedColor: colorScheme.primaryContainer,
                          ),
                        ],
                      ),
                    ],
                  ),
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
