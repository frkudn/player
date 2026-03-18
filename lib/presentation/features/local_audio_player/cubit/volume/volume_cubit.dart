import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:volume_controller/volume_controller.dart';

part 'volume_state.dart';

class VolumeCubit extends Cubit<VolumeState> {
  Timer? _timer;
  final AudioPlayer audioPlayer;

  VolumeCubit({
    required this.audioPlayer,
  }) : super(VolumeState.initial());

  // Adjust the audio player volume based on user interaction
  FutureOr<void> changeAudioPlayerVolume(
      {required DragUpdateDetails details}) async {
    double delta = details.primaryDelta! / -350;
    double newVolume = (state.audioPlayerVolume + delta).clamp(0.0, 1.0);

    // Emit the state change only if the volume changes
    if (newVolume != state.audioPlayerVolume) {
      emit(state.copyWith(audioPlayerVolume: newVolume));
      audioPlayer.setVolume(newVolume);
    }
  }

  // Adjust the system volume based on user interaction
  FutureOr<void> changeSystemVolume(
      {required DragUpdateDetails details}) async {
    double delta = details.primaryDelta! / -350;
    double newVolume = (state.systemVolume + delta).clamp(0.0, 1.0);

    // Emit the state change only if the volume changes
    if (newVolume != state.systemVolume) {
      emit(state.copyWith(systemVolume: newVolume));
      // Set the system volume using VolumeController
      VolumeController.instance.setVolume(newVolume);
      
    }
  }

  // Toggles the visibility of the volume control box
  FutureOr<void> volumeBoxVisibilityToggle() {
    emit(state.copyWith(showVolumeBox: true));

    // Reset and restart the timer for hiding the volume control box
    _timer?.cancel();
    _timer = Timer(
      const Duration(seconds: 3),
      () {
        emit(state.copyWith(showVolumeBox: false));
      },
    );
  }
}
