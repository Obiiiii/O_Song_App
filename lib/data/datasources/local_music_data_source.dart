import 'package:o_song_app/data/models/music_model.dart';
import 'package:o_song_app/core/utils/hive_helper.dart';
import 'package:o_song_app/domain/entities/music_entity.dart';

class LocalMusicDataSource {
  Future<List<MusicEntity>> getAllMusic() async {
    try {
      final musicBox = HiveHelper.getMusicBox();
      final musicModels = musicBox.values.toList();
      return musicModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw Exception('Failed to get music list: $e');
    }
  }

  Future<void> addMusic(MusicEntity music) async {
    try {
      final musicModel = MusicModel.fromEntity(music);
      await HiveHelper.addMusic(musicModel);
    } catch (e) {
      throw Exception('Failed to add music: $e');
    }
  }

  Future<void> removeMusic(String musicId) async {
    try {
      await HiveHelper.removeMusic(musicId);
    } catch (e) {
      throw Exception('Failed to remove music: $e');
    }
  }
}