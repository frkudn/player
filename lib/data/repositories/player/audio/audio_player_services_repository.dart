import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:color_log/color_log.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../logic/audio_player_bloc/audio_player_bloc.dart';
import '../../../models/audioplayercombinedstream_model.dart';

abstract class AudioPlayerServicesRepository {
  Future<void> playPauseAudio();
  Future<void> initializeEvent(
      Emitter<AudioPlayerState> emit, AudioPlayerInitializeEvent event);
  Future<void> nextEvent(
      Emitter<AudioPlayerState> emit, AudioPlayerNextEvent event);
  Future<void> previousEvent(
      Emitter<AudioPlayerState> emit, AudioPlayerPreviousEvent event);
  Future<void> seekEvent(
      Emitter<AudioPlayerState> emit, AudioPlayerSeekEvent event);

  // Add these recommended methods
  // Future<void> dispose();
  // Future<void> setVolume(double volume);
  // Future<void> setSpeed(double speed);
  // Stream<Duration?> get positionStream;
  // Stream<Duration?> get bufferedPositionStream;
}

final class AudioPlayerServices implements AudioPlayerServicesRepository {
  AudioPlayerServices({required this.audioPlayer});

  final AudioPlayer audioPlayer;

  @override
  Future<void> initializeEvent(
      Emitter<AudioPlayerState> emit, AudioPlayerInitializeEvent event) async {
    try {
      emit(AudioPlayerLoadingState());

      final playlist = ConcatenatingAudioSource(
        children: event.audioList.map((audio) {
          return ProgressiveAudioSource(
            Uri.file(audio.path),
            tag: MediaItem(
              id:  audio.title, // Use a unique ID if available
              album:  'Unknown Album',
              title: audio.title,
              artist:  'Unknown Artist',
              duration: audioPlayer.duration, // Add if available
              artUri:  null,
              playable: true,
            
            ),
          );
        }).toList(),
      );

      // Add error handling for setAudioSource
       audioPlayer
          .setAudioSource(
        playlist,
        initialIndex: event.initialMediaIndex,
        initialPosition: Duration.zero,
      )
          .catchError((error) {
         clog.error('Error loading audio source: $error');
      });

      // Create a more robust combined stream with error handling
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
            return AudioPlayerCombinedStream(
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
        audioPlayerCombinedStream: combinedStream,
        isSeeking: false,
        seekingPosition: 0,
      ));

      await audioPlayer.play();
    } catch (e) {
      emit(AudioPlayerErrorState(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> playPauseAudio() async {
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
  Future<void> nextEvent(
      Emitter<AudioPlayerState> emit, AudioPlayerNextEvent event) async {
    try {
      if (await audioPlayer.hasNext) {
        await audioPlayer.seekToNext();
      }
    } catch (e) {
      clog.error('Error seeking to next track: $e');
    }
  }

  @override
  Future<void> previousEvent(
      Emitter<AudioPlayerState> emit, AudioPlayerPreviousEvent event) async {
    try {
      if (await audioPlayer.hasPrevious) {
        await audioPlayer.seekToPrevious();
      }
    } catch (e) {
      clog.error('Error seeking to previous track: $e');
    }
  }

  @override
  Future<void> seekEvent(
      Emitter<AudioPlayerState> emit, AudioPlayerSeekEvent event) async {
    try {
      await audioPlayer.seek(Duration(seconds: event.position.toInt()));
    } catch (e) {
      clog.error('Error seeking to position: $e');
    }
  }

  // Add dispose method to clean up resources
  @override
  Future<void> dispose() async {
    await audioPlayer.dispose();
  }
  

}
