import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveHelper.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final MusicRepository musicRepository = MusicRepositoryImpl(
    remoteDataSource: YouTubeRemoteDataSource(),
    localDataSource: LocalMusicDataSource(),
  );

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MusicListBloc>(
          create: (context) => MusicListBloc(
            getMusicList: GetMusicList(musicRepository),
            addMusic: AddMusic(musicRepository),
            removeMusic: RemoveMusic(musicRepository),
          )..add(LoadMusicList()),
        ),
      ],
      child: MaterialApp(
        title: 'Music App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomePage(),
      ),
    );
  }
}