import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:open_player/base/assets/images/app_images.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import '../bloc/audio_player_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUDIO PLAYER BACKGROUND BLUR IMAGE WIDGET
//
// Static mode (dynamic OFF):
//   Exactly the original — blurred thumbnail, no animation.
//
// Dynamic mode (dynamic ON):
//   The blurred thumbnail slowly drifts in a smooth continuous circular path
//   while very gently breathing (scale). Looks like Spotify / Apple Music.
//
// Why edges never bleed through:
//   • The image is rendered at 140 % of screen size (overscaled).
//   • ClipRect clips any overflow — the screen boundary is never crossed.
//   • The drift amplitude (6 % of screen) is well inside the 20 % buffer
//     the overscale provides, so the image always covers the viewport.
//
// Why it's smooth and cheap:
//   • flutter_hooks useAnimationController — lifecycle managed by hooks.
//   • Single controller runs continuously (no reverse) at 18 s period.
//   • sin/cos on the same t gives a true circle — no abrupt direction change.
//   • AnimatedBuilder wraps only the Transform, nothing else repaints.
//   • RepaintBoundary keeps the blurred image as a cached GPU texture.
//   • The blur layer and the image layer never repaint during animation.
// ─────────────────────────────────────────────────────────────────────────────

class AudioPlayerBackgroundBlurImageWidget extends HookWidget {
  const AudioPlayerBackgroundBlurImageWidget({super.key});

  // Overscale factor — image is this many times larger than the screen.
  // Must be > 1 + (2 * driftRatio) to guarantee no edge bleed.
  // 1.40 gives a 20 % buffer on each side for a 6 % drift amplitude.
  static const double _overscale = 1.40;

  // How far the image centre drifts as a fraction of screen size.
  // Must be less than (_overscale - 1) / 2 = 0.20 — we use 0.06.
  static const double _driftRatio = 0.06;

  // Peak scale on top of the overscale — subtle breathing effect.
  static const double _breatheExtra = 0.08; // 8 % extra at peak

  // One full circular orbit period.
  static const Duration _period = Duration(seconds: 18);

  @override
  Widget build(BuildContext context) {
    // ── Animation controller via hooks ─────────────────────────────────────
    // repeat() with NO reverse → t goes 0→1→0→1 continuously in one direction
    // which gives perfectly smooth sin/cos circular motion.
    final ctrl = useAnimationController(duration: _period)..repeat();

    // Read dynamic flag — rebuilds only when this flag changes
    final bool dynamic = context.select<ThemeCubit, bool>(
      (c) => c.state.playerDynamicLightEnabled,
    );

    // Start/stop when user toggles the setting
    useEffect(() {
      if (dynamic) {
        if (!ctrl.isAnimating) ctrl.repeat();
      } else {
        ctrl.stop();
        ctrl.value = 0;
      }
      return null;
    }, [dynamic]);

    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (s) => s is AudioPlayerSuccessState ? s : null,
      builder: (context, playerState) {
        // Extract current thumbnail bytes
        Uint8List? thumb;
        if (playerState != null) {
          return StreamBuilder(
            stream: playerState.audioPlayerCombinedStream,
            builder: (context, snapshot) {
              final int? ci = snapshot.data?.currentIndex ??
                  playerState.audioPlayer.currentIndex;
              thumb = (ci != null &&
                      ci < playerState.audios.length &&
                      playerState.audios[ci].thumbnail.isNotEmpty)
                  ? playerState.audios[ci].thumbnail.first.bytes
                  : null;
              return _buildLayer(
                  context: context, ctrl: ctrl, dynamic: dynamic, thumb: thumb);
            },
          );
        }
        return _buildLayer(
            context: context, ctrl: ctrl, dynamic: dynamic, thumb: null);
      },
    );
  }

  Widget _buildLayer({
    required BuildContext context,
    required AnimationController ctrl,
    required bool dynamic,
    required Uint8List? thumb,
  }) {
    // ── Build the base image ───────────────────────────────────────────────
    final Widget image = SizedBox.expand(
      child: thumb != null
          ? DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: MemoryImage(thumb),
                  fit: BoxFit.cover,
                ),
              ),
            )
          : const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppImages.defaultThumbnail),
                  fit: BoxFit.cover,
                ),
              ),
            ),
    );

    // ── Blur layer — stays cached as GPU texture ───────────────────────────
    final Widget blurred = RepaintBoundary(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: image,
      ),
    );

    if (!dynamic) {
      // Static mode — original behaviour, no animation overhead
      return blurred;
    }

    // ── Dynamic mode ───────────────────────────────────────────────────────
    // ClipRect is the key: it makes the viewport boundary a hard clip so
    // even if the math drifts slightly over, nothing bleeds through.
    return ClipRect(
      child: AnimatedBuilder(
        animation: ctrl,
        // child is passed through so AnimatedBuilder never rebuilds it —
        // only the Transform wrapper is rebuilt on each tick
        child: blurred,
        builder: (context, child) {
          final double t = ctrl.value; // 0.0 → 1.0 continuous
          final mq = MediaQuery.sizeOf(context);

          // ── Circular drift ─────────────────────────────────────────────
          // sin and cos at the same phase give a true circle.
          // 2π * t maps one full controller cycle to one full orbit.
          final double angle = 2 * math.pi * t;
          final double dx = mq.width * _driftRatio * math.sin(angle);
          final double dy = mq.height * _driftRatio * math.cos(angle);

          // ── Breathing scale ────────────────────────────────────────────
          // Oscillates between _overscale and _overscale + _breatheExtra.
          // sin(2 * angle) runs at double speed so breathing happens twice
          // per orbit — feels natural, like the music is breathing.
          final double breathe =
              _breatheExtra * 0.5 * (1 + math.sin(2 * angle));
          final double scale = _overscale + breathe;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scale(scale) // overscale + breathe
              ..translate(dx / scale, dy / scale), // compensate for scale
            child: child,
          );
        },
      ),
    );
  }
}
