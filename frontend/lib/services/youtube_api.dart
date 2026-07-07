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

  static Future<String?> download(String videoId, String format, String quality) async {
    final res = await http.post(
      Uri.parse("$baseUrl/video/download"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "video_id": videoId,
        "format": format,
        "quality": quality,
      }),
    );

    if (res.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(res.body);
    return data["success"] == true ? data["filename"] : null;
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final res = await http.get(Uri.parse("$baseUrl/settings"));
    if (res.statusCode != 200) {
      throw Exception("Failed to fetch settings");
    }
    return jsonDecode(res.body);
  }

  static Future<bool> updateSettings(String downloadPath, {bool? darkMode}) async {
    final body = <String, dynamic>{'download_path': downloadPath};
    if (darkMode != null) {
      body['dark_mode'] = darkMode;
    }
    final res = await http.put(
      Uri.parse("$baseUrl/settings"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    return res.statusCode == 200;
  }
}
