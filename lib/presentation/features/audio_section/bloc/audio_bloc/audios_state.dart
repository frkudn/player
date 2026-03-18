part of 'audios_bloc.dart';

sealed class AudiosState extends Equatable {
  const AudiosState();

  @override
  List<Object> get props => [];
}

class AudiosInitial extends AudiosState {}

class AudiosLoading extends AudiosState {}

class AudiosSuccess extends AudiosState {
  final List<AudioModel> allSongs;
  final List<AudioModel> dirSongs;

  const AudiosSuccess({required this.allSongs, required this.dirSongs});

  AudiosSuccess copyWith(
      List<AudioModel>? allSongs, List<AudioModel>? dirSongs) {
    return AudiosSuccess(allSongs: allSongs??this.allSongs, dirSongs: dirSongs??this.dirSongs);
  }

  @override
  List<Object> get props => [allSongs, dirSongs];
}

class AudiosFailure extends AudiosState {
  final String message;

  const AudiosFailure(this.message);

  @override
  List<Object> get props => [message];
}
