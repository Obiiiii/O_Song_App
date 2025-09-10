import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:o_song_app/core/utils/hive_helper.dart';
import 'package:o_song_app/data/datasources/local_music_data_source.dart';
import 'package:o_song_app/data/datasources/youtube_remote_data_source.dart';
import 'package:o_song_app/data/repositories/music_repository_impl.dart';
import 'package:o_song_app/domain/repositories/music_repository.dart';
import 'package:o_song_app/domain/usecases/add_music.dart';
import 'package:o_song_app/domain/usecases/get_music_list.dart';
import 'package:o_song_app/domain/usecases/remove_music.dart';
import 'package:o_song_app/presentation/blocs/music_list_bloc/music_list_bloc.dart';
import 'package:o_song_app/presentation/pages/home_page.dart';

/// Entry point của ứng dụng
///
/// Khởi tạo các dependencies và chạy app
void main() async {
  // Đảm bảo Flutter framework được khởi tạo trước khi chạy async code
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize local database
  try {
    print('Initializing Hive database...');
    await HiveHelper.init();
    print('Hive database initialized successfully');
  } catch (e) {
    print('Failed to initialize Hive: $e');
    // Show error dialog or handle gracefully
    runApp(ErrorApp(message: 'Failed to initialize database: $e'));
    return;
  }

  // Run main app
  runApp(MyApp());
}

/// Main application widget
///
/// Thiết lập dependency injection và routing
class MyApp extends StatelessWidget {
  /// Tạo repository instance với dependencies
  ///
  /// Sử dụng dependency injection pattern để dễ test và maintain
  late final MusicRepository _musicRepository = MusicRepositoryImpl(
    remoteDataSource: YouTubeRemoteDataSource(),
    localDataSource: LocalMusicDataSource(),
  );

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // Cung cấp BLoC instances cho toàn bộ app
      providers: [
        BlocProvider<MusicListBloc>(
          create: (context) => MusicListBloc(
            getMusicList: GetMusicList(_musicRepository),
            addMusic: AddMusic(_musicRepository),
            removeMusic: RemoveMusic(_musicRepository),
          )..add(LoadMusicList()), // Load data ngay khi khởi tạo
        ),
      ],
      child: MaterialApp(
        // App configuration
        title: 'O Song App',
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: Colors.blue[600],

          // Modern Material Design 3
          useMaterial3: true,

          // Color scheme
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),

          // Visual density for different platforms
          visualDensity: VisualDensity.adaptivePlatformDensity,

          // AppBar theme
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            titleTextStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          // Card theme
          cardTheme: CardTheme(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          // Button themes
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Input decoration theme
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),

        // Dark theme (optional)
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),

        // Follow system theme
        themeMode: ThemeMode.system,

        // Home page
        home: const HomePage(),

        // Error handling
        builder: (context, child) {
          // Handle global errors
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            return ErrorDisplayWidget(error: errorDetails.exception.toString());
          };

          return child!;
        },
      ),
    );
  }
}

/// Widget hiển thị khi có lỗi khởi tạo app
class ErrorApp extends StatelessWidget {
  final String message;

  const ErrorApp({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Application Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart app
                    SystemNavigator.pop();
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget hiển thị lỗi trong quá trình chạy app
class ErrorDisplayWidget extends StatelessWidget {
  final String error;

  const ErrorDisplayWidget({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.red[50],
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bug_report, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
