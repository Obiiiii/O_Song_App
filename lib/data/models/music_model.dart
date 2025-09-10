import 'package:hive/hive.dart';
import 'package:o_song_app/domain/entities/music_entity.dart';

part 'music_model.g.dart';

/// Model class để lưu trữ thông tin bài nhạc trong Hive database
///
/// Sử dụng Hive annotations để tự động generate adapter code
/// Implements Clean Architecture pattern bằng cách convert to/from Entity
@HiveType(typeId: 0)
class MusicModel {
  /// ID duy nhất của bài nhạc (thường là YouTube video ID)
  @HiveField(0)
  final String id;

  /// Tiêu đề bài nhạc
  @HiveField(1)
  final String title;

  /// URL thumbnail/poster của bài nhạc
  @HiveField(2)
  final String thumbnailUrl;

  /// URL video gốc (YouTube URL)
  @HiveField(3)
  final String videoUrl;

  /// Thời lượng bài nhạc tính bằng giây
  /// Lưu dưới dạng int để tiết kiệm storage
  @HiveField(4)
  final int durationInSeconds;

  /// Thời gian thêm bài nhạc vào danh sách
  @HiveField(5)
  final DateTime? addedAt;

  /// Constructor với validation
  MusicModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.durationInSeconds,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now() {
    // Validate required fields
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }
    if (title.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    if (videoUrl.isEmpty) {
      throw ArgumentError('Video URL cannot be empty');
    }
    if (durationInSeconds < 0) {
      throw ArgumentError('Duration cannot be negative');
    }
  }

  /// Convert seconds to Duration object
  ///
  /// Helper getter để dễ dàng làm việc với Duration
  Duration get duration => Duration(seconds: durationInSeconds);

  /// Format duration thành string dạng MM:SS hoặc HH:MM:SS
  ///
  /// Returns [String] - Formatted duration
  String get formattedDuration {
    final duration = Duration(seconds: durationInSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Kiểm tra xem bài nhạc có phải là video ngắn không (< 1 phút)
  bool get isShort => durationInSeconds < 60;

  /// Kiểm tra xem bài nhạc có phải là video dài không (> 10 phút)
  bool get isLong => durationInSeconds > 600;

  /// Factory constructor để tạo MusicModel từ MusicEntity
  ///
  /// [entity] - MusicEntity object từ domain layer
  ///
  /// Returns [MusicModel] - Model object để lưu vào database
  factory MusicModel.fromEntity(MusicEntity entity) {
    return MusicModel(
      id: entity.id,
      title: entity.title,
      thumbnailUrl: entity.thumbnailUrl,
      videoUrl: entity.videoUrl,
      durationInSeconds: entity.duration.inSeconds,
    );
  }

  /// Convert MusicModel thành MusicEntity
  ///
  /// Returns [MusicEntity] - Entity object cho domain layer
  MusicEntity toEntity() {
    return MusicEntity(
      id: id,
      title: title,
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      duration: duration,
    );
  }

  /// Factory constructor để tạo MusicModel từ JSON
  ///
  /// Hữu ích khi cần import/export data
  factory MusicModel.fromJson(Map<String, dynamic> json) {
    try {
      return MusicModel(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
        videoUrl: json['videoUrl']?.toString() ?? '',
        durationInSeconds: json['durationInSeconds']?.toInt() ?? 0,
        addedAt: json['addedAt'] != null
            ? DateTime.parse(json['addedAt'])
            : null,
      );
    } catch (e) {
      throw Exception('Failed to parse MusicModel from JSON: $e');
    }
  }

  /// Convert MusicModel thành JSON
  ///
  /// Returns [Map<String, dynamic>] - JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'durationInSeconds': durationInSeconds,
      'addedAt': addedAt?.toIso8601String(),
    };
  }

  /// Copy method với khả năng thay đổi một số field
  ///
  /// Hữu ích khi cần update một số thông tin của bài nhạc
  MusicModel copyWith({
    String? id,
    String? title,
    String? thumbnailUrl,
    String? videoUrl,
    int? durationInSeconds,
    DateTime? addedAt,
  }) {
    return MusicModel(
      id: id ?? this.id,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Override toString để debug dễ dàng hơn
  @override
  String toString() {
    return 'MusicModel('
        'id: $id, '
        'title: $title, '
        'duration: $formattedDuration, '
        'addedAt: $addedAt'
        ')';
  }

  /// Override equality operator để so sánh MusicModel
  ///
  /// Hai MusicModel được coi là bằng nhau nếu có cùng ID
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MusicModel && other.id == id;
  }

  /// Override hashCode để sử dụng trong Set, Map
  @override
  int get hashCode => id.hashCode;
}