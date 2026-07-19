import 'package:flutter/material.dart';
import '../services/youtube_api.dart';
import '../models/video_item.dart' as model;
import 'home_screen/input_view.dart';
import 'home_screen/results_view.dart';

class HomeScreen extends StatefulWidget {
  final String character;

  const HomeScreen({super.key, required this.character});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  
  List<model.VideoItem> _videos = [];
  //區分兩個畫面，一個是搜尋 一個是結果
  bool _hasSearched = false;
  bool _isLoading = false;
  final Map<String, double> _downloadingProgress = {};

  Future<void> _handleSearch() async {
    if (_urlController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      //從文字攔的文字發送api請求影片列表
      final data = await YoutubeApi.getPlaylist(_urlController.text);

      setState(() {
        //將返回的影片列表轉換為 VideoItem 對象，並更新狀態
        _videos = (data["videos"] as List).map((v) => model.VideoItem(
          videoId: v["id"]?.toString() ?? "",
          title: v["title"]?.toString() ?? "無標題",
          thumbnail: v["thumbnail"]?.toString() ?? "",
          duration: v["duration"]?.toString() ?? "00:00",
          url: v["url"]?.toString() ?? "",
        )).toList();
        _hasSearched = true;
      });
    } catch (e) {
      print(e);
      //顯示錯誤訊息在底下
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("解析失敗，請檢查網址是否正確")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDownload(model.VideoItem video, String format, String quality) async {
    final String videoId = video.videoId;
    if (videoId.isEmpty) return;

    setState(() => _downloadingProgress[videoId] = 0.0);
    //模擬下載進度
    final progressTimer = Stream.periodic(const Duration(milliseconds: 500), (count) {
      return (count + 1) * 0.05;
    }).takeWhile((p) => p <= 0.9).listen((p) {
      if (mounted && _downloadingProgress.containsKey(videoId)) {
        setState(() => _downloadingProgress[videoId] = p);
      }
    });

    try {
      final filename = await YoutubeApi.download(
        videoId,
        format,
        quality,
      );

      if (mounted) {
        setState(() {
          _downloadingProgress[videoId] = 1.0;
          video.isDownloaded = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(filename != null ? "下載成功：$filename" : "下載失敗"),
            backgroundColor: filename != null ? Colors.green : Colors.redAccent,
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
      progressTimer.cancel();
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() => _downloadingProgress.remove(videoId));
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube 下載器'),
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
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _hasSearched 
              ? HomeResultsView(
                  url: _urlController.text,
                  videos: _videos,
                  downloadingProgress: _downloadingProgress,
                  onDownload: _handleDownload,
                  character: widget.character,
                ) 
              : HomeInputView(
                  controller: _urlController,
                  onSearch: _handleSearch,
                ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
