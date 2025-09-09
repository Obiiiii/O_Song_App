import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:o_song_app/domain/entities/music_entity.dart';
import 'package:o_song_app/domain/usecases/get_music_list.dart';
import 'package:o_song_app/domain/usecases/add_music.dart';
import 'package:o_song_app/domain/usecases/remove_music.dart';

part 'music_list_event.dart';
part 'music_list_state.dart';

class MusicListBloc extends Bloc<MusicListEvent, MusicListState> {
  final GetMusicList getMusicList;
  final AddMusic addMusic;
  final RemoveMusic removeMusic;

  MusicListBloc({
    required this.getMusicList,
    required this.addMusic,
    required this.removeMusic,
  }) : super(MusicListInitial()) {
    on<LoadMusicList>(_onLoadMusicList);
    on<AddMusicItem>(_onAddMusicItem);
    on<RemoveMusicItem>(_onRemoveMusicItem);
  }

  Future<void> _onLoadMusicList(
      LoadMusicList event,
      Emitter<MusicListState> emit,
      ) async {
    emit(MusicListLoading());
    try {
      final musicList = await getMusicList();
      emit(MusicListLoaded(musicList: musicList));
    } catch (e) {
      emit(MusicListError(message: e.toString()));
    }
  }

  Future<void> _onAddMusicItem(
      AddMusicItem event,
      Emitter<MusicListState> emit,
      ) async {
    if (state is MusicListLoaded) {
      try {
        await addMusic(event.music);
        final updatedList = await getMusicList();
        emit(MusicListLoaded(musicList: updatedList));
      } catch (e) {
        emit(MusicListError(message: e.toString()));
      }
    }
  }

  Future<void> _onRemoveMusicItem(
      RemoveMusicItem event,
      Emitter<MusicListState> emit,
      ) async {
    if (state is MusicListLoaded) {
      try {
        await removeMusic(event.musicId);
        final updatedList = await getMusicList();
        emit(MusicListLoaded(musicList: updatedList));
      } catch (e) {
        emit(MusicListError(message: e.toString()));
      }
    }
  }
}