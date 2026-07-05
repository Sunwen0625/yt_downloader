import 'package:flutter/material.dart';
import '../../models/video_item.dart';
import '../../widgets/video_item.dart' as widget;

class HomeResultsView extends StatelessWidget {
  final String url;
  final List<VideoItem> videos;
  final Map<String, double> downloadingProgress;
  final Function(VideoItem video, String format, String quality) onDownload;

  const HomeResultsView({
    super.key,
    required this.url,
    required this.videos,
    required this.downloadingProgress,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
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
                      '已解析: $url',
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
                itemCount: videos.length,
                itemExtent: itemHeight,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  final String videoId = video.videoId;
                  final double? progress = downloadingProgress[videoId];
                  
                  return widget.VideoItem(
                    video: video,
                    isDownloading: progress != null,
                    downloadProgress: progress ?? 0.0,
                    onDownload: (format, quality) => onDownload(video, format, quality),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
