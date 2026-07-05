import 'package:flutter/material.dart';
import '../services/youtube_api.dart';
import '../models/video_item.dart' as model;
import 'home_screen/input_view.dart';
import 'home_screen/results_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  
  List<model.VideoItem> _videos = [];
  bool _hasSearched = false;
  bool _isLoading = false;
  final Map<String, double> _downloadingProgress = {};

  Future<void> _handleSearch() async {
    if (_urlController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final data = await YoutubeApi.getPlaylist(_urlController.text);

      setState(() {
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

    // 模擬進度增加
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
        setState(() => _downloadingProgress[videoId] = 1.0);
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
          : _hasSearched 
              ? HomeResultsView(
                  url: _urlController.text,
                  videos: _videos,
                  downloadingProgress: _downloadingProgress,
                  onDownload: _handleDownload,
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
