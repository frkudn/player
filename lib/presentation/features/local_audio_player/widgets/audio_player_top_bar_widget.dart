import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_add_to_playlist_button_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_equalizer_button_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_more_button.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_pitch_changer_button_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/widgets/audio_player_speed_changer_button_widget.dart';
import 'package:open_player/presentation/features/local_audio_player/cubit/sleep_timer/sleep_timer_cubit.dart';
import 'package:velocity_x/velocity_x.dart';

import 'sleep_timer_ui_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUDIO PLAYER TOP BAR WIDGET
//
// Shows back button (left) and the "more" menu button (right).
// The "more" menu slides in a glassmorphic sidebar with:
//   • Add to Playlist
//   • Equalizer
//   • Speed Changer
//   • Pitch Changer
//   • Sleep Timer  ← NEW
// ─────────────────────────────────────────────────────────────────────────────

class AudioPlayerTopBarWidget extends StatelessWidget {
  const AudioPlayerTopBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);

    return Container(
      // Push down below status bar
      margin: EdgeInsets.only(top: mq.height * 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Back button (left) ──────────────────────────────────────────
          _BackButton(),

          const Spacer(),

          // ── Active sleep timer indicator ────────────────────────────────
          // Shows a small badge with the remaining time next to the more button
          // when a sleep timer is running, so the user always knows it's active.
          BlocBuilder<SleepTimerCubit, SleepTimerState>(
            builder: (context, timerState) {
              if (!timerState.isActive || timerState.remaining == null) {
                return const SizedBox.shrink();
              }
              return GestureDetector(
                onTap: () => SleepTimerSheet.show(context),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withValues(alpha: 0.35),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        HugeIcons.strokeRoundedSleeping,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        SleepTimerSheet.formatRemaining(timerState.remaining!),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── More button (right) ──────────────────────────────────────────
          AudioPlayerMoreButton(
            onPressed: () {
              // Show the glassmorphic sidebar over the player
              VxDialog.showCustom(
                context,
                child: SlideInRight(
                  child: Container(
                    height: 380, // Taller to accommodate sleep timer
                    width: mq.width * 0.25,
                    alignment: Alignment.center,
                    child: [
                      // ── Add to Playlist ─────────────────────────────────
                      AudioPlayerAddToPlaylistButtonWidget(),

                      // ── Equalizer ───────────────────────────────────────
                      AudioPlayerEqualizerButtonWidget(),

                      // ── Speed Changer ───────────────────────────────────
                      AudioPlayerSpeedChangerButtonWidget(),

                      // ── Pitch Changer ───────────────────────────────────
                      AudioPlayerPitchChangerButtonWidget(),

                      // ── Sleep Timer ─────────────────────────────────────
                      // NEW: Sleep timer entry. Shows a small moon icon.
                      // Tapping dismisses the sidebar and opens the timer sheet.
                      _SleepTimerSidebarButton(context: context),
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

// ── BACK BUTTON ───────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.pop(),
      color: Colors.white,
      iconSize: 30,
      tooltip: 'Back',
      icon: const Icon(HugeIcons.strokeRoundedArrowDown01),
    );
  }
}

// ── SLEEP TIMER SIDEBAR BUTTON ────────────────────────────────────────────────
// Shows in the glassmorphic sidebar. Displays the active timer duration
// as a badge when a timer is running.

class _SleepTimerSidebarButton extends StatelessWidget {
  const _SleepTimerSidebarButton({required this.context});

  // Capture the outer context so SleepTimerSheet can access the cubit
  final BuildContext context;

  @override
  Widget build(BuildContext outer) {
    return BlocBuilder<SleepTimerCubit, SleepTimerState>(
      builder: (ctx, timerState) {
        return Tooltip(
          message: 'Sleep Timer',
          child: GestureDetector(
            onTap: () {
              // Close the sidebar first, then open the timer sheet
              Navigator.of(outer).pop();
              Future.delayed(
                const Duration(milliseconds: 150),
                () => SleepTimerSheet.show(context),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  timerState.isActive
                      ? HugeIcons.strokeRoundedSleeping
                      : HugeIcons.strokeRoundedMoon02,
                  color: timerState.isActive
                      ? Colors.amber.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.7),
                  size: 28,
                ),
                // Active indicator dot
                if (timerState.isActive)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
