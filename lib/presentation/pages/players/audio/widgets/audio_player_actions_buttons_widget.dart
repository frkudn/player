import 'package:flutter/material.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_next_button_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_play_pause_button_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_previous_button_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_repeat_button_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_suffle_button_widget.dart';

class AudioPlayerActionsButtonsWidget extends StatelessWidget {
  const AudioPlayerActionsButtonsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: mq.width * 0.03, vertical: mq.height * 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AudioPlayerSuffleButtonWidget(),
          const AudioPlayerPreviousButtonWidget(),
          AudioPlayerPlayPauseButtonWidget(),
          const AudioPlayerNextButtonWidget(),
          const AudioPlayerRepeatButtonWidget(),
        ],
      ),
    );
  }
}
