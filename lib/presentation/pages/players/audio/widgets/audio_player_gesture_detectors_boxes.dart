import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/logic/audio_player_bloc/audio_player_bloc.dart';
import 'package:open_player/logic/volume_cubit/volume_cubit.dart';

class AudioPlayerGestureDetectorsBoxes extends StatelessWidget {
  const AudioPlayerGestureDetectorsBoxes({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left box (1 part)
        Expanded(
          flex: 1,
          child: GestureDetector(
            onDoubleTap: () {
              context.read<AudioPlayerBloc>().add(AudioPlayerBackwardEvent());
            },
            onVerticalDragUpdate: (details) {
              context
                  .read<VolumeCubit>()
                  .changeAudioPlayerVolume(details: details);
              context.read<VolumeCubit>().volumeBoxVisibilityToggle();
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        // Center box (2 parts)
        Expanded(
          flex: 2,
          child: GestureDetector(
            onDoubleTap: () {
              context
                  .read<AudioPlayerBloc>()
                  .add(AudioPlayerPlayPauseToggleEvent());
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        // Right box (1 part)
        Expanded(
          flex: 1,
          child: GestureDetector(
            onDoubleTap: () {
              context.read<AudioPlayerBloc>().add(AudioPlayerForwardEvent());
            },
            onVerticalDragUpdate: (details) {
              context
                  .read<VolumeCubit>()
                  .changeAudioPlayerVolume(details: details);
              context.read<VolumeCubit>().volumeBoxVisibilityToggle();
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
