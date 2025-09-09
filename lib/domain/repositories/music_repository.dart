import '../entities/music_entity.dart';

abstract class MusicRepository {
  Future<List<MusicEntity>> getMusicList();
  Future<void> addMusic(MusicEntity music);
  Future<void> removeMusic(String musicId);
}