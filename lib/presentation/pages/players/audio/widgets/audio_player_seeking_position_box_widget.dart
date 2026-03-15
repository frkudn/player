import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/logic/audio_player_bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/common/widgets/nothing_widget.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../../../utils/formater.dart';

class AudioPlayerSeekingPositionBoxWidget extends StatelessWidget {
  const AudioPlayerSeekingPositionBoxWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);
    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (state) {
        return state is AudioPlayerSuccessState ? state : null;
      },
      builder: (context, state) {
        if (state == null) return nothing;

        return Visibility(
          visible: state.isSeeking,
          child: SizedBox(
            height: mq.width * 0.2,
            width: mq.width * 0.2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Formatter.formatDuration(
                            Duration(seconds: state.seekingPosition.toInt()))
                        .text
                        .white
                        .size(18).shadow(0, 0, 2, Colors.black)
                        .make(),
                   
                    const Icon(
                      HugeIcons.strokeRoundedScrollHorizontal,
                      color: Colors.white,
                    )
                  ],
                ),
              ),
            ),
          ),
        ).glassMorphic(blur: 20,border: Border.all(color: Colors.white38)).centered();
      },
    );
  }
}
