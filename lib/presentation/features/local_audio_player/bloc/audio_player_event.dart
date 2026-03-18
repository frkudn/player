part of 'audio_player_bloc.dart';

sealed class AudioPlayerEvent extends Equatable {
  const AudioPlayerEvent();
}

class AudioPlayerInitializeEvent extends AudioPlayerEvent {
  const AudioPlayerInitializeEvent(
      {required this.initialMediaIndex, required this.audioList});
  final int initialMediaIndex;
  final List<AudioModel> audioList;

  @override
  List<Object?> get props => [initialMediaIndex, audioList];
}

class AudioPlayerPlayPauseToggleEvent extends AudioPlayerEvent {
  @override
  List<Object?> get props => [];
}

class AudioPlayerStopEvent extends AudioPlayerEvent {
  @override
  List<Object?> get props => [];
}

class AudioPlayerForwardEvent extends AudioPlayerEvent {
  @override
  List<Object?> get props => [];
}

class AudioPlayerBackwardEvent extends AudioPlayerEvent {
  @override
  List<Object?> get props => [];
}

class AudioPlayerRepeatToggleEvent extends AudioPlayerEvent {
  @override
  List<Object?> get props => [];
}

class AudioPlayerShuffleEvent extends AudioPlayerEvent {
  @override
  List<Object?> get props => [];
}

class AudioPlayerSeekEvent extends AudioPlayerEvent {
  const AudioPlayerSeekEvent({required this.position});

  final double position;
  @override
  List<Object?> get props => [position];
}

class AudioPlayerNextEvent extends AudioPlayerEvent {
  @override
  List<Object?> get props => [];
}

class AudioPlayerPreviousEvent extends AudioPlayerEvent {
  @override
  List<Object?> get props => [];
}

class AudioPlayerChangeSpeedEvent extends AudioPlayerEvent {
  const AudioPlayerChangeSpeedEvent({required this.value});
  final double value;

  @override
  List<Object?> get props => [value];
}

class AudioPlayerChangePitchEvent extends AudioPlayerEvent {
  const AudioPlayerChangePitchEvent({required this.value});
  final double value;

  @override
  List<Object?> get props => [value];
}

class AudioPlayerDisposeEvent extends AudioPlayerEvent {
  @override
  List<Object?> get props => [];
}

class AudioPlayerIsSeekingToggleEvent extends AudioPlayerEvent {
  final double position;
  final bool isSeeking;
  final AudioPlayerSuccessState state;

  const AudioPlayerIsSeekingToggleEvent(
      {required this.position, required this.isSeeking, required this.state});
  @override
  List<Object?> get props => [position, isSeeking, state];
}
