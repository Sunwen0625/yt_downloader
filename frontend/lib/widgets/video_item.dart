import 'package:flutter/material.dart';
import '../models/video_item.dart' as model;

class VideoItem extends StatefulWidget {
  //定義了 VideoItem 的屬性，包括視頻對象、下載狀態、下載進度、下載回調函數和角色名稱
  final model.VideoItem video;
  final bool isDownloading;
  final double downloadProgress;
  final Function(String format, String quality) onDownload;
  final String character;
  //構造函數，初始化 VideoItem 的屬性
  const VideoItem({
    super.key,
    required this.video,
    required this.isDownloading,
    required this.downloadProgress,
    required this.onDownload,
    required this.character,
  });

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDownloaded = widget.video.isDownloaded;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDownloaded ? 0 : 2,
      color: isDownloaded ? colorScheme.primaryContainer.withOpacity(0.3) : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDownloaded ? colorScheme.primaryContainer : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Opacity(
                  opacity: isDownloaded ? 0.7 : 1.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.video.thumbnail,
                      width: 140,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 140,
                        height: 80,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.video_library, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
                if (isDownloaded)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDownloaded ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.isDownloading) ...[
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            color: Colors.white,
                            child: Image.asset(
                              'assets/${widget.character}.gif',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: widget.downloadProgress,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${(widget.downloadProgress * 100).toStringAsFixed(0)}%",
                                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else if (isDownloaded)
                    Row(
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          "已下載完成",
                          style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => widget.onDownload(
                            widget.video.selectedFormat,
                            widget.video.selectedQuality,
                          ),
                          icon: const Icon(Icons.replay, size: 16),
                          label: const Text("重新下載", style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    )
                  else
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
                          icon: Icon(Icons.download, color: colorScheme.primary),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primary.withOpacity(0.1),
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
  //建構下拉選單
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
