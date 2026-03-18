import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:color_log/color_log.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_player/data/models/custom_audio_source_model.dart';
import 'package:rxdart/rxdart.dart';

import '../../../presentation/features/local_audio_player/bloc/audio_player_bloc.dart';
import '../../models/audioplayercombinedstream_model.dart';

abstract class AudioPlayerServiceBase {
  Future<void> playPauseTrack();
  Future<void> initializePlayer(
      Emitter<AudioPlayerState> emit, AudioPlayerInitializeEvent event);
  Future<void> playNextTrack(
      Emitter<AudioPlayerState> emit, AudioPlayerNextEvent event);
  Future<void> playPreviousTrack(
      Emitter<AudioPlayerState> emit, AudioPlayerPreviousEvent event);
  Future<void> seekToPosition(
      Emitter<AudioPlayerState> emit, AudioPlayerSeekEvent event);

  Future<void> changeSpeed(
      Emitter<AudioPlayerState> emit, AudioPlayerChangeSpeedEvent event);

  Future<void> changePitch(
      Emitter<AudioPlayerState> emit, AudioPlayerChangePitchEvent event);
}

final class AudioPlayerService implements AudioPlayerServiceBase {
  AudioPlayerService({required this.audioPlayer});

  final AudioPlayer audioPlayer;

  @override
  Future<void> initializePlayer(
      Emitter<AudioPlayerState> emit, AudioPlayerInitializeEvent event) async {
    try {
      emit(AudioPlayerLoadingState());

      final audiosource = CustomAudioSource.createPlaylist(event.audioList);

      // Add error handling for setAudioSource
      audioPlayer
          .setAudioSource(
        audiosource,
        initialIndex: event.initialMediaIndex,
        initialPosition: Duration.zero,
      )
          .catchError((error) {
        clog.error('Error loading audio source: $error');
        emit(AudioPlayerErrorState(errorMessage: error.toString()));
        return error;
      });

      // Create a robust combined stream with error handling
      final combinedStream = Rx.combineLatestList([
        audioPlayer.playingStream,
        audioPlayer.positionStream,
        audioPlayer.durationStream,
        audioPlayer.bufferedPositionStream,
        audioPlayer.processingStateStream,
        audioPlayer.speedStream,
        audioPlayer.loopModeStream,
        audioPlayer.shuffleModeEnabledStream,
        audioPlayer.currentIndexStream,
      ])
          .map((values) {
            return AudioPlayerStreamCombiner(
              playing: values[0] as bool,
              position: values[1] as Duration,
              duration: values[2] as Duration?,
              bufferedPosition: values[3] as Duration,
              processingState: values[4] as ProcessingState,
              speed: values[5] as double,
              loopMode: values[6] as LoopMode,
              shuffleModeEnabled: values[7] as bool,
              currentIndex: values[8] as int?,
            );
          })
          .handleError((error) {
            emit(AudioPlayerErrorState(errorMessage: error.toString()));
          })
          .publish()
          .autoConnect();

      emit(AudioPlayerSuccessState(
        audioPlayer: audioPlayer,
        audiosource: audiosource,
        audios: event.audioList,
        audioPlayerCombinedStream: combinedStream,
        isSeeking: false,
        seekingPosition: 0,
      ));

      audioPlayer.play();
    } catch (e) {
      emit(AudioPlayerErrorState(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> playPauseTrack() async {
    try {
      if (audioPlayer.playing) {
        await audioPlayer.pause();
      } else {
        await audioPlayer.play();
      }
    } catch (e) {
      clog.error('Error toggling playback: $e');
    }
  }

  @override
  Future<void> playNextTrack(
      Emitter<AudioPlayerState> emit, AudioPlayerNextEvent event) async {
    try {
      if (audioPlayer.hasNext) {
        await audioPlayer.seekToNext();
      }
    } catch (e) {
      clog.error('Error seeking to next track: $e');
    }
  }

  @override
  Future<void> playPreviousTrack(
      Emitter<AudioPlayerState> emit, AudioPlayerPreviousEvent event) async {
    try {
      if (audioPlayer.hasPrevious) {
        await audioPlayer.seekToPrevious();
      }
    } catch (e) {
      clog.error('Error seeking to previous track: $e');
    }
  }

  @override
  Future<void> seekToPosition(
      Emitter<AudioPlayerState> emit, AudioPlayerSeekEvent event) async {
    try {
      await audioPlayer.seek(Duration(seconds: event.position.toInt()));
    } catch (e) {
      clog.error('Error seeking to position: $e');
    }
  }

  @override
  Future<void> changeSpeed(
      Emitter<AudioPlayerState> emit, AudioPlayerChangeSpeedEvent event) async {
    try {
      await audioPlayer.setSpeed(event.value);
      clog.debug("Speed : ${event.value}");
    } catch (e) {
      clog.error('Error audio player speed change: $e');
    }
  }
  
  @override
  Future<void> changePitch(Emitter<AudioPlayerState> emit, AudioPlayerChangePitchEvent event) async{
    try {
      await audioPlayer.setPitch(event.value);
      clog.debug("Pitch : ${event.value}");
    } catch (e) {
      clog.error('Error audio player pitch change: $e');
    }
  }
}
