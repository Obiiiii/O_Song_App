/// Lớp cấu hình chứa các thông tin cấu hình toàn cục của ứng dụng
///
/// Lưu ý: Thay 'YOUR_YOUTUBE_API_KEY' bằng API key thực tế từ Google Cloud Console
/// Hướng dẫn lấy API key:
/// 1. Truy cập https://console.cloud.google.com/
/// 2. Tạo project mới hoặc chọn project hiện có
/// 3. Kích hoạt YouTube Data API v3
/// 4. Tạo API key và copy vào đây
/// 5. Hạn chế API key chỉ cho YouTube Data API v3 để bảo mật
class Config {
  /// YouTube Data API v3 key để truy cập dữ liệu video/playlist
  ///
  /// Cần thay thế bằng API key thực tế để ứng dụng hoạt động
  /// Format: AIza...
  static const String youtubeApiKey = 'YOUR_YOUTUBE_API_KEY';

  /// Kiểm tra xem API key đã được cấu hình chưa
  static bool get isApiKeyConfigured =>
      youtubeApiKey != 'YOUR_YOUTUBE_API_KEY' &&
      youtubeApiKey.isNotEmpty &&
      youtubeApiKey.startsWith('AIza');

  /// Base URL cho YouTube Data API v3
  static const String youtubeApiBaseUrl =
      'https://www.googleapis.com/youtube/v3';

  /// Timeout mặc định cho các request HTTP (giây)
  static const Duration httpTimeout = Duration(seconds: 30);

  /// Số lượng retry khi request bị lỗi
  static const int maxRetries = 3;

  /// Delay giữa các retry (milliseconds)
  static const Duration retryDelay = Duration(milliseconds: 1000);

  /// Maximum số lượng bài nhạc có thể lưu trong local storage
  static const int maxLocalMusicItems = 1000;

  /// Default thumbnail quality
  static const String defaultThumbnailQuality = 'mqdefault'; // medium quality

  /// Supported YouTube URL patterns
  static const List<String> supportedUrlPatterns = [
    r'youtube\.com\/watch\?v=',
    r'youtu\.be\/',
    r'm\.youtube\.com\/watch\?v=',
    r'youtube\.com\/embed\/',
    r'youtube\.com\/v\/',
  ];

  /// Validate API key format
  static bool validateApiKey(String apiKey) {
    if (apiKey.isEmpty) return false;
    if (apiKey == 'YOUR_YOUTUBE_API_KEY') return false;
    if (!apiKey.startsWith('AIza')) return false;
    if (apiKey.length < 35)
      return false; // YouTube API keys are typically 39 characters
    return true;
  }

  /// Get thumbnail URL cho video ID
  static String getThumbnailUrl(
    String videoId, {
    String quality = 'mqdefault',
  }) {
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }

  /// Kiểm tra xem URL có được hỗ trợ không
  static bool isValidYouTubeUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      return uri.host.contains('youtube.com') ||
          uri.host.contains('youtu.be') ||
          uri.host.contains('m.youtube.com');
    } catch (e) {
      return false;
    }
  }

  /// App configuration
  static const String appName = 'O Song App';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'YouTube Music Player App';

  /// Storage keys for local preferences
  static const String lastPlayedMusicKey = 'last_played_music';
  static const String playbackPositionKey = 'playback_position';
  static const String volumeLevelKey = 'volume_level';
  static const String darkModeKey = 'dark_mode';
}
