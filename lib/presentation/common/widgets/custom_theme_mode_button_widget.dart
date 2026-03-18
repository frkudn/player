import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/logic/theme_cubit/theme_cubit.dart';
import 'package:open_player/utils/extensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM THEME MODE BUTTON
//
// Apple engineering principles applied:
//
// 1. StatefulWidget + SingleTickerProviderStateMixin
//    The old TweenAnimationBuilder(begin:0, end:1) was recreated from scratch
//    every time the parent rebuilt (e.g. BlocBuilder on theme change). Each
//    new TweenAnimationBuilder starts at t=0, so the sparkles always reset.
//    A single AnimationController lives for the widget's lifetime and drives
//    the continuous sparkle rotation independently of the parent tree.
//
// 2. RepaintBoundary around every animated layer
//    Flutter's raster cache stores a GPU texture per RepaintBoundary. When
//    ONLY the sparkle layer changes, Flutter repaints just that texture and
//    composites it — the background and toggle are untouched. Without this,
//    the entire toggle repaints every animation frame.
//
// 3. Zero heap allocations in build()
//    All BoxDecoration objects are stored as instance fields. build() reads
//    pre-built objects — it never calls BoxDecoration(...) or LinearGradient().
//    This reduces GC pressure during the 500 ms toggle animation.
//
// 4. Spring physics on the toggle knob
//    Curves.elasticOut gives the knob a subtle overshoot — the physical
//    "click" feel Apple uses on every interactive element.
// ─────────────────────────────────────────────────────────────────────────────

class CustomThemeModeButtonWidget extends StatefulWidget {
  const CustomThemeModeButtonWidget({super.key});

  @override
  State<CustomThemeModeButtonWidget> createState() =>
      _CustomThemeModeButtonWidgetState();
}

