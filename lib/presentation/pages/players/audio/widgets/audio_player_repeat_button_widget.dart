import 'package:color_log/color_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_player/logic/audio_player_bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/common/widgets/nothing_widget.dart';

class AudioPlayerRepeatButtonWidget extends StatelessWidget {
  const AudioPlayerRepeatButtonWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AudioPlayerBloc, AudioPlayerState,Stream<LoopMode>?>(
      selector: (state) => state is AudioPlayerSuccessState? state.audioPlayer.loopModeStream:null,
      builder: (context, state) {
        if (state != null) {
          return StreamBuilder(
              stream: state,
              builder: (context, snapshot) {
                LoopMode loopMode = snapshot.data ?? LoopMode.all;
                return IconButton(
                  onPressed: () {
                    clog.debug(" Repeat Button is pressed");
                    context
                        .read<AudioPlayerBloc>()
                        .add(AudioPlayerRepeatToggleEvent());
                  },
                  color: Colors.white,
                  iconSize: 25,
                  icon: Icon(
                    loopMode == LoopMode.all
                        ? HugeIcons.strokeRoundedRepeat
                        : loopMode == LoopMode.one
                            ? HugeIcons.strokeRoundedRepeatOne02
                            : HugeIcons.strokeRoundedRepeatOff,
                  ),
                );
              });
        }
        return nothing;
      },
    );
  }
}
