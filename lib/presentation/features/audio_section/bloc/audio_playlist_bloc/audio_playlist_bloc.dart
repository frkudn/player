import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../data/models/audio_model.dart';
import '../../../../../data/models/audio_playlist_model.dart';
import '../../../../../data/services/audio_playlist_service/audio_playlist_service.dart';

part 'audio_playlist_event.dart';
part 'audio_playlist_state.dart';

// Bloc
class AudioPlaylistBloc extends Bloc<AudioPlaylistEvent, AudioPlaylistState> {
  final AudioPlaylistService _playlistService;

  AudioPlaylistBloc(this._playlistService) : super(const AudioPlaylistState()) {
    // Event Handlers
    on<LoadPlaylistsEvent>(_onLoadPlaylists);
    on<CreatePlaylistEvent>(_onCreatePlaylist);
    on<UpdatePlaylistEvent>(_onUpdatePlaylist);
    on<DeletePlaylistEvent>(_onDeletePlaylist);
    on<AddAudioToPlaylistEvent>(_onAddAudioToPlaylist);
    on<RemoveAudioFromPlaylistEvent>(_onRemoveAudioFromPlaylist);
  }

  // Load Playlists
  Future<void> _onLoadPlaylists(
      LoadPlaylistsEvent event, Emitter<AudioPlaylistState> emit) async {
    emit(state.copyWith(status: PlaylistStatus.loading));
    try {
      final playlists = await _playlistService.getAllPlaylists();
      emit(state.copyWith(status: PlaylistStatus.loaded, playlists: playlists));
    } catch (e) {
      emit(state.copyWith(
          status: PlaylistStatus.error, errorMessage: e.toString()));
    }
  }

  // Create Playlist
  Future<void> _onCreatePlaylist(
      CreatePlaylistEvent event, Emitter<AudioPlaylistState> emit) async {
    emit(state.copyWith(status: PlaylistStatus.creating));
    try {
      await _playlistService.createPlaylist(event.playlist);

      // Reload playlists to ensure consistency
      final updatedPlaylists = await _playlistService.getAllPlaylists();

      emit(state.copyWith(
          status: PlaylistStatus.loaded, playlists: updatedPlaylists));
    } catch (e) {
      emit(state.copyWith(
          status: PlaylistStatus.error, errorMessage: e.toString()));
    }
  }

  // Update Playlist
  Future<void> _onUpdatePlaylist(
      UpdatePlaylistEvent event, Emitter<AudioPlaylistState> emit) async {
    emit(state.copyWith(status: PlaylistStatus.updating));
    try {
      await _playlistService.updatePlaylist(event.playlist);

      // Reload playlists to ensure consistency
      final updatedPlaylists = await _playlistService.getAllPlaylists();

      emit(state.copyWith(
          status: PlaylistStatus.loaded, playlists: updatedPlaylists));
    } catch (e) {
      emit(state.copyWith(
          status: PlaylistStatus.error, errorMessage: e.toString()));
    }
  }

  // Delete Playlist
  Future<void> _onDeletePlaylist(
      DeletePlaylistEvent event, Emitter<AudioPlaylistState> emit) async {
    emit(state.copyWith(status: PlaylistStatus.deleting));
    try {
      await _playlistService.deletePlaylist(event.playlist);

      // Reload playlists to ensure consistency
      final updatedPlaylists = await _playlistService.getAllPlaylists();

      emit(state.copyWith(
          status: PlaylistStatus.loaded, playlists: updatedPlaylists));
    } catch (e) {
      emit(state.copyWith(
          status: PlaylistStatus.error, errorMessage: e.toString()));
    }
  }

  // Add Audio to Playlist
  Future<void> _onAddAudioToPlaylist(
      AddAudioToPlaylistEvent event, Emitter<AudioPlaylistState> emit) async {
    emit(state.copyWith(status: PlaylistStatus.updating));
    try {
      await _playlistService.addAudio(event.playlist, event.audio);

      // Reload playlists to ensure consistency
      final updatedPlaylists = await _playlistService.getAllPlaylists();

      emit(state.copyWith(
          status: PlaylistStatus.loaded, playlists: updatedPlaylists));
    } catch (e) {
      emit(state.copyWith(
          status: PlaylistStatus.error, errorMessage: e.toString()));
    }
  }

  // Remove Audio from Playlist
  Future<void> _onRemoveAudioFromPlaylist(RemoveAudioFromPlaylistEvent event,
      Emitter<AudioPlaylistState> emit) async {
    emit(state.copyWith(status: PlaylistStatus.updating));
    try {
      await _playlistService.removeAudio(event.playlist, event.audio);

      // Reload playlists to ensure consistency
      final updatedPlaylists = await _playlistService.getAllPlaylists();

      emit(state.copyWith(
          status: PlaylistStatus.loaded, playlists: updatedPlaylists));
    } catch (e) {
      emit(state.copyWith(
          status: PlaylistStatus.error, errorMessage: e.toString()));
    }
  }
}
