part of 'audio_player_bloc.dart';

sealed class AudioPlayerState extends Equatable {
  const AudioPlayerState();
}

final class AudioPlayerInitialState extends AudioPlayerState {
  @override
  List<Object?> get props => [];
}

final class AudioPlayerLoadingState extends AudioPlayerState {
  @override
  List<Object?> get props => [];
}

class AudioPlayerSuccessState extends AudioPlayerState {
  const AudioPlayerSuccessState({
    required this.audioPlayer,
    required this.isSeeking,
    required this.seekingPosition,
    required this.audioPlayerCombinedStream,
    required this.audioSource,
    required this.audios,
  });

  final AudioPlayer audioPlayer;
  final List<AudioModel> audios;
  final ConcatenatingAudioSource audioSource;
  final bool isSeeking;
  final double seekingPosition;
  final Stream<AudioPlayerStreamCombiner> audioPlayerCombinedStream;

  @override
  List<Object?> get props => [
        audioPlayer,
        audioSource,
        audioPlayerCombinedStream,
        isSeeking,
        seekingPosition,
        audios,
      ];

  AudioPlayerSuccessState copyWith({
    AudioPlayer? audioPlayer,
    bool? isSeeking,
    double? seekingPosition,
    ConcatenatingAudioSource? playlist,
    Stream<AudioPlayerStreamCombiner>? audioPlayerCombinedStream,
    List<AudioModel>? audios,
  }) {
    return AudioPlayerSuccessState(
      audioPlayer: audioPlayer ?? this.audioPlayer,
      audioSource: playlist ?? audioSource,
      isSeeking: isSeeking ?? this.isSeeking,
      seekingPosition: seekingPosition ?? this.seekingPosition,
      audioPlayerCombinedStream:
          audioPlayerCombinedStream ?? this.audioPlayerCombinedStream,
      audios: audios ?? this.audios,
    );
  }
}

class AudioPlayerErrorState extends AudioPlayerState {
  const AudioPlayerErrorState({required this.errorMessage});

  final String errorMessage;
  @override
  List<Object?> get props => [errorMessage];
}
