import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:o_song_app/config.dart';

/// Data source để tương tác với YouTube Data API v3
class YouTubeRemoteDataSource {
  // Base URL cho tất cả YouTube API endpoints
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  // HTTP client với timeout
  static final http.Client _client = http.Client();

  // Timeout cho các HTTP requests
  static const Duration _timeout = Duration(seconds: 30);

  /// Lấy thông tin chi tiết của video từ YouTube API
  Future<Map<String, dynamic>> getVideoData(String videoId) async {
    try {
      // Validate input
      if (videoId.isEmpty) {
        throw ArgumentError('Video ID cannot be empty');
      }

      if (videoId.length != 11) {
        throw ArgumentError('Invalid YouTube video ID format');
      }

      // Kiểm tra API key
      if (!Config.isApiKeyConfigured) {
        throw Exception('YouTube API key is not configured');
      }

      // Construct API URL
      final url =
          '$_baseUrl/videos'
          '?part=snippet,contentDetails'
          '&id=$videoId'
          '&key=${Config.youtubeApiKey}';

      print('Fetching video data for ID: $videoId');

      // Make HTTP request with timeout
      final response = await _client.get(Uri.parse(url)).timeout(_timeout);

      // Handle HTTP response
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if video exists
        if (data['items'] != null && data['items'].isNotEmpty) {
          print(
            'Successfully fetched video data: ${data['items'][0]['snippet']['title']}',
          );
          return data;
        } else {
          throw Exception('Video not found or may be private/deleted');
        }
      } else if (response.statusCode == 400) {
        throw Exception('Invalid request. Please check video ID format.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'API quota exceeded or invalid API key. Please try again later.',
        );
      } else if (response.statusCode == 404) {
        throw Exception('Video not found');
      } else {
        throw Exception(
          'HTTP error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on TimeoutException {
      throw Exception(
        'Request timeout. Please check your internet connection.',
      );
    } catch (e) {
      print('Error in getVideoData: $e');
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// Lấy thông tin playlist từ YouTube API
  Future<Map<String, dynamic>> getPlaylistData(String playlistId) async {
    try {
      // Validate input
      if (playlistId.isEmpty) {
        throw ArgumentError('Playlist ID cannot be empty');
      }

      // Kiểm tra API key
      if (!Config.isApiKeyConfigured) {
        throw Exception('YouTube API key is not configured');
      }

      // Construct API URL
      final url =
          '$_baseUrl/playlists'
          '?part=snippet,contentDetails'
          '&id=$playlistId'
          '&key=${Config.youtubeApiKey}';

      print('Fetching playlist data for ID: $playlistId');

      // Make HTTP request with timeout
      final response = await _client.get(Uri.parse(url)).timeout(_timeout);

      // Handle HTTP response
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if playlist exists
        if (data['items'] != null && data['items'].isNotEmpty) {
          print(
            'Successfully fetched playlist data: ${data['items'][0]['snippet']['title']}',
          );
          return data;
        } else {
          throw Exception('Playlist not found or may be private');
        }
      } else if (response.statusCode == 400) {
        throw Exception('Invalid request. Please check playlist ID format.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'API quota exceeded or invalid API key. Please try again later.',
        );
      } else if (response.statusCode == 404) {
        throw Exception('Playlist not found');
      } else {
        throw Exception(
          'HTTP error ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on TimeoutException {
      throw Exception(
        'Request timeout. Please check your internet connection.',
      );
    } catch (e) {
      print('Error in getPlaylistData: $e');
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// Trích xuất video ID từ YouTube URL
  String extractVideoId(String url) {
    try {
      // Validate input
      if (url.isEmpty) {
        throw ArgumentError('URL cannot be empty');
      }

      print('Extracting video ID from URL: $url');

      // Parse URL
      final uri = Uri.parse(url);

      // Handle youtu.be format
      if (uri.host.contains('youtu.be')) {
        final videoId = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first
            : null;
        if (videoId != null && videoId.length == 11) {
          print('Extracted video ID: $videoId');
          return videoId;
        }
      }
      // Handle youtube.com format
      else if (uri.host.contains('youtube.com')) {
        // Check query parameter 'v'
        final videoId = uri.queryParameters['v'];
        if (videoId != null && videoId.isNotEmpty && videoId.length >= 11) {
          final cleanId = videoId.substring(0, 11); // Take first 11 characters
          print('Extracted video ID: $cleanId');
          return cleanId;
        }

        // Check embed format
        if (uri.pathSegments.contains('embed') &&
            uri.pathSegments.length >= 2) {
          final videoId =
              uri.pathSegments[uri.pathSegments.indexOf('embed') + 1];
          if (videoId.length >= 11) {
            final cleanId = videoId.substring(0, 11);
            print('Extracted video ID from embed: $cleanId');
            return cleanId;
          }
        }

        // Check /v/ format
        if (uri.pathSegments.contains('v') && uri.pathSegments.length >= 2) {
          final videoId = uri.pathSegments[uri.pathSegments.indexOf('v') + 1];
          if (videoId.length >= 11) {
            final cleanId = videoId.substring(0, 11);
            print('Extracted video ID from /v/: $cleanId');
            return cleanId;
          }
        }
      }

      // Fallback: Use regex for complex cases
      final regExp = RegExp(
        r'^.*(?:youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]{11})',
        caseSensitive: false,
      );

      final match = regExp.firstMatch(url);
      if (match != null && match.group(1) != null) {
        final videoId = match.group(1)!;
        print('Extracted video ID via regex: $videoId');
        return videoId;
      }

      throw Exception('Could not extract video ID from URL');
    } catch (e) {
      print('Error extracting video ID: $e');
      throw Exception('Invalid YouTube URL format: $e');
    }
  }

  /// Trích xuất playlist ID từ YouTube URL
  String extractPlaylistId(String url) {
    try {
      // Validate input
      if (url.isEmpty) {
        throw ArgumentError('URL cannot be empty');
      }

      print('Extracting playlist ID from URL: $url');

      // Parse URL and check for 'list' parameter
      final uri = Uri.parse(url);
      final playlistId = uri.queryParameters['list'];

      if (playlistId != null && playlistId.isNotEmpty) {
        print('Extracted playlist ID: $playlistId');
        return playlistId;
      }

      // Fallback: Use regex
      final regExp = RegExp(r'[&?]list=([^&]+)', caseSensitive: false);
      final match = regExp.firstMatch(url);

      if (match != null && match.group(1) != null) {
        final playlistId = match.group(1)!;
        print('Extracted playlist ID via regex: $playlistId');
        return playlistId;
      }

      throw Exception('Could not extract playlist ID from URL');
    } catch (e) {
      print('Error extracting playlist ID: $e');
      throw Exception('Invalid YouTube playlist URL format: $e');
    }
  }

  /// Kiểm tra xem URL có phải là YouTube URL hợp lệ không
  static bool isValidYouTubeUrl(String url) {
    try {
      if (url.isEmpty) return false;

      final uri = Uri.parse(url);
      return uri.host.contains('youtube.com') ||
          uri.host.contains('youtu.be') ||
          uri.host.contains('m.youtube.com');
    } catch (e) {
      return false;
    }
  }

  /// Cleanup HTTP client
  static void dispose() {
    _client.close();
    print('HTTP client disposed');
  }
}
