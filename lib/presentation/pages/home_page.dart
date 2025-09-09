import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:o_song_app/presentation/blocs/music_list_bloc/music_list_bloc.dart';
import 'package:o_song_app/presentation/pages/add_music_page.dart';
import 'package:o_song_app/presentation/pages/player_page.dart';
import 'package:o_song_app/presentation/widgets/music_list_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddMusicPage()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MusicListBloc, MusicListState>(
        builder: (context, state) {
          if (state is MusicListLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MusicListError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is MusicListLoaded) {
            if (state.musicList.isEmpty) {
              return const Center(
                child: Text('No music added yet. Tap + to add some!'),
              );
            }

            return ListView.builder(
              itemCount: state.musicList.length,
              itemBuilder: (context, index) {
                final music = state.musicList[index];
                return MusicListItem(
                  music: music,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerPage(music: music),
                      ),
                    );
                  },
                  onDelete: () {
                    context.read<MusicListBloc>().add(
                      RemoveMusicItem(musicId: music.id),
                    );
                  },
                );
              },
            );
          } else {
            return const Center(child: Text('Unknown state'));
          }
        },
      ),
    );
  }
}