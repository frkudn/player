part of 'audio_playlist_bloc.dart';

// States
class AudioPlaylistState extends Equatable {
  final List<AudioPlaylistModel> playlists;
  final PlaylistStatus status;
  final String? errorMessage;

  const AudioPlaylistState({
    this.playlists = const [],
    this.status = PlaylistStatus.initial,
    this.errorMessage,
  });

  AudioPlaylistState copyWith({
    List<AudioPlaylistModel>? playlists,
    PlaylistStatus? status,
    String? errorMessage,
  }) {
    return AudioPlaylistState(
      playlists: playlists ?? this.playlists,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [playlists, status, errorMessage];
}

enum PlaylistStatus {
  initial,
  loading,
  loaded,
  error,
  creating,
  updating,
  deleting
}
