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
void main() async {
  // Đảm bảo Flutter framework được khởi tạo trước khi chạy async code
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Setup error handling
  setupErrorHandling();

  // Initialize local database
  try {
    print('Initializing Hive database...');
    await HiveHelper.init();
    print('Hive database initialized successfully');

    // Run main app với BlocProvider
    runApp(const MyAppWithBloc());
  } catch (e, stackTrace) {
    print('Failed to initialize Hive: $e');
    print('Stack trace: $stackTrace');
    // Show error dialog or handle gracefully
    runApp(ErrorApp(message: 'Failed to initialize database: $e'));
  }
}

/// Wrapper widget để cung cấp Bloc cho toàn bộ app
class MyAppWithBloc extends StatelessWidget {
  const MyAppWithBloc({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Tạo repository instance với dependencies
    final MusicRepository musicRepository = MusicRepositoryImpl(
      remoteDataSource: YouTubeRemoteDataSource(),
      localDataSource: LocalMusicDataSource(),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<MusicListBloc>(
          create: (context) => MusicListBloc(
            getMusicList: GetMusicList(musicRepository),
            addMusic: AddMusic(musicRepository),
            removeMusic: RemoveMusic(musicRepository),
          )..add(LoadMusicList()), // Load data ngay khi khởi tạo
        ),
      ],
      child: const MyApp(),
    );
  }
}

/// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'O Song App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String message;

  const ErrorApp({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Application Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
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
                  onPressed: () async {
                    // Restart app properly
                    try {
                      await HiveHelper.init();
                      runApp(const MyAppWithBloc());
                    } catch (e) {
                      // If still fails, show system navigation
                      SystemNavigator.pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
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

// Setup error handling for the entire app
void setupErrorHandling() {
  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return ErrorDisplayWidget(error: errorDetails.exception.toString());
  };
}

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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await HiveHelper.init();
                  runApp(const MyAppWithBloc());
                } catch (e) {
                  SystemNavigator.pop();
                }
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
