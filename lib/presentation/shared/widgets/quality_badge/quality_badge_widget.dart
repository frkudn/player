// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// ── Tier configuration ────────────────────────────────────────────────────────

/// Immutable visual config for a quality tier badge.
class _TierConfig {
  final List<Color> gradient; // 3-stop gradient, top-left → bottom-right
  final Color glow; // box-shadow / pulse ring colour
  final Color shimmer; // shimmer sweep highlight colour
  final String label;
  final IconData? icon;
  final bool hasPulse; // animated ring (DSD only)
  final bool hasShimmer; // moving shimmer sweep (DSD + MQ)

  const _TierConfig({
    required this.gradient,
    required this.glow,
    required this.shimmer,
    required this.label,
    this.icon,
    this.hasPulse = false,
    this.hasShimmer = false,
  });

  static _TierConfig of(String quality) {
    switch (quality) {
      // ── DSD ── fiery amber-orange, analog warmth
      case 'DSD':
        return const _TierConfig(
          gradient: [Color(0xFFFF6B00), Color(0xFFE53000), Color(0xFFFF9500)],
          glow: Color(0xFFFF5500),
          shimmer: Color(0xFFFFCC80),
          label: 'DSD',
          icon: Icons.graphic_eq_rounded,
          hasPulse: true,
          hasShimmer: true,
        );

      // ── MQ ── deep amethyst, studio luxury
      case 'MQ':
        return const _TierConfig(
          gradient: [Color(0xFF6A0DAD), Color(0xFF9C27B0), Color(0xFFCE93D8)],
          glow: Color(0xFF9C27B0),
          shimmer: Color(0xFFEDD8F5),
          label: 'MQ',
          icon: Icons.auto_awesome_rounded,
          hasPulse: false,
          hasShimmer: true,
        );

      // ── HR ── sapphire teal, JEITA Hi-Res standard colour family
      case 'HR':
        return const _TierConfig(
          gradient: [Color(0xFF006064), Color(0xFF00897B), Color(0xFF4DB6AC)],
          glow: Color(0xFF00897B),
          shimmer: Color(0xFFB2EBF2),
          label: 'Hi-Res',
          icon: Icons.diamond_rounded,
          hasPulse: false,
          hasShimmer: false,
        );

      // ── HQ ── cobalt blue, clear and confident
      case 'HQ':
        return const _TierConfig(
          gradient: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF64B5F6)],
          glow: Color(0xFF1976D2),
          shimmer: Colors.transparent,
          label: 'HQ',
          hasPulse: false,
          hasShimmer: false,
        );

      // ── SQ ── jade green, solid and dependable
      case 'SQ':
        return const _TierConfig(
          gradient: [Color(0xFF1B5E20), Color(0xFF388E3C), Color(0xFF81C784)],
          glow: Color(0xFF388E3C),
          shimmer: Colors.transparent,
          label: 'SQ',
          hasPulse: false,
          hasShimmer: false,
        );

      // ── LQ ── cool slate, understated
      default:
        return const _TierConfig(
          gradient: [Color(0xFF455A64), Color(0xFF607D8B), Color(0xFF90A4AE)],
          glow: Color(0xFF607D8B),
          shimmer: Colors.transparent,
          label: 'LQ',
          hasPulse: false,
          hasShimmer: false,
        );
    }
  }
}

// ── QualityBadge ─────────────────────────────────────────────────────────────

class QualityBadge extends HookWidget {
  final String quality;

  /// Scales the entire badge. `size` ≈ the font size of the label;
  /// all internal proportions are derived from it.
  final double size;

  final bool showAnimation;
  final VoidCallback? onTap;

  // `isDark` retained for API compatibility but gradient badges look great
  // on both light and dark surfaces without adjustment.
  final bool isDark;