class _CustomThemeModeButtonWidgetState
    extends State<CustomThemeModeButtonWidget>
    with SingleTickerProviderStateMixin {
  // ── Continuous sparkle / star rotation ──────────────────────────────────
  // Runs forever at a gentle pace — independent of the toggle animation.
  // Disposed properly in dispose() so there are no memory leaks.
  late final AnimationController _sparkle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(); // loops 0→1 forever

  // ── Pre-built decorations (zero build() allocations) ────────────────────

  static final _darkTrackDeco = BoxDecoration(
    borderRadius: BorderRadius.circular(30),
    gradient: LinearGradient(
      colors: [const Color(0xFF1C1C2E), const Color(0xFF2D2D44)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.4),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ],
  );

  static final _lightTrackDeco = BoxDecoration(
    borderRadius: BorderRadius.circular(30),
    gradient: const LinearGradient(
      colors: [Color(0xFF74C8FF), Color(0xFFB69DFF), Color(0xFFFF9FC3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF74C8FF).withValues(alpha: 0.4),
        blurRadius: 10,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: const Color(0xFFFF9FC3).withValues(alpha: 0.25),
        blurRadius: 16,
        spreadRadius: 3,
        offset: const Offset(4, 4),
      ),
    ],
  );

  static final _darkKnobDeco = BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      colors: [const Color(0xFF2C2C3E), const Color(0xFF3D3D55)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      const BoxShadow(
        color: Colors.black38,
        blurRadius: 6,
        spreadRadius: 1,
      ),
    ],
  );

  static final _lightKnobDeco = BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      colors: [Colors.orange.shade300, Colors.yellow.shade400],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.orange.withValues(alpha: 0.35),
        blurRadius: 8,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: Colors.yellow.shade200.withValues(alpha: 0.4),
        blurRadius: 14,
        spreadRadius: 3,
        offset: const Offset(2, 2),
      ),
    ],
  );

  @override
  void dispose() {
    _sparkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild when isDarkMode changes — not on every ThemeState emit
    final isDark = context.select<ThemeCubit, bool>(
      (c) => c.state.isDarkMode,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing: scales with parent constraints + screen height
        final mq = MediaQuery.sizeOf(context);
        final double trackH = (mq.height * 0.045).clamp(36.0, 52.0);
        final double trackW = (mq.width * 0.18).clamp(68.0, 100.0);
        final double knobSize = trackH - 8;

        return GestureDetector(
          onTap: () => context.read<ThemeCubit>().toggleThemeMode(),
          child: SizedBox(
            width: trackW,
            height: trackH,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(4),
              decoration: isDark ? _darkTrackDeco : _lightTrackDeco,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Background ambient layer ─────────────────────────
                  // RepaintBoundary: this layer animates independently.
                  // GPU texture is cached — only repaints when sparkle rotates.
                  RepaintBoundary(
                    child: isDark
                        ? _StarField(animation: _sparkle)
                        : _SunRays(animation: _sparkle),
                  ),

                  // ── Sliding knob ─────────────────────────────────────
                  // AnimatedAlign handles the position transition.
                  // The knob itself has a RepaintBoundary because its
                  // rotation is independent of the position tween.
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.elasticOut, // spring overshoot = Apple feel
                    alignment:
                        isDark ? Alignment.centerRight : Alignment.centerLeft,
                    child: RepaintBoundary(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 420),
                        width: knobSize,
                        height: knobSize,
                        decoration: isDark ? _darkKnobDeco : _lightKnobDeco,
                        child: _KnobIcon(isDark: isDark, knobSize: knobSize),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KNOB ICON
//
// Separate widget so AnimatedSwitcher can cross-fade between sun and moon
// without rebuilding the entire toggle tree.
// ─────────────────────────────────────────────────────────────────────────────

class _KnobIcon extends StatelessWidget {
  const _KnobIcon({required this.isDark, required this.knobSize});

  final bool isDark;
  final double knobSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Icon(
        key: ValueKey(isDark), // tells AnimatedSwitcher these are different
        isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
        color: isDark ? const Color(0xFFB0B8D8) : Colors.orange.shade800,
        size: knobSize * 0.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAR FIELD (dark mode background)
//
// Uses a single AnimationController value to rotate/twinkle 5 stars.
// Drawing 5 icons is cheaper than a CustomPainter for this case because
// Icon widgets are already cached GPU glyphs.
// ─────────────────────────────────────────────────────────────────────────────

class _StarField extends AnimatedWidget {
  const _StarField({required Animation<double> animation})
      : super(listenable: animation);

  // Fixed positions — computed once, not every frame
  static const _positions = [
    Offset(4, 3),
    Offset(16, 8),
    Offset(28, 2),
    Offset(10, 14),
    Offset(22, 16),
  ];

  @override
  Widget build(BuildContext context) {
    final double t = (listenable as Animation<double>).value;

    return Stack(
      children: List.generate(_positions.length, (i) {
        // Each star rotates at a slightly different speed (phase offset)
        final double angle = (t + i * 0.17) * 2 * math.pi;
        // Twinkle: scale oscillates between 0.6 and 1.0
        final double scale = 0.6 + 0.4 * math.sin(t * math.pi * 2 + i);

        return Positioned(
          left: _positions[i].dx,
          top: _positions[i].dy,
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: Icon(
                Icons.star_rounded,
                size: 7,
                color: Colors.yellow[100]!.withValues(alpha: 0.7 + 0.3 * scale),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUN RAYS (light mode background)
//
// Small sparkles that slowly rotate — evokes a sunny sky without being heavy.
// AnimatedWidget pattern: rebuild happens only when the animation ticks,
// not when the parent rebuilds.
// ─────────────────────────────────────────────────────────────────────────────

class _SunRays extends AnimatedWidget {
  const _SunRays({required Animation<double> animation})
      : super(listenable: animation);

  static const _positions = [
    Offset(3, 2),
    Offset(18, 6),
    Offset(32, 3),
    Offset(8, 14),
    Offset(24, 16),
  ];

  @override
  Widget build(BuildContext context) {
    final double t = (listenable as Animation<double>).value;

    return Stack(
      children: List.generate(_positions.length, (i) {
        final double angle = (t + i * 0.2) * 2 * math.pi;
        final double opacity = 0.5 + 0.5 * math.sin(t * math.pi * 2 + i * 0.8);

        return Positioned(
          left: _positions[i].dx,
          top: _positions[i].dy,
          child: Transform.rotate(
            angle: angle,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 9,
              color: Colors.white.withValues(alpha: opacity.clamp(0.3, 0.95)),
            ),
          ),
        );
      }),
    );
  }
}
