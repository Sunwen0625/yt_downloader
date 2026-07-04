import 'package:flutter/material.dart';

class HomeInputView extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  const HomeInputView({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library, size: 80, color: Colors.redAccent),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '貼上 YouTube 影片或播放清單網址',
              prefixIcon: const Icon(Icons.link),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onSubmitted: (_) => onSearch(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('解析網址', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
