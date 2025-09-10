import 'package:o_song_app/domain/repositories/music_repository.dart';

/// UseCase để xóa một bài nhạc khỏi danh sách
///
/// Tuân theo nguyên tắc Single Responsibility Principle (SRP)
/// và Dependency Inversion Principle (DIP) của Clean Architecture
class RemoveMusic {
  final MusicRepository repository;

  /// Constructor nhận vào repository để thực hiện việc xóa
  RemoveMusic(this.repository);

  /// Thực hiện việc xóa bài nhạc theo ID
  ///
  /// [musicId] - ID của bài nhạc cần xóa
  ///
  /// Throws [Exception] nếu có lỗi xảy ra trong quá trình xóa
  Future<void> call(String musicId) async {
    if (musicId.isEmpty) {
      throw ArgumentError('Music ID cannot be empty');
    }

    return await repository.removeMusic(musicId);
  }
}
