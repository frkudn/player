import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/presentation/features/local_audio_player/bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/features/local_audio_player/view/audio_player.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_next_button_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_play_pause_button_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_position_and_duration_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_previous_button_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_seek_bar_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_thumbnail_card_widget.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import 'package:open_player/presentation/shared/widgets/animated_auto_scroll_text_widget.dart';
import 'package:open_player/presentation/shared/widgets/nothing_widget.dart';
import 'package:open_player/utils/formater.dart';
import 'package:velocity_x/velocity_x.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MINI AUDIO PLAYER WIDGET
//
// Reads ThemeState.miniPlayerStyleIndex to choose between 3 layouts.
// All 3 layouts reuse the same existing sub-widgets — only composition differs.
//
//   0 = Classic   — original glassmorphic card (full controls + seek bar)
//   1 = Compact   — slim pill bar (thumbnail + title + single play button)
//   2 = Artwork   — large artwork card with seek bar and prominent controls
//
// Tapping any style opens the full AudioPlayerPage as a modal bottom sheet —
// identical behavior to the original implementation.
//
// Responsive notes:
//   • All heights are screen-relative (mq.height fractions)
//   • Text uses Flexible/Expanded — never overflows
//   • Images use fixed height — never unbounded
// ─────────────────────────────────────────────────────────────────────────────

class MiniAudioPlayerWidget extends StatelessWidget {
  const MiniAudioPlayerWidget({
    super.key,
    this.height,
    this.color,
    this.shadowColor,
  });

  final double? height;
  final Color? color;
  final Color? shadowColor;

