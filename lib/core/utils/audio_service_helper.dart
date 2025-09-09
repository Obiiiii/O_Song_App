import 'package:audioplayers/audioplayers.dart';

class AudioServiceHelper {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;
  static String? _currentUrl;

  static Future<void> play(String url) async {
    try {
      if (_currentUrl != url) {
        await _audioPlayer.stop();
        await _audioPlayer.setSource(UrlSource(url));
        _currentUrl = url;
      }
      await _audioPlayer.resume();
      _isPlaying = true;
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  static Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      throw Exception('Failed to pause audio: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentUrl = null;
    } catch (e) {
      throw Exception('Failed to stop audio: $e');
    }
  }

  static Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      throw Exception('Failed to seek audio: $e');
    }
  }

  static Stream<Duration> get onPositionChanged {
    return _audioPlayer.onPositionChanged;
  }

  static Stream<Duration> get onDurationChanged {
    return _audioPlayer.onDurationChanged;
  }

  static Stream<PlayerState> get onPlayerStateChanged {
    return _audioPlayer.onPlayerStateChanged;
  }

  static bool get isPlaying => _isPlaying;
}