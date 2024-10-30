import 'package:animate_do/animate_do.dart';
import 'package:color_log/color_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/logic/audio_player_bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/common/nothing_widget.dart';

class AudioPlayerPlayPauseButtonWidget extends StatelessWidget {
  AudioPlayerPlayPauseButtonWidget({
    super.key,
    this.iconSize,
    this.playIcon,
    this.pauseIcon
  });

  double? iconSize;
  IconData? playIcon;
  IconData? pauseIcon;


  @override
  Widget build(BuildContext context) {
    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (state) {
        return state is AudioPlayerSuccessState ? state : null;
      },
      builder: (context, state) {
        if (state != null) {
          return StreamBuilder(
              stream: state.audioPlayerCombinedStream,
              builder: (context, snapshot) {
                bool isPlay = snapshot.data?.playing ?? false;
                return SpinPerfect(
                  animate: state.audioPlayer.playing,
                  duration: const Duration(milliseconds: 500),
                  child: IconButton(
                    onPressed: () {
                      clog.debug("Play Pause Button is pressed");
                      context
                          .read<AudioPlayerBloc>()
                          .add(AudioPlayerPlayPauseToggleEvent());
                    },
                    color: Colors.white,
                    iconSize: iconSize ?? 40,
                    icon: Icon(isPlay
                        ?pauseIcon?? HugeIcons.strokeRoundedPause
                        :playIcon?? HugeIcons.strokeRoundedPlay),
                  ),
                );
              });
        } else {
          return nothing;
        }
      },
    );
  }
}
