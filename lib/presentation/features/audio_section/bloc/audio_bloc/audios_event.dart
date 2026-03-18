part of 'audios_bloc.dart';

// Events
sealed class AudiosEvent extends Equatable {
  const AudiosEvent();

  @override
  List<Object> get props => [];
}

class AudiosLoadAllEvent extends AudiosEvent {}

class AudiosLoadFromDirectoryEvent extends AudiosEvent {
  final Directory directory;

  const AudiosLoadFromDirectoryEvent({required this.directory});

  @override
  List<Object> get props => [directory];
}
