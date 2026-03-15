import 'package:color_log/color_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/logic/audio_player_bloc/audio_player_bloc.dart';

class AudioPlayerPreviousButtonWidget extends StatelessWidget {
  const AudioPlayerPreviousButtonWidget({super.key, this.iconSize});

  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AudioPlayerBloc, AudioPlayerState, bool?>(
      selector: (state) {
        return state is AudioPlayerSuccessState? state.audioPlayer.hasPrevious:null;
      },
      builder: (context, state) {
        return IconButton(
          onPressed: () {
            clog.debug("Previous Button is pressed");
            context.read<AudioPlayerBloc>().add(AudioPlayerPreviousEvent());
          },
          color:state!= null?state == true?  Colors.white:Colors.grey:Colors.white,
          iconSize: iconSize ?? 25,
          icon: const Icon(HugeIcons.strokeRoundedPrevious),
        );
      },
    );
  }
}