  const QualityBadge({
    super.key,
    this.quality = 'LQ',
    this.isDark = false,
    this.size = 12,
    this.showAnimation = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _TierConfig.of(quality);
    final isHovered = useState(false);

    // ── Controllers ─────────────────────────────────────────────────────────
    // Hover: quick ease-out scale pop
    final hoverCtrl = useAnimationController(
      duration: const Duration(milliseconds: 180),
    );

    // Shimmer: looping sweep across the badge face (DSD + MQ)
    final shimmerCtrl = useAnimationController(
      duration: const Duration(milliseconds: 2600),
    );

    // Pulse: expanding ring glow (DSD only)
    final pulseCtrl = useAnimationController(
      duration: const Duration(milliseconds: 1700),
    );

    // ── Animation lifecycle ──────────────────────────────────────────────────
    useEffect(() {
      if (!showAnimation) return null;
      if (config.hasShimmer) shimmerCtrl.repeat();
      if (config.hasPulse) pulseCtrl.repeat(); // one-shot direction, no reverse
      return () {
        shimmerCtrl.stop();
        pulseCtrl.stop();
      };
    }, [showAnimation, quality]);

    useEffect(() {
      if (isHovered.value) {
        hoverCtrl.forward();
      } else {
        hoverCtrl.reverse();
      }
      return null;
    }, [isHovered.value]);

    // ── Build ────────────────────────────────────────────────────────────────
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([hoverCtrl, shimmerCtrl, pulseCtrl]),
          builder: (context, _) {
            final scale = showAnimation
                ? Tween<double>(begin: 1.0, end: 1.09)
                    .animate(CurvedAnimation(
                      parent: hoverCtrl,
                      curve: Curves.easeOutBack,
                    ))
                    .value
                : 1.0;

            final glowAlpha = Tween<double>(begin: 0.32, end: 0.70)
                .animate(CurvedAnimation(
                  parent: hoverCtrl,
                  curve: Curves.easeOut,
                ))
                .value;

            return Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // ── Expanding pulse ring (DSD) ───────────────────────────
                  if (config.hasPulse && showAnimation)
                    _PulseRing(
                      controller: pulseCtrl,
                      color: config.glow,
                      baseHeight: size * 1.9,
                      borderRadius: size * 0.42,
                    ),

                  // ── Main badge ───────────────────────────────────────────
                  _BadgeFace(
                    config: config,
                    size: size,
                    glowAlpha: glowAlpha,
                    shimmerProgress: config.hasShimmer && showAnimation
                        ? shimmerCtrl.value
                        : -1,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Badge face ────────────────────────────────────────────────────────────────

class _BadgeFace extends StatelessWidget {
  final _TierConfig config;
  final double size;
  final double glowAlpha;

  /// Normalised 0–1 shimmer position; -1 = disabled.
  final double shimmerProgress;

  const _BadgeFace({
    required this.config,
    required this.size,
    required this.glowAlpha,
    required this.shimmerProgress,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.42);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.58,
        vertical: size * 0.22,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: const Alignment(-0.8, -1.0),
          end: const Alignment(0.8, 1.0),
          colors: config.gradient,
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          // Outer colour glow
          BoxShadow(
            color: config.glow.withValues(alpha: glowAlpha),
            blurRadius: size * 0.7,
            spreadRadius: size * 0.04,
          ),
          // Subtle drop shadow for depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.1),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.35),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Shimmer sweep ──────────────────────────────────────────────
            if (shimmerProgress >= 0)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ShimmerPainter(
                    progress: shimmerProgress,
                    color: config.shimmer,
                  ),
                ),
              ),

            // ── Specular top-edge highlight ────────────────────────────────
            Positioned(
              top: 0,
              left: size * 0.4,
              right: size * 0.4,
              child: Container(
                height: 0.9,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),

            // ── Label row ─────────────────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (config.icon != null) ...[
                  Icon(
                    config.icon,
                    color: Colors.white,
                    size: size * 0.8,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  SizedBox(width: size * 0.24),
                ],
                Text(
                  config.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.65,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.65,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pulse ring ────────────────────────────────────────────────────────────────

/// Expands outward from the badge and fades out — like a sonar ping.
class _PulseRing extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final double baseHeight;
  final double borderRadius;

  const _PulseRing({
    required this.controller,
    required this.color,
    required this.baseHeight,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final expandScale = Tween<double>(begin: 1.0, end: 1.55)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut))
        .value;

    final fadeOut = Tween<double>(begin: 0.55, end: 0.0)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeIn))
        .value;

    return Transform.scale(
      scale: expandScale,
      child: Container(
        height: baseHeight,
        // Width adapts with scale; ring is purely decorative
        width: baseHeight * 2.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: color.withValues(alpha: fadeOut),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

// ── Shimmer painter ───────────────────────────────────────────────────────────

/// Paints a diagonal light-streak that sweeps left → right once per cycle.
///
/// `progress` is the raw 0–1 animation value.
/// The sweep overshoots on both sides so the transition is smooth even
/// at the edges of short badges.
class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ShimmerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Map 0–1 progress to a centerX that travels from -40 % to 140 % width
    final centerX = size.width * (-0.4 + progress * 1.8);
    final beamWidth = size.width * 0.45;

    final rect = Rect.fromCenter(
      center: Offset(centerX, size.height / 2),
      width: beamWidth,
      height: size.height,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          color.withAlpha(0),
          color.withAlpha(55),
          color.withAlpha(0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    // Clip to badge bounds before drawing
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}
