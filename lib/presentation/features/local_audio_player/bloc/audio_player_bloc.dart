import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../base/di/dependency_injection.dart';
import '../../../../data/models/audio_model.dart';
import '../../../../data/models/audioplayercombinedstream_model.dart';
import '../../../../data/services/audio/audio_player_services.dart';
part 'audio_player_event.dart';
part 'audio_player_state.dart';

class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  final AudioPlayer audioPlayer = getIt.get<AudioPlayer>();
  final AudioPlayerService audioServices = getIt.get<AudioPlayerService>();
  AudioPlayerBloc() : super(AudioPlayerInitialState()) {
    on<AudioPlayerInitializeEvent>(_audioPlayerInitializeEvent);
    on<AudioPlayerPlayPauseToggleEvent>(_audioPlayerPauseToggle);
    on<AudioPlayerNextEvent>(_audioPlayerNextEvent);
    on<AudioPlayerPreviousEvent>(_audioPlayerPreviousEvent);
    on<AudioPlayerSeekEvent>(_audioPlayerSeekEvent);
    on<AudioPlayerIsSeekingToggleEvent>(_audioPlayerIsSeekingToggleEvent);
    on<AudioPlayerShuffleEvent>(_audioPlayerShuffleEvent);
    on<AudioPlayerRepeatToggleEvent>(_audioPlayerRepeatToggleEvent);
    on<AudioPlayerForwardEvent>(_audioPlayerForwardEvent);
    on<AudioPlayerBackwardEvent>(_audioPlayerBackwardEvent);
    on<AudioPlayerStopEvent>(_audioPlayerStopEvent);
    on<AudioPlayerDisposeEvent>(_audioPlayerDispose);
    on<AudioPlayerChangeSpeedEvent>(_audioPlayerChangeSpeedEvent);
    on<AudioPlayerChangePitchEvent>(_audioPlayerChangePitchEvent);
  }

  /// Method to handle MusicPlayerInitializeEvent and Play Audio.
  FutureOr<void> _audioPlayerInitializeEvent(
      AudioPlayerInitializeEvent event, Emitter<AudioPlayerState> emit) async {
    audioServices.initializePlayer(emit, event);
  }

  /// Method to handle  Play And Pause Audio.
  FutureOr<void> _audioPlayerPauseToggle(
      AudioPlayerPlayPauseToggleEvent event, Emitter<AudioPlayerState> emit) {
    audioServices.playPauseTrack();
  }

  FutureOr<void> _audioPlayerNextEvent(
      AudioPlayerNextEvent event, Emitter<AudioPlayerState> emit) {
    audioServices.playNextTrack(emit, event);
  }

  FutureOr<void> _audioPlayerPreviousEvent(
      AudioPlayerPreviousEvent event, Emitter<AudioPlayerState> emit) {
    audioServices.playPreviousTrack(emit, event);
  }

  FutureOr<void> _audioPlayerSeekEvent(
      AudioPlayerSeekEvent event, Emitter<AudioPlayerState> emit) {
    audioServices.seekToPosition(emit, event);
  }

  FutureOr<void> _audioPlayerIsSeekingToggleEvent(
      AudioPlayerIsSeekingToggleEvent event, Emitter<AudioPlayerState> emit) {
    final double position = event.position;
    final bool isSeeking = event.isSeeking;
    emit(event.state.copyWith(isSeeking: isSeeking, seekingPosition: position));
  }

  FutureOr<void> _audioPlayerShuffleEvent(
      AudioPlayerShuffleEvent event, Emitter<AudioPlayerState> emit) async {
    bool isShufle = !audioPlayer.shuffleModeEnabled;
    await audioPlayer.setShuffleModeEnabled(isShufle);
  }

  FutureOr<void> _audioPlayerRepeatToggleEvent(
      AudioPlayerRepeatToggleEvent event,
      Emitter<AudioPlayerState> emit) async {
    LoopMode loop = audioPlayer.loopMode;
    if (loop == LoopMode.all) {
      await audioPlayer.setLoopMode(LoopMode.one);
    }

    if (loop == LoopMode.one) {
      await audioPlayer.setLoopMode(LoopMode.off);
    }
    if (loop == LoopMode.off) {
      await audioPlayer.setLoopMode(LoopMode.all);
    }
  }

  FutureOr<void> _audioPlayerForwardEvent(
      AudioPlayerForwardEvent event, Emitter<AudioPlayerState> emit) async {
    final position = audioPlayer.position.inSeconds;
    if (position + 10 < audioPlayer.duration!.inSeconds) {
      await audioPlayer.seek(
        Duration(seconds: position + 10),
      );
    }
  }

  FutureOr<void> _audioPlayerBackwardEvent(
      AudioPlayerBackwardEvent event, Emitter<AudioPlayerState> emit) async {
    final position = audioPlayer.position.inSeconds;
    if (position - 10 > 0) {
      await audioPlayer.seek(
        Duration(seconds: position - 10),
      );
    }
  }

  FutureOr<void> _audioPlayerStopEvent(
      AudioPlayerStopEvent event, Emitter<AudioPlayerState> emit) async {
    await audioPlayer.stop();
  }

  FutureOr<void> _audioPlayerChangeSpeedEvent(
      AudioPlayerChangeSpeedEvent event, Emitter<AudioPlayerState> emit) async {
    audioServices.changeSpeed(emit, event);
  }

  FutureOr<void> _audioPlayerChangePitchEvent(
      AudioPlayerChangePitchEvent event, Emitter<AudioPlayerState> emit) async {
    audioServices.changePitch(emit, event);
  }

  FutureOr<void> _audioPlayerDispose(
      AudioPlayerDisposeEvent event, Emitter<AudioPlayerState> emit) async {
    await audioPlayer.dispose();
  }
}
