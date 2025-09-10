part of 'music_list_bloc.dart';

abstract class MusicListEvent extends Equatable {
  const MusicListEvent();

  @override
  List<Object> get props => [];
}

class LoadMusicList extends MusicListEvent {}

class AddMusicItem extends MusicListEvent {
  final MusicEntity music;

  const AddMusicItem({required this.music});

  @override
  List<Object> get props => [music];
}

class RemoveMusicItem extends MusicListEvent {
  final String musicId;

  const RemoveMusicItem({required this.musicId});

  @override
  List<Object> get props => [musicId];
}
