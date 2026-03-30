// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

// ── Tier visual config ────────────────────────────────────────────────────────

/// All visual properties for a single quality tier, held as const instances.
/// Zero allocation per build — configs are resolved once at compile time.
@immutable
class _TierStyle {
  final List<Color> gradient; // 3-stop, dark anchor → vivid mid → bright tip
  final Color glowColor;
  final String label;
  final IconData? icon;

  const _TierStyle({
    required this.gradient,
    required this.glowColor,
    required this.label,
    this.icon,
  });

  // ── Static tier map ───────────────────────────────────────────────────────
  //
  // DSD  : Deep black/charcoal with molten gold — ultra-premium, one-of-a-kind
  // MQ   : Deep crimson → vivid red → rose       — "super quality", powerful
  // HR   : Deep amber → pure gold → pale gilt     — "high resolution", precious
  // HQ   : Deep navy → cobalt → sky blue          — solid, trustworthy, clear
  // SQ   : Deep forest → emerald → sage           — decent, natural
  // LQ   : Charcoal → slate → silver              — muted, understated

  static const _TierStyle dsd = _TierStyle(
    gradient: [Color(0xFF1A1100), Color(0xFF7A5200), Color(0xFFF0C040)],
    glowColor: Color(0xFFD4A017),
    label: 'DSD',
    icon: Icons.graphic_eq_rounded,
  );

  static const _TierStyle mq = _TierStyle(
    gradient: [Color(0xFF2D0000), Color(0xFFB71C1C), Color(0xFFEF5350)],
    glowColor: Color(0xFFB71C1C),
    label: 'MQ',
    icon: Icons.workspace_premium_rounded,
  );

  static const _TierStyle hr = _TierStyle(
    gradient: [Color(0xFF2B1900), Color(0xFF9A6500), Color(0xFFFFBF00)],
    glowColor: Color(0xFFC88A00),
    label: 'Hi-Res',
    icon: Icons.diamond_rounded,
  );

  static const _TierStyle hq = _TierStyle(
    gradient: [Color(0xFF091630), Color(0xFF1255B5), Color(0xFF4B8AE8)],
    glowColor: Color(0xFF1565C0),
    label: 'HQ',
  );

  static const _TierStyle sq = _TierStyle(
    gradient: [Color(0xFF0A2015), Color(0xFF1A7A3A), Color(0xFF48BB7A)],
    glowColor: Color(0xFF2E7D32),
    label: 'SQ',
  );

  static const _TierStyle lq = _TierStyle(
    gradient: [Color(0xFF1C1C1C), Color(0xFF5A5A5A), Color(0xFFA0A0A0)],
    glowColor: Color(0xFF607D8B),
    label: 'LQ',
  );

  static _TierStyle of(String quality) {
    switch (quality) {
      case 'DSD':
        return dsd;
      case 'MQ':
        return mq;
      case 'HR':
        return hr;
      case 'HQ':
        return hq;
      case 'SQ':
        return sq;
      default:
        return lq;
    }
  }
}

// ── QualityBadge ─────────────────────────────────────────────────────────────

/// Compact, mobile-optimised quality tier badge.
///
/// Design principles:
///   • No hover logic — this is a touch-first Android widget
///   • Single [AnimationController] used only when [onTap] is provided;
///     otherwise the widget is entirely static (zero animation overhead)
///   • [_TierStyle] instances are compile-time const — zero per-build allocation
///   • [CustomPainter] avoided — decoration is pure [BoxDecoration]
///   • All sizing derived from the single [size] parameter
///
/// Usage:
///   QualityBadge(quality: 'HR', size: 11)
///   QualityBadge(quality: 'DSD', size: 13, onTap: () { ... })
class QualityBadge extends StatefulWidget {
  /// Quality tier string: 'DSD' | 'MQ' | 'HR' | 'HQ' | 'SQ' | 'LQ'
  final String quality;

  /// Controls all proportions. Roughly equal to the label font size.
  /// Recommended: 10–14 for list items, 14–18 for now-playing screen.
  final double size;

  /// Optional tap callback. If null, no AnimationController is created.
  final VoidCallback? onTap;

  // Retained for API compatibility with existing call sites
  final bool isDark;
  final bool showAnimation;

  const QualityBadge({
    super.key,
    this.quality = 'LQ',
    this.size = 12,
    this.onTap,
    this.isDark = false,
    this.showAnimation = true,
  });

  @override
  State<QualityBadge> createState() => _QualityBadgeState();
}

class _QualityBadgeState extends State<QualityBadge>
    with SingleTickerProviderStateMixin {
  // Controller is created only when onTap is provided — saves resources
  // for the common case of a non-interactive badge in a track list.
  AnimationController? _ctrl;
  Animation<double>? _scale;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(QualityBadge old) {
    super.didUpdateWidget(old);
    // If onTap toggled, create or destroy the controller accordingly
    if ((widget.onTap != null) != (old.onTap != null)) {
      _ctrl?.dispose();
      _ctrl = null;
      _scale = null;
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    if (widget.onTap == null || !widget.showAnimation) return;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl!, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl?.forward();
  void _onTapUp(TapUpDetails _) => _ctrl?.reverse();
  void _onTapCancel() => _ctrl?.reverse();

  @override
  Widget build(BuildContext context) {
    final style = _TierStyle.of(widget.quality);
    final badge = _BadgeBody(style: style, size: widget.size);

    if (widget.onTap == null || _ctrl == null) return badge;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale!,
        builder: (_, __) => Transform.scale(
          scale: _scale!.value,
          child: badge,
        ),
      ),
    );
  }
}

// ── Badge body (stateless, const-constructible) ───────────────────────────────

class _BadgeBody extends StatelessWidget {
  final _TierStyle style;
  final double size;

  const _BadgeBody({required this.style, required this.size});

  @override
  Widget build(BuildContext context) {
    final s = size;
    final radius = BorderRadius.circular(s * 0.40);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: s * 0.55,
        vertical: s * 0.20,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: const Alignment(-0.6, -1.0),
          end: const Alignment(0.6, 1.0),
          colors: style.gradient,
          stops: const [0.0, 0.50, 1.0],
        ),
        // Colour-matched bottom glow — gives the badge depth and presence
        boxShadow: [
          BoxShadow(
            color: style.glowColor.withValues(alpha: 0.50),
            blurRadius: s * 0.75,
            spreadRadius: 0,
            offset: Offset(0, s * 0.15),
          ),
          // Tight inner shadow for 3D depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: s * 0.20,
            offset: Offset(0, s * 0.08),
          ),
        ],
        // Subtle frosted rim — separates the badge from any background
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
          width: 0.7,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── Specular highlight — 1 px white line at the very top edge ───
          // Gives the impression the badge is a physical object lit from above
          Positioned(
            top: 0,
            left: s * 0.25,
            right: s * 0.25,
            child: Container(
              height: 0.75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.52),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),

          // ── Label row ─────────────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (style.icon != null) ...[
                Icon(
                  style.icon,
                  color: Colors.white,
                  size: s * 0.80,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                SizedBox(width: s * 0.22),
              ],
              Text(
                style.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: s * 0.65,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.55,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.40),
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
    );
  }
}
