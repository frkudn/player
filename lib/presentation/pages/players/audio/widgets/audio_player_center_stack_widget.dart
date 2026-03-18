import 'package:flutter/material.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_custom_volume_box.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_gesture_detectors_boxes.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_seeking_position_box_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_thumbnail_card_widget.dart';
import 'audio_player_lyrics_box_widget.dart';

class AudioPlayerCenterStackWidget extends StatelessWidget {
  const AudioPlayerCenterStackWidget({
    super.key,
    required this.showLyrics,
    required this.playerWidth, // 👈 renamed from containerWidth for clarity
    required this.leftOffset, // 👈 replaces left:0/right:0 + Center trick
  });

  final ValueNotifier<bool> showLyrics;

  /// The content width — identical to the glassmorphic container's width.
  final double playerWidth;

  /// The left inset — identical to the glassmorphic container's left edge.
  final double leftOffset;

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);
    final double contentHeight = mq.height * 0.45;

    return Positioned(
      top: mq.height * 0.16,
      // ↓ Use explicit left + width instead of left:0/right:0 + Center.
      //   This guarantees the stack occupies exactly the same horizontal
      //   region as the glassmorphic container — no off-by-one on any screen.
      left: leftOffset,
      width: playerWidth,
      height: contentHeight,
      child: Stack(
        // StackFit.expand forces every non-positioned child (thumbnail,
        // gesture boxes, etc.) to fill the full playerWidth × contentHeight.
        fit: StackFit.expand,
        children: [
          // 👇 horizontalPadding: 0 — the stack is already constrained to
          // playerWidth, so the thumbnail's internal mq.width * 0.05 padding
          // must be zeroed out, otherwise the image sits narrower than the
          // glassmorphic container directly below it.
          const AudioPlayerThumbnailCardWidget(horizontalPadding: 0),

          // Gesture regions (left / centre / right) fill the same box.
          const AudioPlayerGestureDetectorsBoxes(),

          // Lyrics overlay — rendered within the constrained width.
          if (showLyrics.value) AudioPlayerLyricsBoxWidget(),

          // Volume indicator (glassmorphic pill, centred by its own widget).
          AudioPlayerCustomVolumeBoxWidget(),

          // Seeking position indicator (glassmorphic pill, centred).
          const AudioPlayerSeekingPositionBoxWidget(),
        ],
      ),
    );
  }
}
