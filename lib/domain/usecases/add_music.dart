import 'package:o_song_app/domain/repositories/music_repository.dart';
import 'package:o_song_app/domain/entities/music_entity.dart';

class AddMusic {
  final MusicRepository repository;

  AddMusic(this.repository);

  Future<void> call(MusicEntity music) async {
    return await repository.addMusic(music);
  }
}