import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:open_player/presentation/shared/widgets/animated_auto_scroll_text_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_next_button_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_position_and_duration_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_previous_button_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_seek_bar_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_thumbnail_card_widget.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../../base/assets/fonts/styles.dart';
import '../../../features/local_audio_player/bloc/audio_player_bloc.dart';
import '../../../../utils/formater.dart';
import '../nothing_widget.dart';
import '../../../features/local_audio_player/view/audio_player.dart';
import '../../../features/local_audio_player/widgets/audio_player_play_pause_button_widget.dart';

class MiniAudioPlayerWidget extends StatelessWidget {
  const MiniAudioPlayerWidget(
      {super.key, this.height, this.color, this.shadowColor});
  final double? height;
  final Color? color;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);
    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (state) => state is AudioPlayerSuccessState ? state : null,
      builder: (context, playerState) {
        if (playerState == null) return nothing;
        return FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: SizedBox(
            height: height ?? mq.height * 0.163,
            width: mq.width,
            child: StreamBuilder(
                stream: playerState.audioPlayerCombinedStream,
                builder: (context, snapshot) {
                  int? currentIndex = snapshot.data?.currentIndex ??
                      playerState.audioPlayer.currentIndex;
                  String title = currentIndex != null
                      ? playerState.audios[currentIndex].title
                      : "...";
                  return GestureDetector(
                    onTap: () {
                      ///!-----Show Player Screen ----///
                      showModalBottomSheet(
                        showDragHandle: false,
                        isScrollControlled: true,
                        context: context,
                        builder: (context) => const AudioPlayerPage(),
                      );
                    },
                    child: Card(
                      color: color ?? Theme.of(context).colorScheme.primary,
                      shadowColor: shadowColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(0),
                      )),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              //-------- Upper Section ---------///
                              Row(
                                children: [
                                  //----- Thumbnail ----------//
                                  if (!playerState.isSeeking)
                                    AudioPlayerThumbnailCardWidget(
                                      horizontalPadding: 0,
                                      height: mq.height * 0.05,
                                      width: mq.height * 0.05,
                                      borderRadius: BorderRadius.circular(5),
                                    ),

                                  ///------------ Seeking Position --------//
                                  if (playerState.isSeeking)
                                    CircleAvatar(
                                      radius: 23,
                                      child: Text(
                                        Formatter.formatDuration(
                                          Duration(
                                            seconds: playerState.seekingPosition
                                                .toInt(),
                                          ),
                                        ),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.white),
                                      ),
                                    ),

                                  const Gap(10),

                                  ///--------------- Music Title ------------------//
                                  Expanded(
                                    child: AnimatedAutoScrollTextWidget(
                                      title,
                                      style: const TextStyle(
                                        fontFamily: AppFonts.poppins,
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),

                                  ///------------- Buttons Row -------------///
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const AudioPlayerPreviousButtonWidget(),
                                      AudioPlayerPlayPauseButtonWidget(
                                        iconSize: 30,
                                        pauseIcon: CupertinoIcons.pause_circle,
                                        playIcon: CupertinoIcons.play_circle,
                                      ),
                                      const AudioPlayerNextButtonWidget(),
                                    ],
                                  )
                                ],
                              ),

                              //--------- Bottom Section
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Row(
                                  children: [
                                    //------ Position
                                    AudioPlayerPositionAndDurationWidget(
                                      showDuration: false,
                                      enablePadding: false,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),

                                    //----------- Slider
                                    Flexible(
                                      child: AudioPlayerSeekBarWidget(
                                        enabledThumbRadius: 6,
                                        activeTrackColor: Colors.white,
                                        thumbColor: Colors.white,
                                      ),
                                    ),

                                    //------- Duration
                                    AudioPlayerPositionAndDurationWidget(
                                      showPosition: false,
                                      enablePadding: false,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
          ).glassMorphic(
              borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          )),
        );
      },
    );
  }
}
