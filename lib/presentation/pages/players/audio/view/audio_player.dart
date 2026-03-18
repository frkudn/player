import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_lyrics_button_widget.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_actions_buttons_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_background_blur_image_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_center_stack_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_position_and_duration_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_seek_bar_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_title_artist_favorite_button_row_widget.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_top_bar_widget.dart';

import '../../../../../utils/responsive.dart';

class AudioPlayerPage extends HookWidget {
  const AudioPlayerPage({super.key});

  /// Maximum content width on large screens (tablet / desktop).
  /// Keeps the player feeling compact and readable — not stretched across
  /// an 800-pt tablet canvas.
  static const double _kMaxPlayerWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final showLyrics = useState(false);
    final Size mq = MediaQuery.sizeOf(context);
    final bool isWide = context.isTabletOrLarger; // from ResponsiveContext

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;

          // ── Single source of truth for player width ──────────────────────
          // Mobile  → 88 % of sheet width (original behaviour).
          // Tablet+ → capped at _kMaxPlayerWidth so it never feels stretched.
          final double playerWidth = isWide
              ? screenWidth.clamp(0.0, _kMaxPlayerWidth)
              : screenWidth * 0.88;

          // True horizontal centre — works for any playerWidth / screenWidth.
          final double leftOffset = (screenWidth - playerWidth) / 2;
          // ────────────────────────────────────────────────────────────────

          return Stack(
            children: [
              // ── Background blur ────────────────────────────────────────
              const AudioPlayerBackgroundBlurImageWidget(),

              // ── Top bar ────────────────────────────────────────────────
              const AudioPlayerTopBarWidget(),

              // ── Center stack (thumbnail · gestures · lyrics · volume) ──
              // Receives the identical playerWidth + leftOffset so it aligns
              // pixel-perfectly with the glassmorphic container below.
              AudioPlayerCenterStackWidget(
                showLyrics: showLyrics,
                playerWidth: playerWidth,
                leftOffset: leftOffset,
              ),

              // ── Player glassmorphic container ──────────────────────────
              [
                // Title, artist, favourite, quality badge
                AudioPlayerTitleArtistFavoriteButtonAudioQualityBadgeRowWidget(),

                // Seek bar
                AudioPlayerSeekBarWidget(
                  enableTrackHeightOnSeeking: true,
                  trackHeight: 18,
                  activeTrackColor: Colors.white,
                  thumbColor: Colors.white,
                  overlayColor: Colors.transparent,
                ),

                // Position & duration
                AudioPlayerPositionAndDurationWidget(),

                // Action buttons
                AudioPlayerActionsButtonsWidget(),
              ]
                  .column()
                  .scrollVertical()
                  // Inner horizontal padding relative to playerWidth, not mq.width
                  .pSymmetric(h: playerWidth * 0.02)
                  .glassMorphic(blur: 15)
                  .positioned(
                    bottom: mq.height * 0.06,
                    height: mq.height * 0.3,
                    // ↓ same values as the center stack — guaranteed alignment
                    width: playerWidth,
                    left: leftOffset,
                  ),

              // ── Lyrics toggle button ───────────────────────────────────
              AudioPlayerLyricsButtonWidget(showLyrics: showLyrics),
            ],
          );
        },
      ),
    );
  }
}
