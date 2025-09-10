/// Lớp cấu hình chứa các thông tin cấu hình toàn cục của ứng dụng
///
/// Lưu ý: Thay 'YOUR_YOUTUBE_API_KEY' bằng API key thực tế từ Google Cloud Console
/// Hướng dẫn lấy API key:
/// 1. Truy cập https://console.cloud.google.com/
/// 2. Tạo project mới hoặc chọn project hiện có
/// 3. Kích hoạt YouTube Data API v3
/// 4. Tạo API key và copy vào đây
class Config {
  /// YouTube Data API v3 key để truy cập dữ liệu video/playlist
  ///
  /// Cần thay thế bằng API key thực tế để ứng dụng hoạt động
  static const String youtubeApiKey = 'YOUR_YOUTUBE_API_KEY';

  /// Kiểm tra xem API key đã được cấu hình chưa
  static bool get isApiKeyConfigured => youtubeApiKey != 'YOUR_YOUTUBE_API_KEY';

  /// Base URL cho YouTube Data API v3
  static const String youtubeApiBaseUrl = 'https://www.googleapis.com/youtube/v3';

  /// Timeout mặc định cho các request HTTP (giây)
  static const Duration httpTimeout = Duration(seconds: 30);
}