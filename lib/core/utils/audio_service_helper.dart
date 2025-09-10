import 'package:audioplayers/audioplayers.dart';

/// Helper class quản lý việc phát nhạc trong ứng dụng
///
/// Sử dụng Singleton pattern để đảm bảo chỉ có 1 instance AudioPlayer
/// trong toàn bộ ứng dụng, tránh conflict khi phát nhiều nguồn âm thanh
class AudioServiceHelper {
  // Instance duy nhất của AudioPlayer
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Trạng thái phát nhạc hiện tại
  static bool _isPlaying = false;

  // URL của bài nhạc đang phát
  static String? _currentUrl;

  /// Phát nhạc từ URL
  ///
  /// [url] - URL của file âm thanh cần phát
  ///
  /// Nếu URL khác với URL hiện tại, sẽ dừng bài cũ và phát bài mới
  /// Throws [Exception] nếu không thể phát được âm thanh
  static Future<void> play(String url) async {
    try {
      // Validate URL
      if (url.isEmpty) {
        throw ArgumentError('URL cannot be empty');
      }

      // Nếu URL khác với bài đang phát, thay đổi nguồn
      if (_currentUrl != url) {
        await _audioPlayer.stop();
        await _audioPlayer.setSource(UrlSource(url));
        _currentUrl = url;
      }

      // Bắt đầu/tiếp tục phát
      await _audioPlayer.resume();
      _isPlaying = true;

      print('Audio started playing: $url');
    } catch (e) {
      _isPlaying = false;
      print('Error playing audio: $e');
      throw Exception('Failed to play audio: $e');
    }
  }

  /// Tạm dừng phát nhạc
  ///
  /// Throws [Exception] nếu không thể tạm dừng
  static Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
      print('Audio paused');
    } catch (e) {
      print('Error pausing audio: $e');
      throw Exception('Failed to pause audio: $e');
    }
  }

  /// Dừng phát nhạc hoàn toàn
  ///
  /// Khác với pause(), stop() sẽ reset về đầu bài và clear URL hiện tại
  /// Throws [Exception] nếu không thể dừng
  static Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentUrl = null;
      print('Audio stopped');
    } catch (e) {
      print('Error stopping audio: $e');
      throw Exception('Failed to stop audio: $e');
    }
  }

  /// Tua đến vị trí cụ thể trong bài nhạc
  ///
  /// [position] - Vị trí thời gian cần tua đến
  ///
  /// Throws [Exception] nếu không thể seek
  static Future<void> seek(Duration position) async {
    try {
      // Validate position
      if (position.isNegative) {
        throw ArgumentError('Position cannot be negative');
      }

      await _audioPlayer.seek(position);
      print('Audio seeked to: ${position.inSeconds}s');
    } catch (e) {
      print('Error seeking audio: $e');
      throw Exception('Failed to seek audio: $e');
    }
  }

  /// Stream cung cấp vị trí hiện tại của bài nhạc
  ///
  /// Có thể subscribe để cập nhật UI theo thời gian thực
  static Stream<Duration> get onPositionChanged {
    return _audioPlayer.onPositionChanged;
  }

  /// Stream cung cấp thông tin tổng thời lượng bài nhạc
  ///
  /// Được trigger khi bài nhạc được load thành công
  static Stream<Duration> get onDurationChanged {
    return _audioPlayer.onDurationChanged;
  }

  /// Stream cung cấp trạng thái của player
  ///
  /// Có thể sử dụng để cập nhật UI khi trạng thái thay đổi
  /// (playing, paused, stopped, completed)
  static Stream<PlayerState> get onPlayerStateChanged {
    return _audioPlayer.onPlayerStateChanged;
  }

  /// Getter để kiểm tra trạng thái phát nhạc hiện tại
  static bool get isPlaying => _isPlaying;

  /// Getter để lấy URL bài nhạc đang phát
  static String? get currentUrl => _currentUrl;

  /// Cleanup resources khi không cần dùng nữa
  ///
  /// Nên gọi khi ứng dụng bị đóng hoặc không cần audio player nữa
  static Future<void> dispose() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
      _isPlaying = false;
      _currentUrl = null;
      print('AudioPlayer disposed');
    } catch (e) {
      print('Error disposing AudioPlayer: $e');
    }
  }
}