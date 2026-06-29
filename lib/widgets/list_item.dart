import 'package:flutter/material.dart';
import 'dart:async';
import 'list_item_skeleton.dart';
import 'list_item_download_overlay.dart';

class ListItem extends StatefulWidget {
  final String title;
  final String thumbnailUrl;
  final String duration;
  final VoidCallback? onDownload;
  final bool isLoading;

  const ListItem({
    super.key,
    this.title = "YouTube 影片名稱",
    this.thumbnailUrl = "https://via.placeholder.com/150",
    this.duration = "00:00",
    this.onDownload,
    this.isLoading = false,
  });

  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  // 格式與畫質選項
  final List<String> formats = ["mp4", "mp3"];
  String selectedFormat = "mp4";
  final List<String> qualities = ["1080p", "720p", "480p", "360p"];
  String selectedQuality = "720p";

  // 下載狀態控制
  bool isDownloading = false;
  double downloadProgress = 0.0;
  Timer? _timer;

  // 模擬下載過程
  void _startMockDownload() {
    if (isDownloading) return;
    setState(() {
      isDownloading = true;
      downloadProgress = 0.0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        downloadProgress += 0.005;
        if (downloadProgress >= 1.0) {
          downloadProgress = 1.0;
          isDownloading = false;
          _timer?.cancel();
          if (widget.onDownload != null) widget.onDownload!();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardHeight = constraints.maxHeight;
        double imageHeight = cardHeight * 0.7;
        double imageWidth = imageHeight * (16 / 9);

        if (widget.isLoading) {
          return ListItemSkeleton(imageWidth: imageWidth, imageHeight: imageHeight);
        }

        return Card(
          elevation: isDownloading ? 8 : 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isDownloading
                ? const BorderSide(color: Colors.redAccent, width: 2)
                : BorderSide.none,
          ),
          child: Stack(
            children: [
              // 下載疊層 (進度條與 GIF)
              if (isDownloading)
                ListItemDownloadOverlay(
                  progress: downloadProgress,
                  maxWidth: constraints.maxWidth,
                ),

              // 內容層
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildThumbnail(imageWidth, imageHeight),
                    const SizedBox(width: 12),
                    _buildInfoSection(),
                    if (!isDownloading)
                      IconButton(
                        onPressed: _startMockDownload,
                        icon: const Icon(Icons.download, color: Colors.redAccent),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(double width, double height) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Opacity(
            opacity: isDownloading ? 0.4 : 1.0,
            child: Image.network(
              widget.thumbnailUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (!isDownloading)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
              child: Text(widget.duration, style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (isDownloading)
            Text(
              "下載中... ${(downloadProgress * 100).toInt()}%",
              style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
            )
          else
            _buildSelectors(),
        ],
      ),
    );
  }

  Widget _buildSelectors() {
    return Row(
      children: [
        // 格式選擇
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedFormat,
            isDense: true,
            onChanged: (String? newValue) {
              setState(() {
                selectedFormat = newValue!;
              });
            },
            items: formats.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value.toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
        ),
        if (selectedFormat == "mp4") ...[
          const SizedBox(width: 12),
          // 畫質選擇
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedQuality,
              isDense: true,
              onChanged: (String? newValue) {
                setState(() {
                  selectedQuality = newValue!;
                });
              },
              items: qualities.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
