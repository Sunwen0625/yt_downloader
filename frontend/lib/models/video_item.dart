class VideoItem {
  final String videoId;
  final String title;
  final String thumbnail;
  final String duration;
  final String url;

  List<String> formats;
  List<String> qualities;


  String selectedFormat;
  String selectedQuality;

  VideoItem({
    required this.videoId,
    required this.title,
    required this.thumbnail,
    required this.duration,
    this.url = '',
    this.formats = const ['mp3', 'mp4'],
    this.qualities = const ['1080p', '720p', '480p'],
    this.selectedFormat = 'mp4',
    this.selectedQuality = '720p',
  });
}