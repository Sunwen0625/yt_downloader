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
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        double itemHeight = (constraints.maxHeight / 5).clamp(100.0, 150.0);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: colorScheme.tertiary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '已解析: $url',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
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
