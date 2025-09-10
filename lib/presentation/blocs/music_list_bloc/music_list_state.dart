part of 'music_list_bloc.dart';

abstract class MusicListState extends Equatable {
  const MusicListState();

  @override
  List<Object> get props => [];
}

class MusicListInitial extends MusicListState {}

class MusicListLoading extends MusicListState {}

class MusicListLoaded extends MusicListState {
  final List<MusicEntity> musicList;

  const MusicListLoaded({required this.musicList});

  @override
  List<Object> get props => [musicList];
}

class MusicListError extends MusicListState {
  final String message;

  const MusicListError({required this.message});

  @override
  List<Object> get props => [message];
}
