import 'package:flutter/material.dart';

class ListItem extends StatefulWidget {
  final String title;
  final String thumbnailUrl;
  final String duration;
  final VoidCallback? onDownload;

  const ListItem({
    super.key,
    this.title = "YouTube 影片名稱",
    this.thumbnailUrl = "https://via.placeholder.com/150",
    this.duration = "00:00",
    this.onDownload,
  });

  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  // 格式選項
  final List<String> formats = ["mp4", "mp3"];
  String selectedFormat = "mp4";

  // 畫質選項 (僅 mp4 使用)
  final List<String> qualities = ["1080p", "720p", "480p", "360p"];
  String selectedQuality = "720p";

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根據 Card 的高度動態調整內部元件大小
        double cardHeight = constraints.maxHeight;
        double imageHeight = cardHeight * 0.7; // 縮圖佔 Card 高度的 70%
        double imageWidth = imageHeight * (16 / 9); // 保持 16:9 比例

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. 左側：影片縮圖
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.thumbnailUrl,
                        width: imageWidth,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: imageWidth,
                          height: imageHeight,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.duration,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // 2. 中間：影片資訊與選項
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // 垂直置中
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: cardHeight * 0.12 > 14 ? 14 : cardHeight * 0.12, // 動態字體大小
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // 格式選擇
                          DropdownButton<String>(
                            value: selectedFormat,
                            isDense: true,
                            underline: const SizedBox(),
                            style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedFormat = newValue!;
                              });
                            },
                            items: formats.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase()),
                              );
                            }).toList(),
                          ),
                          if (selectedFormat == "mp4") ...[
                            const SizedBox(width: 8),
                            // 畫質選擇
                            DropdownButton<String>(
                              value: selectedQuality,
                              isDense: true,
                              underline: const SizedBox(),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedQuality = newValue!;
                                });
                              },
                              items: qualities.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. 右側：下載按鈕
                IconButton(
                  onPressed: widget.onDownload,
                  icon: const Icon(Icons.download, color: Colors.redAccent),
                  iconSize: cardHeight * 0.25 > 24 ? 24 : cardHeight * 0.25, // 動態圖標大小
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "下載",
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
