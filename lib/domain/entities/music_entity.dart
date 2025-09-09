import 'package:equatable/equatable.dart';

class MusicEntity extends Equatable {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final Duration duration;

  const MusicEntity({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
  });

  @override
  List<Object> get props => [id, title, thumbnailUrl, videoUrl, duration];
}