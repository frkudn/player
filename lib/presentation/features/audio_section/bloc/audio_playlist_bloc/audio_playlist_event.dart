part of 'audio_playlist_bloc.dart';

// Events
abstract class AudioPlaylistEvent extends Equatable {
  const AudioPlaylistEvent();

  @override
  List<Object> get props => [];
}

class LoadPlaylistsEvent extends AudioPlaylistEvent {}

class CreatePlaylistEvent extends AudioPlaylistEvent {
  final AudioPlaylistModel playlist;

  const CreatePlaylistEvent(this.playlist);

  @override
  List<Object> get props => [playlist];
}

class UpdatePlaylistEvent extends AudioPlaylistEvent {
  final AudioPlaylistModel playlist;

  const UpdatePlaylistEvent(this.playlist);

  @override
  List<Object> get props => [playlist];
}

class DeletePlaylistEvent extends AudioPlaylistEvent {
  final AudioPlaylistModel playlist;

  const DeletePlaylistEvent(this.playlist);

  @override
  List<Object> get props => [playlist];
}

class AddAudioToPlaylistEvent extends AudioPlaylistEvent {
  final AudioPlaylistModel playlist;
  final AudioModel audio;

  const AddAudioToPlaylistEvent(this.playlist, this.audio);

  @override
  List<Object> get props => [playlist, audio];
}

class RemoveAudioFromPlaylistEvent extends AudioPlaylistEvent {
  final AudioPlaylistModel playlist;
  final AudioModel audio;

  const RemoveAudioFromPlaylistEvent(this.playlist, this.audio);

  @override
  List<Object> get props => [playlist, audio];
}
