import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/presentation/shared/widgets/nothing_widget.dart';

import '../bloc/audio_player_bloc.dart';
import '../../../../utils/formater.dart';

class AudioPlayerPositionAndDurationWidget extends StatelessWidget {
  const AudioPlayerPositionAndDurationWidget(
      {super.key,
      this.showPosition = true,
      this.showDuration = true,
      this.enablePadding = true,
      this.fontSize,
      this.fontWeight});

  final bool showPosition;
  final bool showDuration;
  final bool enablePadding;
  final double? fontSize;
  final FontWeight? fontWeight;
  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);

    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (state) {
        return state is AudioPlayerSuccessState ? state : null;
      },
      builder: (context, successState) {
        if (successState != null) {
          return StreamBuilder(
              stream: successState.audioPlayerCombinedStream,
              builder: (context, snapshot) {
                Duration position = snapshot.data?.position ??
                    successState.audioPlayer.position;
                Duration duration = snapshot.data?.duration ??
                    successState.audioPlayer.duration ??
                    Duration.zero;

                return Padding(
                  padding: enablePadding
                      ? EdgeInsets.symmetric(
                          horizontal: mq.width * 0.03,
                        )
                      : EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      //---       Position
                      if (showPosition)
                        Text(
                          Formatter.formatDuration(position),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              shadows: [
                                Shadow(
                                    color: Colors.black38,
                                    blurRadius: 2,
                                    offset: Offset(0, 0))
                              ]),
                        ),

                      //--     Duration
                      if (showDuration)
                        Text(
                          Formatter.formatDuration(duration),
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              shadows: [
                                Shadow(
                                    color: Colors.black38,
                                    blurRadius: 2,
                                    offset: Offset(0, 0))
                              ]),
                        ),
                    ],
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