  /// Opens the full-screen player as a bottom sheet.
  static void _openPlayer(BuildContext context) {
    showModalBottomSheet(
      showDragHandle: false,
      isScrollControlled: true,
      context: context,
      builder: (_) => const AudioPlayerPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild when the style index changes — not on every ThemeState emit
    final int styleIndex = context.select<ThemeCubit, int>(
      (c) => c.state.miniPlayerStyleIndex,
    );

    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (s) => s is AudioPlayerSuccessState ? s : null,
      builder: (context, playerState) {
        if (playerState == null) return nothing;

        return FadeInDown(
          duration: const Duration(milliseconds: 400),
          child: switch (styleIndex) {
            1 => _CompactMiniPlayer(
                playerState: playerState,
                color: color,
                shadowColor: shadowColor,
                onTap: () => _openPlayer(context),
              ),
            2 => _ArtworkMiniPlayer(
                playerState: playerState,
                color: color,
                shadowColor: shadowColor,
                onTap: () => _openPlayer(context),
              ),
            _ => _ClassicMiniPlayer(
                playerState: playerState,
                height: height,
                color: color,
                shadowColor: shadowColor,
                onTap: () => _openPlayer(context),
              ),
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STYLE 0 — CLASSIC
//
// Original design: glassmorphic card with thumbnail, scrolling title,
// prev/play/next buttons, and a seek bar at the bottom.
// ═══════════════════════════════════════════════════════════════════════════

class _ClassicMiniPlayer extends StatelessWidget {
  const _ClassicMiniPlayer({
    required this.playerState,
    required this.onTap,
    this.height,
    this.color,
    this.shadowColor,
  });

  final AudioPlayerSuccessState playerState;
  final VoidCallback onTap;
  final double? height;
  final Color? color;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height ?? mq.height * 0.163,
        width: mq.width,
        child: StreamBuilder(
          stream: playerState.audioPlayerCombinedStream,
          builder: (context, snapshot) {
            final int? ci = snapshot.data?.currentIndex ??
                playerState.audioPlayer.currentIndex;
            final String title =
                ci != null ? playerState.audios[ci].title : '...';

            return Container(
              decoration: BoxDecoration(color: Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Upper row: thumbnail + title + controls
                    Row(
                      children: [
                        // Thumbnail — fixed size, never unbounded
                        if (!playerState.isSeeking)
                          AudioPlayerThumbnailCardWidget(
                            horizontalPadding: 0,
                            height: mq.height * 0.05,
                            width: mq.height * 0.05,
                            borderRadius: BorderRadius.circular(5),
                          ),

                        // Seeking position indicator
                        if (playerState.isSeeking)
                          CircleAvatar(
                            radius: 23,
                            child: Text(
                              Formatter.formatDuration(Duration(
                                  seconds:
                                      playerState.seekingPosition.toInt())),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ),

                        const Gap(10),

                        // Scrolling title — Expanded prevents overflow
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

                        // Playback buttons
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
                        ),
                      ],
                    ),

                    // Seek bar row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Row(
                        children: [
                          const AudioPlayerPositionAndDurationWidget(
                            showDuration: false,
                            enablePadding: false,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          const Flexible(
                            child: AudioPlayerSeekBarWidget(
                              enabledThumbRadius: 6,
                              activeTrackColor: Colors.white,
                              thumbColor: Colors.white,
                            ),
                          ),
                          const AudioPlayerPositionAndDurationWidget(
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
            ).glassMorphic(
                blur: 4,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.zero,
                  bottomRight: Radius.zero,
                ),
                circularRadius: 0,
                opacity: 0);
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STYLE 1 — COMPACT
//
// Ultra-slim pill bar: thumbnail + scrolling title + single play/pause button.
// No seek bar — maximum screen space for the content below.
// Height is fixed at ~10% of screen height.
// ═══════════════════════════════════════════════════════════════════════════

class _CompactMiniPlayer extends StatelessWidget {
  const _CompactMiniPlayer({
    required this.playerState,
    required this.onTap,
    this.color,
    this.shadowColor,
  });

  final AudioPlayerSuccessState playerState;
  final VoidCallback onTap;
  final Color? color;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    // Responsive height: 10% mobile, 7% tablet (tablets have more vertical space)
    final double h = mq.width >= 600 ? mq.height * 0.07 : mq.height * 0.10;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: h,
        width: mq.width,
        child: StreamBuilder(
          stream: playerState.audioPlayerCombinedStream,
          builder: (context, snapshot) {
            final int? ci = snapshot.data?.currentIndex ??
                playerState.audioPlayer.currentIndex;
            final String title =
                ci != null ? playerState.audios[ci].title : '...';
            final bool playing = snapshot.data?.playing ?? false;

            return Container(
              // color: color ?? Theme.of(context).colorScheme.primary,
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: AudioPlayerThumbnailCardWidget(
                      horizontalPadding: 0,
                      height: h - 12,
                      width: h - 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Gap(10),

                  // Title — Expanded + marquee handles any length
                  Expanded(
                    child: AnimatedAutoScrollTextWidget(
                      title,
                      style: const TextStyle(
                        fontFamily: AppFonts.poppins,
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Gap(8),

                  // Single play/pause button — compact
                  AudioPlayerPlayPauseButtonWidget(
                    iconSize: 28,
                    pauseIcon: CupertinoIcons.pause_circle_fill,
                    playIcon: CupertinoIcons.play_circle_fill,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).glassMorphic(
        blur: 4,
        border: Border.all(style: BorderStyle.none),
        circularRadius: 0,
        opacity: 0);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STYLE 2 — ARTWORK
//
// Artwork-dominant card: album art fills the left ~30% of the card,
// title + seek bar + all controls sit to the right.
// Taller than Classic at 20% screen height — the art has room to breathe.
// ═══════════════════════════════════════════════════════════════════════════

class _ArtworkMiniPlayer extends StatelessWidget {
  const _ArtworkMiniPlayer({
    required this.playerState,
    required this.onTap,
    this.color,
    this.shadowColor,
  });

  final AudioPlayerSuccessState playerState;
  final VoidCallback onTap;
  final Color? color;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final double h = mq.width >= 600 ? mq.height * 0.142 : mq.height * 0.182;
    final double artSize =
        h - 12; // artwork fills the full height minus padding

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: h,
        width: mq.width,
        child: StreamBuilder(
          stream: playerState.audioPlayerCombinedStream,
          builder: (context, snapshot) {
            final int? ci = snapshot.data?.currentIndex ??
                playerState.audioPlayer.currentIndex;
            final String title =
                ci != null ? playerState.audios[ci].title : '...';
            final String artist =
                ci != null ? (playerState.audios[ci].artists) : '';

            return Container(
              // color: color ?? Theme.of(context).colorScheme.primary,
              color: Colors.transparent,
              padding: const EdgeInsets.all(6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: large square artwork
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AudioPlayerThumbnailCardWidget(
                      horizontalPadding: 0,
                      height: artSize,
                      width: artSize,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Gap(10),

                  // Right: title + artist + controls + seek
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title
                        AnimatedAutoScrollTextWidget(
                          title,
                          style: const TextStyle(
                            fontFamily: AppFonts.poppins,
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        // Artist — optional, only shown when present
                        if (artist.isNotEmpty)
                          Text(
                            artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),

                        const Gap(4),

                        // Playback buttons row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AudioPlayerPreviousButtonWidget(iconSize: 20),
                            AudioPlayerPlayPauseButtonWidget(
                              iconSize: 32,
                              pauseIcon: CupertinoIcons.pause_circle_fill,
                              playIcon: CupertinoIcons.play_circle_fill,
                            ),
                            const AudioPlayerNextButtonWidget(iconSize: 20),
                          ],
                        ),

                        // Slim seek bar
                        const AudioPlayerSeekBarWidget(
                          enabledThumbRadius: 5,
                          activeTrackColor: Colors.white,
                          thumbColor: Colors.white,
                          trackHeight: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ).glassMorphic(
        blur: 4,
        border: Border.all(style: BorderStyle.none),
        circularRadius: 0,
        opacity: 0);
  }
}
