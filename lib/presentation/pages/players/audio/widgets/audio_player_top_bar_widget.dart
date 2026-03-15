import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_add_to_playlist_button_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_equalizer_button_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_more_button.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_pitch_changer_button_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_speed_changer_button_widget.dart';
import 'package:velocity_x/velocity_x.dart';


class AudioPlayerTopBarWidget extends StatelessWidget {
  const AudioPlayerTopBarWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);
    return Container(
      margin: EdgeInsets.only(top: mq.height * 0.05),
      // color: Colors.amber,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //--- Back Button ---///
          _BackButton(),
          const Spacer(),

          //--- More Button ---///
          AudioPlayerMoreButton(
            onPressed: () {
              //-------- Show Slide Dialog
              VxDialog.showCustom(
                context,
                child: SlideInRight(
                  child: Container(
                    height: 300,
                    width: mq.width * 0.25,
                    alignment: Alignment.center,
                    child: [
                      //----- Add to Playlist
                      AudioPlayerAddToPlaylistButtonWidget(),

                      //------- Equalizer
                      AudioPlayerEqualizerButtonWidget(),

                      //------- Speed Changer
                      AudioPlayerSpeedChangerButtonWidget(),

                      //----- Pitch Changer
                      AudioPlayerPitchChangerButtonWidget(),
                    ]
                        .column(
                          alignment: MainAxisAlignment.center,
                        )
                        .scrollVertical(),
                  ).glassMorphic().pOnly(left: mq.width * 0.75),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

//---- Back Button
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.pop();
      },
      color: Colors.white,
      iconSize: 30,
      tooltip: "Back",
      icon: const Icon(HugeIcons.strokeRoundedArrowDown01),
    );
  }
}
