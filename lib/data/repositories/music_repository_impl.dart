import 'package:o_song_app/domain/entities/music_entity.dart';
import 'package:o_song_app/domain/repositories/music_repository.dart';
import 'package:o_song_app/data/datasources/youtube_remote_data_source.dart';
import 'package:o_song_app/data/datasources/local_music_data_source.dart';

/// Implementation của MusicRepository interface
///
/// Kết hợp dữ liệu từ local storage (Hive) và remote API (YouTube)
/// Tuân theo Repository Pattern trong Clean Architecture
class MusicRepositoryImpl implements MusicRepository {
  final YouTubeRemoteDataSource remoteDataSource;
  final LocalMusicDataSource localDataSource;

  /// Constructor nhận vào các data source dependencies
  MusicRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  /// Lấy danh sách tất cả bài nhạc đã lưu
  ///
  /// Returns [List<MusicEntity>] - Danh sách bài nhạc từ local storage
  ///
  /// Throws [Exception] nếu có lỗi khi truy cập local storage
  @override
  Future<List<MusicEntity>> getMusicList() async {
    try {
      print('Getting music list from local storage');

      final musicList = await localDataSource.getAllMusic();

      // Sort by added time (newest first) if available
      musicList.sort((a, b) {
        // Assuming we have addedAt field in the future
        // For now, sort by title
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

      print('Successfully retrieved ${musicList.length} music items');
      return musicList;
    } catch (e) {
      print('Error getting music list: $e');
      throw Exception('Failed to get music list: $e');
    }
  }

  /// Thêm bài nhạc mới vào danh sách
  ///
  /// Sẽ tự động lấy metadata từ YouTube API trước khi lưu
  /// Nếu không lấy được metadata, sẽ lưu với thông tin cơ bản
  ///
  /// [music] - MusicEntity cần thêm (có thể chỉ có URL)
  ///
  /// Throws [Exception] nếu có lỗi trong quá trình thêm
  @override
  Future<void> addMusic(MusicEntity music) async {
    try {
      print('Adding music: ${music.title}');

      // Validate input
      if (music.videoUrl.isEmpty) {
        throw ArgumentError('Video URL cannot be empty');
      }

      // Check if URL is valid YouTube URL
      if (!YouTubeRemoteDataSource.isValidYouTubeUrl(music.videoUrl)) {
        throw ArgumentError('Invalid YouTube URL');
      }

      MusicEntity musicToSave = music;

      // Try to get metadata from YouTube API
      try {
        final videoId = remoteDataSource.extractVideoId(music.videoUrl);

        // Check if music already exists
        final existingMusic = await localDataSource.getAllMusic();
        if (existingMusic.any((m) => m.id == videoId)) {
          throw Exception('Music already exists in the playlist');
        }

        print('Fetching metadata for video ID: $videoId');
        final videoData = await remoteDataSource.getVideoData(videoId);

        // Extract metadata from API response
        final snippet = videoData['items'][0]['snippet'];
        final contentDetails = videoData['items'][0]['contentDetails'];

        // Create updated music entity with real metadata
        musicToSave = MusicEntity(
          id: videoId,
          title: _cleanTitle(snippet['title']),
          thumbnailUrl: _getBestThumbnail(snippet['thumbnails']),
          videoUrl: music.videoUrl,
          duration: _parseDuration(contentDetails['duration']),
        );

        print('Successfully fetched metadata: ${musicToSave.title}');
      } catch (e) {
        print('Failed to fetch metadata: $e');

        // Fallback: create basic music entity
        final videoId = _generateFallbackId(music.videoUrl);
        musicToSave = MusicEntity(
          id: videoId,
          title: music.title.isNotEmpty ? music.title : 'Unknown Title',
          thumbnailUrl: music.thumbnailUrl.isNotEmpty
              ? music.thumbnailUrl
              : _generateThumbnailUrl(videoId),
          videoUrl: music.videoUrl,
          duration: music.duration.inSeconds > 0
              ? music.duration
              : const Duration(minutes: 3, seconds: 45), // Default duration
        );

        print('Using fallback metadata: ${musicToSave.title}');
      }

      // Save to local storage
      await localDataSource.addMusic(musicToSave);
      print('Successfully added music to local storage: ${musicToSave.title}');

    } catch (e) {
      print('Error adding music: $e');
      throw Exception('Failed to add music: $e');
    }
  }

  /// Xóa bài nhạc khỏi danh sách
  ///
  /// [musicId] - ID của bài nhạc cần xóa
  ///
  /// Throws [Exception] nếu có lỗi khi xóa
  @override
  Future<void> removeMusic(String musicId) async {
    try {
      if (musicId.isEmpty) {
        throw ArgumentError('Music ID cannot be empty');
      }

      print('Removing music with ID: $musicId');

      await localDataSource.removeMusic(musicId);

      print('Successfully removed music: $musicId');
    } catch (e) {
      print('Error removing music: $e');
      throw Exception('Failed to remove music: $e');
    }
  }

  /// Parse ISO 8601 duration từ YouTube API thành Duration object
  ///
  /// YouTube API trả về duration dạng "PT4M13S" (4 minutes 13 seconds)
  ///
  /// [isoDuration] - Duration string từ API
  ///
  /// Returns [Duration] - Parsed duration object
  Duration _parseDuration(String isoDuration) {
    try {
      // Regex để parse PT format: PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?
      final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
      final match = regex.firstMatch(isoDuration);

      if (match != null) {
        final hours = int.parse(match.group(1) ?? '0');
        final minutes = int.parse(match.group(2) ?? '0');
        final seconds = int.parse(match.group(3) ?? '0');

        final duration = Duration(hours: hours, minutes: minutes, seconds: seconds);
        print('Parsed duration: $isoDuration -> ${duration.inSeconds}s');
        return duration;
      }

      print('Failed to parse duration, using fallback: $isoDuration');
      return const Duration(minutes: 3, seconds: 45); // Fallback duration
    } catch (e) {
      print('Error parsing duration: $e');
      return const Duration(minutes: 3, seconds: 45);
    }
  }

  /// Làm sạch title từ YouTube (remove emoji, special chars)
  ///
  /// [title] - Raw title từ YouTube API
  ///
  /// Returns [String] - Cleaned title
  String _cleanTitle(String title) {
    try {
      // Remove excessive whitespace và newlines
      String cleaned = title.replaceAll(RegExp(r'\s+'), ' ').trim();

      // Truncate if too long
      if (cleaned.length > 100) {
        cleaned = '${cleaned.substring(0, 97)}...';
      }

      return cleaned;
    } catch (e) {
      print('Error cleaning title: $e');
      return title;
    }
  }

  /// Chọn thumbnail chất lượng tốt nhất từ YouTube API
  ///
  /// [thumbnails] - Thumbnails object từ API response
  ///
  /// Returns [String] - URL của thumbnail tốt nhất
  String _getBestThumbnail(Map<String, dynamic> thumbnails) {
    try {
      // Ưu tiên: high -> medium -> default
      if (thumbnails.containsKey('high')) {
        return thumbnails['high']['url'];
      } else if (thumbnails.containsKey('medium')) {
        return thumbnails['medium']['url'];
      } else if (thumbnails.containsKey('default')) {
        return thumbnails['default']['url'];
      }

      // Fallback
      return '';
    } catch (e) {
      print('Error getting thumbnail: $e');
      return '';
    }
  }

  /// Generate fallback ID từ URL khi không extract được
  ///
  /// [url] - Video URL
  ///
  /// Returns [String] - Generated ID
  String _generateFallbackId(String url) {
    try {
      // Try to extract video ID first
      return remoteDataSource.extractVideoId(url);
    } catch (e) {
      // Generate hash-based ID from URL
      return url.hashCode.abs().toString();
    }
  }

  /// Generate thumbnail URL từ video ID
  ///
  /// [videoId] - YouTube video ID
  ///
  /// Returns [String] - Thumbnail URL
  String _generateThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
  }
}