import 'package:hive/hive.dart';
import 'package:o_song_app/domain/entities/music_entity.dart';

part 'music_model.g.dart';

@HiveType(typeId: 0)
class MusicModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String thumbnailUrl;

  @HiveField(3)
  final String videoUrl;

  @HiveField(4)
  final int durationInSeconds;

  MusicModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.durationInSeconds,
  });

  Duration get duration => Duration(seconds: durationInSeconds);

  factory MusicModel.fromEntity(MusicEntity entity) {
    return MusicModel(
      id: entity.id,
      title: entity.title,
      thumbnailUrl: entity.thumbnailUrl,
      videoUrl: entity.videoUrl,
      durationInSeconds: entity.duration.inSeconds,
    );
  }

  MusicEntity toEntity() {
    return MusicEntity(
      id: id,
      title: title,
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      duration: duration,
    );
  }
}