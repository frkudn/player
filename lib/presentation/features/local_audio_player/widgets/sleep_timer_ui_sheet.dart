// ─────────────────────────────────────────────────────────────────────────────
// SLEEP TIMER UI SHEET
//
// A beautiful bottom sheet widget for selecting / cancelling the sleep timer.
// Designed to be shown from the audio player's sidebar.
//
// Usage:
//   SleepTimerSheet.show(context);
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';

import '../cubit/sleep_timer/sleep_timer_cubit.dart';

class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({super.key});
  static String formatRemaining(Duration d) => _fmt(d);

  /// Shows the sleep timer bottom sheet over the current screen.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<SleepTimerCubit>(),
        child: const SleepTimerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color primary = cs.primary;
    final Color onSurface = cs.onSurface;

    // Use a dark sheet background for the audio player context
    final Color bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF111118)
        : cs.surface;

    return BlocBuilder<SleepTimerCubit, SleepTimerState>(
      builder: (context, state) {
        final cubit = context.read<SleepTimerCubit>();

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: primary.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ───────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Header row ────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: primary.withValues(alpha: 0.12),
                    ),
                    child: Icon(HugeIcons.strokeRoundedSleeping,
                        size: 18, color: primary),
                  ),
                  const Gap(12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sleep Timer',
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppFonts.poppins,
                        ),
                      ),
                      Text(
                        state.isActive
                            ? 'Pauses in ${_fmt(state.remaining!)}'
                            : 'Audio pauses after selected time',
                        style: TextStyle(
                          color: state.isActive
                              ? primary
                              : onSurface.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: state.isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Live countdown badge when active
                  if (state.isActive && state.remaining != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: primary.withValues(alpha: 0.15),
                        border: Border.all(
                            color: primary.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Text(
                        _fmt(state.remaining!),
                        style: TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: AppFonts.poppins,
                        ),
                      ),
                    ),
                ],
              ),

              const Gap(20),

              // ── Preset grid ───────────────────────────────────────────────
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                ),
                itemCount: SleepTimerCubit.presets.length,
                itemBuilder: (_, i) {
                  final Duration d = SleepTimerCubit.presets[i];
                  final bool isSelected = state.isActive && state.selected == d;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      cubit.start(d);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? primary.withValues(alpha: 0.15)
                            : onSurface.withValues(alpha: 0.04),
                        border: Border.all(
                          color: isSelected
                              ? primary.withValues(alpha: 0.45)
                              : onSurface.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  spreadRadius: -2,
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _fmtPreset(d),
                          style: TextStyle(
                            color: isSelected
                                ? primary
                                : onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppFonts.poppins,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const Gap(16),

              // ── Cancel button (only when active) ──────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: state.isActive
                    ? GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          cubit.cancel();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.red.withValues(alpha: 0.08),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.25),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.timer_off_rounded,
                                  color: Colors.red.withValues(alpha: 0.7),
                                  size: 16),
                              const Gap(8),
                              Text(
                                'Cancel Timer',
                                style: TextStyle(
                                  color: Colors.red.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  /// Format a Duration as "hh:mm:ss" or "mm:ss".
  static String _fmt(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Format a Duration preset as "5 min", "1 hr", etc.
  static String _fmtPreset(Duration d) {
    if (d.inMinutes >= 60) {
      final int h = d.inHours;
      final int rem = d.inMinutes.remainder(60);
      return rem == 0 ? '${h}hr' : '${h}h${rem}m';
    }
    return '${d.inMinutes}min';
  }
}
