import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:o_song_app/data/models/music_model.dart';

/// Helper class để quản lý Hive database
///
/// Hive là NoSQL database nhanh và nhẹ cho Flutter/Dart
/// Sử dụng để lưu trữ danh sách nhạc offline
class HiveHelper {
  // Flag để kiểm tra xem Hive đã được khởi tạo chưa
  static bool _isInitialized = false;

  // Tên box lưu trữ music data
  static const String _musicBoxName = 'musicBox';

  /// Khởi tạo Hive database
  ///
  /// Phải được gọi trước khi sử dụng bất kỳ method nào khác
  /// Thường được gọi trong main() function
  ///
  /// Throws [Exception] nếu không thể khởi tạo Hive
  static Future<void> init() async {
    try {
      // Tránh khởi tạo lại nếu đã được khởi tạo
      if (_isInitialized) {
        print('Hive already initialized');
        return;
      }

      // Lấy thư mục để lưu trữ database
      final appDocumentDirectory = await path_provider
          .getApplicationDocumentsDirectory();

      // Khởi tạo Hive với đường dẫn cụ thể
      Hive.init(appDocumentDirectory.path);
      print('Hive initialized with path: ${appDocumentDirectory.path}');

      // Đăng ký adapter để Hive có thể serialize/deserialize MusicModel
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MusicModelAdapter());
        print('MusicModel adapter registered');
      }

      // Mở box để lưu trữ music data
      await Hive.openBox<MusicModel>(_musicBoxName);
      print('Music box opened successfully');

      _isInitialized = true;
    } catch (e) {
      print('Error initializing Hive: $e');
      throw Exception('Failed to initialize Hive: $e');
    }
  }

  /// Lấy music box instance
  ///
  /// Returns [Box<MusicModel>] để thao tác với music data
  ///
  /// Throws [Exception] nếu Hive chưa được khởi tạo
  static Box<MusicModel> getMusicBox() {
    if (!_isInitialized) {
      throw Exception(
        'Hive has not been initialized. Call HiveHelper.init() first.',
      );
    }

    // Kiểm tra xem box có đang mở không
    if (!Hive.isBoxOpen(_musicBoxName)) {
      throw Exception('Music box is not open');
    }

    return Hive.box<MusicModel>(_musicBoxName);
  }

  /// Thêm bài nhạc vào database
  ///
  /// [music] - MusicModel object cần lưu
  ///
  /// Sử dụng music.id làm key để tránh duplicate
  /// Throws [Exception] nếu không thể thêm
  static Future<void> addMusic(MusicModel music) async {
    try {
      final box = getMusicBox();

      // Sử dụng music ID làm key để dễ tìm kiếm và tránh duplicate
      await box.put(music.id, music);

      print('Music added to Hive: ${music.title}');
    } catch (e) {
      print('Error adding music to Hive: $e');
      throw Exception('Failed to add music: $e');
    }
  }

  /// Xóa bài nhạc khỏi database
  ///
  /// [musicId] - ID của bài nhạc cần xóa
  ///
  /// Throws [Exception] nếu không thể xóa
  static Future<void> removeMusic(String musicId) async {
    try {
      if (musicId.isEmpty) {
        throw ArgumentError('Music ID cannot be empty');
      }

      final box = getMusicBox();

      // Kiểm tra xem bài nhạc có tồn tại không
      if (!box.containsKey(musicId)) {
        print('Music with ID $musicId not found');
        return;
      }

      await box.delete(musicId);
      print('Music removed from Hive: $musicId');
    } catch (e) {
      print('Error removing music from Hive: $e');
      throw Exception('Failed to remove music: $e');
    }
  }

  /// Lấy tất cả bài nhạc từ database
  ///
  /// Returns [List<MusicModel>] chứa tất cả bài nhạc đã lưu
  ///
  /// Throws [Exception] nếu không thể lấy dữ liệu
  static List<MusicModel> getAllMusic() {
    try {
      final box = getMusicBox();
      final musicList = box.values.toList();

      print('Retrieved ${musicList.length} music items from Hive');
      return musicList;
    } catch (e) {
      print('Error getting music from Hive: $e');
      throw Exception('Failed to get all music: $e');
    }
  }

  /// Lấy bài nhạc theo ID
  ///
  /// [musicId] - ID của bài nhạc cần tìm
  ///
  /// Returns [MusicModel?] - null nếu không tìm thấy
  static MusicModel? getMusicById(String musicId) {
    try {
      if (musicId.isEmpty) {
        throw ArgumentError('Music ID cannot be empty');
      }

      final box = getMusicBox();
      return box.get(musicId);
    } catch (e) {
      print('Error getting music by ID: $e');
      return null;
    }
  }

  /// Kiểm tra xem bài nhạc có tồn tại không
  ///
  /// [musicId] - ID của bài nhạc cần kiểm tra
  ///
  /// Returns [bool] - true nếu tồn tại
  static bool containsMusic(String musicId) {
    try {
      if (musicId.isEmpty) return false;

      final box = getMusicBox();
      return box.containsKey(musicId);
    } catch (e) {
      print('Error checking music existence: $e');
      return false;
    }
  }

  /// Xóa tất cả bài nhạc
  ///
  /// Sử dụng cẩn thận - sẽ xóa toàn bộ dữ liệu
  static Future<void> clearAllMusic() async {
    try {
      final box = getMusicBox();
      await box.clear();
      print('All music cleared from Hive');
    } catch (e) {
      print('Error clearing music: $e');
      throw Exception('Failed to clear all music: $e');
    }
  }

  /// Đóng tất cả Hive boxes và cleanup
  ///
  /// Nên gọi khi ứng dụng tắt
  static Future<void> close() async {
    try {
      if (_isInitialized) {
        await Hive.close();
        _isInitialized = false;
        print('Hive closed successfully');
      }
    } catch (e) {
      print('Error closing Hive: $e');
    }
  }

  /// Getter để kiểm tra trạng thái khởi tạo
  static bool get isInitialized => _isInitialized;
}
