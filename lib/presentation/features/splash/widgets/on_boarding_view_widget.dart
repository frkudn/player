import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:open_player/base/assets/svgs/app_svgs.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/base/theme/app_textstyles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ON-BOARDING VIEW WIDGET
//
// Design concept: "quiet manifesto" — the app's FOSS/privacy values are shown
// in a calm, cinematic sequence rather than a noisy marketing splash.
//
// Layout layers (bottom to top):
//   1. Dark canvas with slow radial pulse (CustomPaint)
//   2. Three orbiting particles (CustomPaint + animation)
//   3. Logo — scales in from 0 via the parent's logoAnimation
//   4. Manifesto chip sequence — "No Ads", "No Subscription", etc.
//   5. Bottom tagline (fade in)
//
// No flashing, no jarring transitions — everything moves at breathing pace.
// ─────────────────────────────────────────────────────────────────────────────

class OnBoardingViewWidget extends StatefulWidget {
  final Animation<double> logoAnimation;

  const OnBoardingViewWidget({super.key, required this.logoAnimation});

  @override
  State<OnBoardingViewWidget> createState() => _OnBoardingViewWidgetState();
}

class _OnBoardingViewWidgetState extends State<OnBoardingViewWidget>
    with TickerProviderStateMixin {
  // ── Pulse ring behind the logo ─────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Orbiting dots ─────────────────────────────────────────────────────────
  late AnimationController _orbitCtrl;

  // ── Staggered chip reveal ──────────────────────────────────────────────────
  late AnimationController _chipsCtrl;
  late List<Animation<double>> _chipFades;
  late List<Animation<Offset>> _chipSlides;

  // ── Bottom tagline fade ────────────────────────────────────────────────────
  late AnimationController _taglineCtrl;
  late Animation<double> _taglineFade;

  static const _chips = [
    (text: AppStrings.noAds, icon: Icons.block_rounded),
    (text: AppStrings.noSubscription, icon: Icons.credit_card_off_rounded),
    (text: AppStrings.noTracking, icon: Icons.visibility_off_rounded),
    (text: AppStrings.justPureEntertainment, icon: Icons.music_note_rounded),
  ];

  @override
  void initState() {
    super.initState();

    // Pulse — slow breathe, loops forever
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    // Orbit — continuous slow rotation
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // Chips — staggered fade + slide, start after logo animation finishes
    _chipsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _chipFades = List.generate(_chips.length, (i) {
      final start = i * 0.22;
      final end = (start + 0.28).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _chipsCtrl,
          curve: Interval(start, end, curve: Curves.easeOut)));
    });

    _chipSlides = List.generate(_chips.length, (i) {
      final start = i * 0.22;
      final end = (start + 0.28).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(CurvedAnimation(
          parent: _chipsCtrl,
          curve: Interval(start, end, curve: Curves.easeOut)));
    });

    // Tagline — fades in after chips are done
    _taglineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _taglineFade = CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeIn);

    // Sequence: wait for logo, then chips, then tagline
    widget.logoAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted)
            _chipsCtrl.forward().then((_) {
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) _taglineCtrl.forward();
              });
            });
        });
      }
    });

    // If logo is already done (e.g. hot reload) start immediately
    if (widget.logoAnimation.status == AnimationStatus.completed) {
      _chipsCtrl.forward().then((_) => _taglineCtrl.forward());
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    _chipsCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String logo = isDark ? AppSvgs.logoDarkMode : AppSvgs.logoLightMode;

    // Accent color — use theme primary if available, otherwise vibrant purple
    final Color accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF06060F) : const Color(0xFFF5F5FB),
      body: Stack(children: [
        // ── 1. Background pulse ──────────────────────────────────────────
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => CustomPaint(
              painter: _PulsePainter(
                progress: _pulseAnim.value,
                accent: accent,
                isDark: isDark,
              ),
            ),
          ),
        ),

        // ── 2. Orbiting particles ────────────────────────────────────────
        Positioned(
          top: mq.height * 0.18,
          left: mq.width / 2 - 60,
          width: 120,
          height: 120,
          child: AnimatedBuilder(
            animation: _orbitCtrl,
            builder: (_, __) => CustomPaint(
              painter: _OrbitPainter(
                progress: _orbitCtrl.value,
                accent: accent,
                isDark: isDark,
              ),
            ),
          ),
        ),

        // ── 3. Logo ───────────────────────────────────────────────────────
        Positioned(
          top: mq.height * 0.18,
          left: 0,
          right: 0,
          child: ScaleTransition(
            scale: widget.logoAnimation,
            child: Hero(
              tag: 'app_logo',
              child: SvgPicture.asset(logo, height: 96),
            ),
          ),
        ),

        // ── 4. Manifesto chips ────────────────────────────────────────────
        Positioned(
          top: mq.height * 0.40,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_chips.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FadeTransition(
                    opacity: _chipFades[i],
                    child: SlideTransition(
                      position: _chipSlides[i],
                      child: _ManifestoChip(
                        text: _chips[i].text,
                        icon: _chips[i].icon,
                        accent: accent,
                        isDark: isDark,
                        index: i,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        // ── 5. Bottom tagline ────────────────────────────────────────────
        Positioned(
          bottom: mq.height * 0.07,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _taglineFade,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                AppStrings.appTagline,
                style: AppTextStyles.onBoarding.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.3),
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              // Version pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: accent.withValues(alpha: 0.1),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                child: Text(
                  AppStrings.appVersion,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MANIFESTO CHIP
//
// Each chip shows an icon + text in a glass-style container.
// Alternates between left/right alignment for visual rhythm.
// ═══════════════════════════════════════════════════════════════════════════════

class _ManifestoChip extends StatelessWidget {
  const _ManifestoChip({
    required this.text,
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.index,
  });

  final String text;
  final IconData icon;
  final Color accent;
  final bool isDark;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Even indices align left, odd align right — creates visual rhythm
    final bool alignLeft = index.isEven;

    final Color bg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final Color border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final Color fg = isDark ? Colors.white : Colors.black;

    return Align(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: bg,
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alignLeft) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: accent, size: 14),
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.7),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ] else ...[
              Text(
                text,
                style: TextStyle(
                  color: fg.withValues(alpha: 0.7),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                ),
                child: Icon(icon, color: accent, size: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Slow radial pulse rings behind the logo — creates a "breathing" atmosphere
class _PulsePainter extends CustomPainter {
  const _PulsePainter({
    required this.progress,
    required this.accent,
    required this.isDark,
  });

  final double progress;
  final Color accent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.27);
    const maxR = 140.0;

    for (int i = 0; i < 3; i++) {
      final double t = ((progress + i * 0.33) % 1.0);
      final double radius = maxR * (0.4 + t * 0.6);
      final double opacity = (1.0 - t) * (isDark ? 0.08 : 0.05);

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accent.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) =>
      old.progress != progress || old.accent != accent;
}

/// Three small dots orbiting slowly around the logo area
class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.progress,
    required this.accent,
    required this.isDark,
  });

  final double progress;
  final Color accent;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const r = 52.0;
    final dotPaint = Paint()
      ..color = accent.withValues(alpha: isDark ? 0.35 : 0.25)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final double a = progress * 2 * 3.14159 + i * 2.094;
      canvas.drawCircle(
        Offset(center.dx + r * _cos(a), center.dy + r * _sin(a)),
        2.5 - i * 0.4,
        dotPaint,
      );
    }
  }

  // Approximation sin/cos — avoid dart:math import issues in this file
  static double _sin(double x) {
    // Taylor series approximation (good enough for animation)
    x = x % (2 * 3.14159265);
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  static double _cos(double x) => _sin(x + 1.5708);

  @override
  bool shouldRepaint(_OrbitPainter old) => old.progress != progress;
}
