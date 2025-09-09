import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:o_song_app/core/config.dart';

class YouTubeRemoteDataSource {
  static const String BASE_URL = 'https://www.googleapis.com/youtube/v3';

  Future<Map<String, dynamic>> getVideoData(String videoId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$BASE_URL/videos?part=snippet,contentDetails&id=$videoId&key=${Config.youtubeApiKey}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return data;
        } else {
          throw Exception('Video not found');
        }
      } else if (response.statusCode == 403) {
        throw Exception('API quota exceeded. Please try again later.');
      } else {
        throw Exception('Failed to load video data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getPlaylistData(String playlistId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$BASE_URL/playlists?part=snippet,contentDetails&id=$playlistId&key=${Config.youtubeApiKey}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return data;
        } else {
          throw Exception('Playlist not found');
        }
      } else if (response.statusCode == 403) {
        throw Exception('API quota exceeded. Please try again later.');
      } else {
        throw Exception('Failed to load playlist data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  String extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.first;
      } else if (uri.host.contains('youtube.com')) {
        final videoId = uri.queryParameters['v'];
        if (videoId != null && videoId.isNotEmpty) {
          return videoId;
        }
      }

      // Fallback regex for other URL formats
      final regExp = RegExp(
        r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*',
        caseSensitive: false,
      );

      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 2 && match.group(2) != null) {
        return match.group(2)!;
      }

      throw Exception('Invalid YouTube URL');
    } catch (e) {
      throw Exception('Invalid URL format: $e');
    }
  }

  String extractPlaylistId(String url) {
    try {
      final uri = Uri.parse(url);
      final playlistId = uri.queryParameters['list'];
      if (playlistId != null && playlistId.isNotEmpty) {
        return playlistId;
      }

      // Fallback regex
      final regExp = RegExp(r'[&?]list=([^&]+)', caseSensitive: false);

      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 1 && match.group(1) != null) {
        return match.group(1)!;
      }

      throw Exception('Invalid YouTube playlist URL');
    } catch (e) {
      throw Exception('Invalid URL format: $e');
    }
  }
}