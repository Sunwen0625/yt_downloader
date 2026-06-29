import 'package:flutter/material.dart';
import '../widgets/list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 模擬數據
  final List<Map<String, String>> _mockVideos = List.generate(
    10,
    (index) => {
      "title": "範例影片名稱 #${index + 1} - 這裡是一個比較長的標題測試",
      "duration": "${index + 3}:45",
      "thumbnailUrl": "https://picsum.photos/200/120?random=$index",
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube 下載器'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 計算每個 Item 的高度，讓畫面剛好顯示 5 個
          // 加入 clamp 確保在極端尺寸下不會太難看
          double itemHeight = (constraints.maxHeight / 5).clamp(100.0, 150.0);

          return ListView.builder(
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
                    SnackBar(content: Text('開始下載: ${video["title"]}')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
