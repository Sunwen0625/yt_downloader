import 'package:flutter/material.dart';
import '../widgets/list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasSearched = false;
  bool _isLoadingMore = false;

  // 模擬解析後的數據
  final List<Map<String, String>> _mockVideos = List.generate(
    10,
    (index) => {
      "title": "解析到的影片 #${index + 1} - 這裡是一個比較長的標題測試",
      "duration": "${index + 3}:45",
      "thumbnailUrl": "https://picsum.photos/200/120?random=$index",
    },
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasSearched) {
      _fetchMoreVideos();
    }
  }

  Future<void> _fetchMoreVideos() async {
    setState(() {
      _isLoadingMore = true;
    });

    // 模擬網路延遲
    //await Future.delayed(const Duration(seconds: 2));

    final int currentLength = _mockVideos.length;
    final List<Map<String, String>> newVideos = List.generate(
      10,
      (index) => {
        "title": "解析到的影片 #${currentLength + index + 1} - 新載入的影片",
        "duration": "${index + 5}:12",
        "thumbnailUrl": "https://picsum.photos/200/120?random=${currentLength + index}",
      },
    );

    if (mounted) {
      setState(() {
        _mockVideos.addAll(newVideos);
        _isLoadingMore = false;
      });
    }
  }

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
                controller: _scrollController,
                itemCount: _mockVideos.length + (_isLoadingMore ? 3 : 0),
                itemExtent: itemHeight,
                itemBuilder: (context, index) {
                  if (index < _mockVideos.length) {
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
                  } else {
                    // 顯示加載中的佔位符
                    return const ListItem(isLoading: true);
                  }
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
    _scrollController.dispose();
    super.dispose();
  }
}
