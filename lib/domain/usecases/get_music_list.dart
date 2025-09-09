import 'package:o_song_app/domain/repositories/music_repository.dart';
import 'package:o_song_app/domain/entities/music_entity.dart';

class GetMusicList {
  final MusicRepository repository;

  GetMusicList(this.repository);

  Future<List<MusicEntity>> call() async {
    return await repository.getMusicList();
  }
}