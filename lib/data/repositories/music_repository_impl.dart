import 'package:o_song_app/domain/entities/music_entity.dart';
import 'package:o_song_app/domain/repositories/music_repository.dart';
import 'package:o_song_app/data/datasources/youtube_remote_data_source.dart';
import 'package:o_song_app/data/datasources/local_music_data_source.dart';

class MusicRepositoryImpl implements MusicRepository {
  final YouTubeRemoteDataSource remoteDataSource;
  final LocalMusicDataSource localDataSource;

  MusicRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<MusicEntity>> getMusicList() async {
    return await localDataSource.getAllMusic();
  }

  @override
  Future<void> addMusic(MusicEntity music) async {
    // Lấy metadata từ YouTube API
    try {
      final videoId = remoteDataSource.extractVideoId(music.videoUrl);
      final videoData = await remoteDataSource.getVideoData(videoId);

      // Cập nhật music entity với metadata thực tế
      final snippet = videoData['items'][0]['snippet'];
      final contentDetails = videoData['items'][0]['contentDetails'];

      final updatedMusic = MusicEntity(
        id: videoId,
        title: snippet['title'],
        thumbnailUrl: snippet['thumbnails']['default']['url'],
        videoUrl: music.videoUrl,
        duration: _parseDuration(contentDetails['duration']),
      );

      await localDataSource.addMusic(updatedMusic);
    } catch (e) {
      // Fallback: vẫn lưu music với thông tin cơ bản
      await localDataSource.addMusic(music);
    }
  }

  Duration _parseDuration(String isoDuration) {
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(isoDuration);

    if (match != null) {
      final hours = int.parse(match.group(1) ?? '0');
      final minutes = int.parse(match.group(2) ?? '0');
      final seconds = int.parse(match.group(3) ?? '0');

      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    }

    return const Duration(minutes: 3, seconds: 45); // Fallback
  }

  @override
  Future<void> removeMusic(String musicId) async {
    await localDataSource.removeMusic(musicId);
  }
}