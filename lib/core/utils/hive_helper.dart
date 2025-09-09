import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:o_song_app/data/models/music_model.dart';

class HiveHelper {
  static bool _isInitialized = false;

  static Future<void> init() async {
    try {
      if (!_isInitialized) {
        final appDocumentDirectory = await path_provider
            .getApplicationDocumentsDirectory();
        Hive.init(appDocumentDirectory.path);

        Hive.registerAdapter(MusicModelAdapter());

        await Hive.openBox<MusicModel>('musicBox');
        _isInitialized = true;
      }
    } catch (e) {
      throw Exception('Failed to initialize Hive: $e');
    }
  }

  static Box<MusicModel> getMusicBox() {
    if (!_isInitialized) {
      throw Exception(
        'Hive has not been initialized. Call HiveHelper.init() first.',
      );
    }
    return Hive.box<MusicModel>('musicBox');
  }

  static Future<void> addMusic(MusicModel music) async {
    try {
      final box = getMusicBox();
      await box.put(music.id, music);
    } catch (e) {
      throw Exception('Failed to add music: $e');
    }
  }

  static Future<void> removeMusic(String musicId) async {
    try {
      final box = getMusicBox();
      await box.delete(musicId);
    } catch (e) {
      throw Exception('Failed to remove music: $e');
    }
  }

  static List<MusicModel> getAllMusic() {
    try {
      final box = getMusicBox();
      return box.values.toList();
    } catch (e) {
      throw Exception('Failed to get all music: $e');
    }
  }
}