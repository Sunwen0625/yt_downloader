class VideoItem {
  final String videoId;
  final String title;
  final String thumbnail;
  final String duration;

  List<String> formats;
  List<String> qualities;

  bool metadataLoaded;

  String selectedFormat;
  String selectedQuality;

  VideoItem({
    required this.videoId,
    required this.title,
    required this.thumbnail,
    required this.duration,
    this.formats = const [],
    this.qualities = const [],
    this.metadataLoaded = false,
    this.selectedFormat = "mp4",
    this.selectedQuality = "720p",
  });
}