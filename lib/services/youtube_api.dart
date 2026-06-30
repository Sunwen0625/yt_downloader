import 'dart:convert';
import 'package:http/http.dart' as http;

class YoutubeApi {
  static const baseUrl = "http://127.0.0.1:8000";

  static Future<Map<String, dynamic>> getPlaylist(String url) async {
    final res = await http.get(
      Uri.parse("$baseUrl/playlist?url=${Uri.encodeComponent(url)}"),
    );

    if (res.statusCode != 200) {
      throw Exception("API error");
    }

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getMetadata(String videoId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/video/$videoId/metadata"),
    );

    if (res.statusCode != 200) {
      throw Exception("Metadata fetch error");
    }

    return jsonDecode(res.body);
  }

  static Future<bool> download(String videoId, String format, String quality) async {
    final res = await http.post(
      Uri.parse("$baseUrl/download"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "video_id": videoId,
        "format": format,
        "quality": quality,
      }),
    );

    if (res.statusCode != 200) {
      return false;
    }

    final data = jsonDecode(res.body);
    return data["success"] ?? false;
  }
}
