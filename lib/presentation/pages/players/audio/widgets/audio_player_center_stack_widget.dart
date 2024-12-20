import 'package:flutter/material.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_custom_volume_box.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_gesture_detectors_boxes.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_seeking_position_box_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_thumbnail_card_widget.dart';

import 'audio_player_lyrics_box_widget.dart';

class AudioPlayerCenterStackWidget extends StatelessWidget {
  const AudioPlayerCenterStackWidget({super.key, required this.showLyrics});

  final ValueNotifier<bool> showLyrics;

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);
    return Positioned(
      top: mq.height * 0.16,
      height: mq.height * 0.45,
      width: mq.width,
      child: Stack(
        children: [
          //-------- Thumbnail Card --------//
          const AudioPlayerThumbnailCardWidget(),

          //----     -- Gesture Detectors
          const AudioPlayerGestureDetectorsBoxes(),

          //----------- Lyrics Box
          if (showLyrics.value) AudioPlayerLyricsBoxWidget(),

          ///-----Custom Volume Box Widget
          AudioPlayerCustomVolumeBoxWidget(),

          //------- Seeking  Position
          const AudioPlayerSeekingPositionBoxWidget(),
        ],
      ),
    );
  }
}
