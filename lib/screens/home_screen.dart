import 'package:flutter/material.dart';
import '../services/youtube_api.dart';
import '../widgets/video_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  
  List<dynamic> _videos = [];
  bool _hasSearched = false;
  bool _isLoading = false;
  final Set<String> _downloadingIds = {};

  Future<void> _handleSearch() async {
    if (_urlController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final data = await YoutubeApi.getPlaylist(_urlController.text);

      setState(() {
        _videos = data["videos"];
        _hasSearched = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("解析失敗，請檢查網址是否正確")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                    _videos = [];
                  });
                },
              )
            ]
          : null,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : _hasSearched ? _buildResultsView() : _buildInputView(),
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
        // 動態計算高度，確保畫面顯示約 5 個
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
                itemCount: _videos.length,
                itemExtent: itemHeight,
                itemBuilder: (context, index) {
                  final video = _videos[index];
                  final String videoId = video["id"] ?? "";
                  
                  return VideoItem(
                    title: video["title"] ?? "無標題",
                    duration: video["duration"] ?? "00:00",
                    thumbnailUrl: video["thumbnailUrl"] ?? "",
                    isDownloading: _downloadingIds.contains(videoId),
                    downloadProgress: _downloadingIds.contains(videoId) ? 0.7 : 0.0, // 模擬進度
                    onDownload: (format, quality) async {
                      if (videoId.isEmpty) return;

                      setState(() => _downloadingIds.add(videoId));

                      try {
                        final success = await YoutubeApi.download(
                          videoId,
                          format,
                          quality,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? "下載成功：${video["title"]}" : "下載失敗"),
                              backgroundColor: success ? Colors.green : Colors.redAccent,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("下載發生錯誤"), backgroundColor: Colors.redAccent),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _downloadingIds.remove(videoId));
                        }
                      }
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
