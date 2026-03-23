import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_lyrics_button_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_actions_buttons_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_background_blur_image_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_center_stack_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_position_and_duration_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_seek_bar_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_title_artist_favorite_button_row_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_top_bar_widget.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import 'package:open_player/utils/responsive.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUDIO PLAYER PAGE
//
// Reads ThemeState.playerStyleIndex and delegates to one of 3 layouts.
// All 3 layouts reuse the same existing sub-widgets — only positioning differs.
//
//   0 = Classic    — thumbnail top, glassmorphic controls container bottom
//                    (original design, unchanged)
//   1 = Minimal    — album art fills full screen, controls overlaid at bottom
//                    as a translucent strip (feels more immersive)
//   2 = Immersive  — same as Minimal but controls are ultra-compact + no glass
//                    container, everything transparent directly over the art
// ─────────────────────────────────────────────────────────────────────────────

class AudioPlayerPage extends HookWidget {
  const AudioPlayerPage({super.key});

  static const double _kMaxPlayerWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    final showLyrics = useState(false);

    // Read playerStyleIndex — only rebuild when this field changes
    final int styleIndex = context.select<ThemeCubit, int>(
      (c) => c.state.playerStyleIndex,
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final Size mq = MediaQuery.sizeOf(context);
          final bool isWide = context.isTabletOrLarger;
          final double screenWidth = constraints.maxWidth;

          // Player width and offset used by Classic style
          // (Minimal and Immersive are full-width so they don't need this)
          final double playerWidth = isWide
              ? screenWidth.clamp(0.0, _kMaxPlayerWidth)
              : screenWidth * 0.88;
          final double leftOffset = (screenWidth - playerWidth) / 2;

          switch (styleIndex) {
            case 1:
              return _MinimalLayout(
                showLyrics: showLyrics,
                mq: mq,
                screenWidth: screenWidth,
              );
            case 2:
              return _ImmersiveLayout(
                showLyrics: showLyrics,
                mq: mq,
                screenWidth: screenWidth,
              );
            default:
              // Style 0 — Classic (original design)
              return _ClassicLayout(
                showLyrics: showLyrics,
                mq: mq,
                playerWidth: playerWidth,
                leftOffset: leftOffset,
              );
          }
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LAYOUT 0 — CLASSIC
//
// Original design: thumbnail in center, glassmorphic controls card at bottom.
// Responsive: playerWidth + leftOffset keep it centered on tablets.
// ═══════════════════════════════════════════════════════════════════════════

class _ClassicLayout extends StatelessWidget {
  const _ClassicLayout({
    required this.showLyrics,
    required this.mq,
    required this.playerWidth,
    required this.leftOffset,
  });

  final ValueNotifier<bool> showLyrics;
  final Size mq;
  final double playerWidth;
  final double leftOffset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred album art background (with optional flowing animation)
        const AudioPlayerBackgroundBlurImageWidget(),

        // Back button + more menu (speed, pitch, sleep timer, etc.)
        const AudioPlayerTopBarWidget(),

        // Thumbnail + gesture zones + lyrics overlay + volume indicator
        AudioPlayerCenterStackWidget(
          showLyrics: showLyrics,
          playerWidth: playerWidth,
          leftOffset: leftOffset,
        ),

        // Glassmorphic controls container
        [
          AudioPlayerTitleArtistFavoriteButtonAudioQualityBadgeRowWidget(),
          AudioPlayerSeekBarWidget(
            enableTrackHeightOnSeeking: true,
            trackHeight: 18,
            activeTrackColor: Colors.white,
            thumbColor: Colors.white,
            overlayColor: Colors.transparent,
          ),
          AudioPlayerPositionAndDurationWidget(),
          AudioPlayerActionsButtonsWidget(),
        ]
            .column()
            .scrollVertical()
            .pSymmetric(h: playerWidth * 0.02)
            .glassMorphic(blur: 15)
            .positioned(
              bottom: mq.height * 0.06,
              height: mq.height * 0.3,
              width: playerWidth,
              left: leftOffset,
            ),

        // Show / hide lyrics toggle at the very bottom
        AudioPlayerLyricsButtonWidget(showLyrics: showLyrics),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LAYOUT 1 — MINIMAL
//
// Album art fills the full screen as the hero element.
// The center stack (thumbnail) is full-width and full-height.
// Controls sit in a semi-transparent blurred strip anchored to the bottom.
// No hard card edges — feels like the music is the UI.
// ═══════════════════════════════════════════════════════════════════════════

class _MinimalLayout extends StatelessWidget {
  const _MinimalLayout({
    required this.showLyrics,
    required this.mq,
    required this.screenWidth,
  });

  final ValueNotifier<bool> showLyrics;
  final Size mq;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background blur
        const AudioPlayerBackgroundBlurImageWidget(),

        // Full-screen thumbnail — left:0, right:0, no insets
        // horizontalPadding:0 removes the internal padding from the widget
        AudioPlayerCenterStackWidget(
          showLyrics: showLyrics,
          playerWidth: screenWidth, // full width
          leftOffset: 0, // no horizontal offset
        ),

        // Top bar floats over the art
        const AudioPlayerTopBarWidget(),

        // Controls overlay — frosted strip at the bottom
        // Uses glassMorphic so it reads over any album art colour
        [
          AudioPlayerTitleArtistFavoriteButtonAudioQualityBadgeRowWidget(),
          AudioPlayerSeekBarWidget(
            enableTrackHeightOnSeeking: true,
            trackHeight: 14,
            activeTrackColor: Colors.white,
            thumbColor: Colors.white,
            overlayColor: Colors.transparent,
          ),
          AudioPlayerPositionAndDurationWidget(),
          AudioPlayerActionsButtonsWidget(),
        ]
            .column()
            .scrollVertical()
            .pSymmetric(h: mq.width * 0.04)
            .glassMorphic(blur: 20)
            .positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: mq.height * 0.32,
            ),

        AudioPlayerLyricsButtonWidget(showLyrics: showLyrics),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LAYOUT 2 — IMMERSIVE
//
// Edge-to-edge album art. No glass container at all — controls are
// rendered directly on top of the art with white text and shadow only.
// The seek bar, title, and buttons float over the image.
// Maximum screen used for the album art — feels like a concert screen.
// ═══════════════════════════════════════════════════════════════════════════

class _ImmersiveLayout extends StatelessWidget {
  const _ImmersiveLayout({
    required this.showLyrics,
    required this.mq,
    required this.screenWidth,
  });

  final ValueNotifier<bool> showLyrics;
  final Size mq;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-screen blurred background
        const AudioPlayerBackgroundBlurImageWidget(),

        // Full-screen thumbnail (edge-to-edge, no padding)
        AudioPlayerCenterStackWidget(
          showLyrics: showLyrics,
          playerWidth: screenWidth,
          leftOffset: 0,
        ),

        // Top bar — back button + more menu — floats over the art
        const AudioPlayerTopBarWidget(),

        // Thin dark gradient scrim at the bottom so controls are readable
        // over any album art colour without a glass container
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: mq.height * 0.38,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xCC000000), // semi-transparent black scrim
                ],
              ),
            ),
          ),
        ),

        // Controls float directly over the scrim — no glass card
        Positioned(
          bottom: mq.height * 0.04,
          left: mq.width * 0.04,
          right: mq.width * 0.04,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AudioPlayerTitleArtistFavoriteButtonAudioQualityBadgeRowWidget(),
              AudioPlayerSeekBarWidget(
                enableTrackHeightOnSeeking: true,
                trackHeight: 12,
                activeTrackColor: Colors.white,
                thumbColor: Colors.white,
                overlayColor: Colors.transparent,
              ),
              AudioPlayerPositionAndDurationWidget(),
              AudioPlayerActionsButtonsWidget(),
            ],
          ),
        ),

        AudioPlayerLyricsButtonWidget(showLyrics: showLyrics),
      ],
    );
  }
}
