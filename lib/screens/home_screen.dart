import 'package:flutter/material.dart';
import '../widgets/list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _hasSearched = false;

  // 模擬解析後的數據
  final List<Map<String, String>> _mockVideos = List.generate(
    10,
    (index) => {
      "title": "解析到的影片 #${index + 1} - 這裡是一個比較長的標題測試",
      "duration": "${index + 3}:45",
      "thumbnailUrl": "https://picsum.photos/200/120?random=$index",
    },
  );

  void _handleSearch() {
    if (_urlController.text.isNotEmpty) {
      setState(() {
        _hasSearched = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入有效的 YouTube 網址')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube 下載器'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: _hasSearched 
          ? [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _hasSearched = false;
                    _urlController.clear();
                  });
                },
              )
            ]
          : null,
      ),
      body: _hasSearched ? _buildResultsView() : _buildInputView(),
    );
  }

  // 1. 輸入介面
  Widget _buildInputView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library, size: 80, color: Colors.redAccent),
          const SizedBox(height: 24),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: '貼上 YouTube 影片或播放清單網址',
              prefixIcon: const Icon(Icons.link),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onSubmitted: (_) => _handleSearch(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleSearch,
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

  // 2. 結果列表介面
  Widget _buildResultsView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 動態計算高度，確保畫面顯示 5 個
        double itemHeight = (constraints.maxHeight / 5).clamp(100.0, 150.0);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[50],
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '已解析: ${_urlController.text}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _mockVideos.length,
                itemExtent: itemHeight,
                itemBuilder: (context, index) {
                  final video = _mockVideos[index];
                  return ListItem(
                    title: video["title"]!,
                    duration: video["duration"]!,
                    thumbnailUrl: video["thumbnailUrl"]!,
                    onDownload: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('正在下載: ${video["title"]}')),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
