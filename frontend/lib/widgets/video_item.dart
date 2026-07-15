import 'package:flutter/material.dart';
import '../models/video_item.dart' as model;

class VideoItem extends StatefulWidget {
  final model.VideoItem video;
  final bool isDownloading;
  final double downloadProgress;
  final Function(String format, String quality) onDownload;

  const VideoItem({
    super.key,
    required this.video,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onDownload,
  });

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 縮圖
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.video.thumbnail,
                    width: 140,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 140,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.video_library, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.video.duration,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // 影片資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.isDownloading) ...[
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/Hoshina.gif',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: widget.downloadProgress,
                                backgroundColor: Colors.grey[200],
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${(widget.downloadProgress * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Row(
                      children: [
                        _buildDropdown(
                          value: widget.video.selectedFormat,
                          items: widget.video.formats.isEmpty ? ["mp4"] : widget.video.formats,
                          onChanged: (val) => setState(() => widget.video.selectedFormat = val!),
                        ),
                        if (widget.video.selectedFormat == 'mp4') ...[
                          const SizedBox(width: 8),
                          _buildDropdown(
                            value: widget.video.selectedQuality,
                            items: widget.video.qualities.isEmpty ? ["720p"] : widget.video.qualities,
                            onChanged: (val) => setState(() => widget.video.selectedQuality = val!),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          onPressed: () => widget.onDownload(
                            widget.video.selectedFormat,
                            widget.video.selectedQuality,
                          ),
                          icon: const Icon(Icons.download, color: Colors.redAccent),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
