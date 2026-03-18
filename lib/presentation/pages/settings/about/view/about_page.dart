import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/assets/svgs/app_svgs.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/presentation/common/widgets/social_media_icon_button.dart/social_media_icon_button.dart';
import 'package:url_launcher/link.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ABOUT PAGE
//
// Design direction: editorial manifesto × developer portfolio
//
// The unforgettable element: a slowly breathing ambient orb behind the hero
// section that pulses with the app primary colour, combined with oversized
// grid-breaking typography ("OPEN" + "PLAYER" stacked) and a FOSS manifesto
// strip that scrolls horizontally.
//
// Architecture:
//  • _AmbientOrb — AnimationController-driven breathing circle (RepaintBoundary)
//  • _ManifestoStrip — horizontal ScrollView of bold ideology phrases
//  • _StatBadge — editorial number + label unit
//  • _DevCard — glassmorphic developer identity card
//  • _SocialPill — compact icon+label tappable pill
// ─────────────────────────────────────────────────────────────────────────────

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  // Controls the ambient orb breathing animation (scale 0.9 → 1.1 and back)
  late final AnimationController _orb = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _orb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primary = Theme.of(context).primaryColor;
    final Color bg = Theme.of(context).scaffoldBackgroundColor;
    final Color onBg = isDark ? Colors.white : Colors.black;
    final String appLogo =
        isDark ? AppSvgs.logoDarkMode : AppSvgs.logoLightMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Status bar icons match the page background
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── SLIVER APP BAR ────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: FadeIn(
                duration: const Duration(milliseconds: 600),
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    CupertinoIcons.back,
                    color: onBg.withValues(alpha: 0.7),
                  ),
                ),
              ),
              // "ABOUT" label top-right
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 20, top: 8),
                  child: FadeIn(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'ABOUT',
                      style: TextStyle(
                        color: primary.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        fontFamily: AppFonts.poppins,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HERO SECTION ──────────────────────────────────────
                  _HeroSection(
                    orb: _orb,
                    primary: primary,
                    onBg: onBg,
                    isDark: isDark,
                    appLogo: appLogo,
                    mq: mq,
                  ),

                  const Gap(8),

                  // ── MANIFESTO STRIP ───────────────────────────────────
                  FadeInLeft(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 700),
                    child: _ManifestoStrip(primary: primary, onBg: onBg),
                  ),

                  const Gap(36),

                  // ── STATS ROW ─────────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    duration: const Duration(milliseconds: 700),
                    child:
                        _StatsRow(primary: primary, onBg: onBg, isDark: isDark),
                  ),

                  const Gap(36),

                  // ── PHILOSOPHY BLOCK ──────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    duration: const Duration(milliseconds: 700),
                    child: _PhilosophyBlock(primary: primary, onBg: onBg),
                  ),

                  const Gap(36),

                  // ── DEVELOPER CARD ────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    duration: const Duration(milliseconds: 700),
                    child:
                        _DevCard(primary: primary, onBg: onBg, isDark: isDark),
                  ),

                  const Gap(36),

                  // ── REPO LINKS ────────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    duration: const Duration(milliseconds: 700),
                    child: _RepoSection(
                        primary: primary, onBg: onBg, isDark: isDark),
                  ),

                  const Gap(48),

                  // ── FOOTER ────────────────────────────────────────────
                  FadeInUp(
                    delay: const Duration(milliseconds: 900),
                    child: _Footer(primary: primary, onBg: onBg),
                  ),

                  // Bottom space for floating nav bar
                  const Gap(100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO SECTION
//
// Oversized stacked typography: "OPEN" on one line, "PLAYER" on the next,
// with an animated breathing orb behind the logo.
// The orb is in a RepaintBoundary so its animation doesn't repaint the text.
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.orb,
    required this.primary,
    required this.onBg,
    required this.isDark,
    required this.appLogo,
    required this.mq,
  });

  final Animation<double> orb;
  final Color primary;
  final Color onBg;
  final bool isDark;
  final String appLogo;
  final Size mq;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: massive editorial typography ──────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "OPEN" — thin weight for contrast with "PLAYER"
                SlideInLeft(
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    'OPEN',
                    style: TextStyle(
                      fontSize: mq.width >= 600 ? 72 : 56,
                      fontFamily: AppFonts.poppins,
                      fontWeight: FontWeight.w200,
                      letterSpacing: -2,
                      color: onBg.withValues(alpha: 0.85),
                      height: 1.0,
                    ),
                  ),
                ),

                // "PLAYER" — heavy weight, primary colour tint
                SlideInLeft(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 800),
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [primary, onBg],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      'PLAYER',
                      style: TextStyle(
                        fontSize: mq.width >= 600 ? 72 : 56,
                        fontFamily: AppFonts.poppins,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -3,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

                const Gap(12),

                // Version badge — small, tucked under the title
                SlideInLeft(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 700),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: primary.withValues(alpha: 0.12),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      AppStrings.appVersion,
                      style: TextStyle(
                        color: primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        fontFamily: AppFonts.poppins,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Gap(16),

          // ── Right: logo floating on animated orb ───────────────────
          SizedBox(
            width: mq.width * 0.32,
            height: mq.width * 0.32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Breathing orb — isolated in RepaintBoundary
                RepaintBoundary(
                  child: _AmbientOrb(animation: orb, primary: primary),
                ),

                // App logo on top
                SlideInDown(
                  duration: const Duration(milliseconds: 900),
                  child: Link(
                    uri: Uri.parse('https://frkudn.github.io/player/'),
                    target: LinkTarget.blank,
                    builder: (context, followLink) => GestureDetector(
                      onTap: followLink,
                      child: SvgPicture.asset(
                        appLogo,
                        height: mq.width * 0.22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AMBIENT ORB
//
// AnimatedWidget pattern — only this widget repaints on each animation tick.
// Draws two concentric circles with different blur radii for a glow effect.
// ─────────────────────────────────────────────────────────────────────────────

class _AmbientOrb extends AnimatedWidget {
  const _AmbientOrb({
    required Animation<double> animation,
    required this.primary,
  }) : super(listenable: animation);

  final Color primary;

  @override
  Widget build(BuildContext context) {
    final double t = (listenable as Animation<double>).value;
    // Scale oscillates: 0.88 → 1.12, driven by the animation value
    final double scale = 0.88 + 0.24 * math.sin(t * math.pi);

    return Transform.scale(
      scale: scale,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            // Outer glow
            BoxShadow(
              color: primary.withValues(alpha: 0.22),
              blurRadius: 40,
              spreadRadius: 8,
            ),
            // Inner core
            BoxShadow(
              color: primary.withValues(alpha: 0.10),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: CircleAvatar(
          radius: double.infinity,
          backgroundColor: primary.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MANIFESTO STRIP
//
// Horizontally scrolling row of bold ideology phrases.
// Alternates between filled (primary tint) and outline chip styles.
// ─────────────────────────────────────────────────────────────────────────────

class _ManifestoStrip extends StatelessWidget {
  const _ManifestoStrip({required this.primary, required this.onBg});

  final Color primary;
  final Color onBg;

  static const List<String> _phrases = [
    '⚡ NO ADS',
    '🔒 NO TRACKING',
    '💸 FREE FOREVER',
    '🌐 OPEN SOURCE',
    '🛡️ PRIVACY FIRST',
    '❤️ BUILT WITH LOVE',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _phrases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final bool filled = i.isEven;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color:
                  filled ? primary.withValues(alpha: 0.12) : Colors.transparent,
              border: Border.all(
                color: filled
                    ? primary.withValues(alpha: 0.3)
                    : onBg.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Text(
              _phrases[i],
              style: TextStyle(
                color: filled ? primary : onBg.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontFamily: AppFonts.poppins,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS ROW
//
// Three editorial stat badges: lines of code (approx), contributors, rating.
// Numbers are big, labels are tiny — maximum visual impact with minimum noise.
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.primary,
    required this.onBg,
    required this.isDark,
  });

  final Color primary;
  final Color onBg;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
              child: _StatBadge(
            value: '∞',
            label: 'FREE',
            primary: primary,
            onBg: onBg,
            isDark: isDark,
          )),
          const Gap(12),
          Expanded(
              child: _StatBadge(
            value: '0',
            label: 'ADS',
            primary: primary,
            onBg: onBg,
            isDark: isDark,
          )),
          const Gap(12),
          Expanded(
              child: _StatBadge(
            value: '100%',
            label: 'LOCAL',
            primary: primary,
            onBg: onBg,
            isDark: isDark,
          )),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.value,
    required this.label,
    required this.primary,
    required this.onBg,
    required this.isDark,
  });

  final String value;
  final String label;
  final Color primary;
  final Color onBg;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(
          color: onBg.withValues(alpha: 0.07),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Big editorial number
          Text(
            value,
            style: TextStyle(
              color: primary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: AppFonts.poppins,
              height: 1,
            ),
          ),
          const Gap(4),
          // Tiny uppercase label
          Text(
            label,
            style: TextStyle(
              color: onBg.withValues(alpha: 0.35),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHILOSOPHY BLOCK
//
// The app's core philosophy as a short manifesto paragraph.
// Left-aligned with a thick primary accent bar — editorial pull-quote feel.
// ─────────────────────────────────────────────────────────────────────────────

class _PhilosophyBlock extends StatelessWidget {
  const _PhilosophyBlock({required this.primary, required this.onBg});

  final Color primary;
  final Color onBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thick accent bar
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open Source Project',
                  style: TextStyle(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontFamily: AppFonts.poppins,
                  ),
                ),
                const Gap(6),
                Text(
                  'A powerful media player built with conviction — '
                  'free from ads, subscriptions, and surveillance. '
                  'Your files stay on your device. Always.',
                  style: TextStyle(
                    color: onBg.withValues(alpha: 0.65),
                    fontSize: 14,
                    height: 1.6,
                    fontFamily: AppFonts.poppins,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEVELOPER CARD
//
// Glassmorphic card showing developer identity with monospace handle,
// tagline, and horizontal social link pills.
// The handle "@frkudn" is the centrepiece — bold monospace, primary tinted.
// ─────────────────────────────────────────────────────────────────────────────

class _DevCard extends StatelessWidget {
  const _DevCard({
    required this.primary,
    required this.onBg,
    required this.isDark,
  });

  final Color primary;
  final Color onBg;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          border: Border.all(
            color: primary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar + name/handle
            Row(
              children: [
                // Developer avatar — primary tinted circle with initial
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primary.withValues(alpha: 0.4),
                        primary.withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'F',
                      style: TextStyle(
                        color: primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: AppFonts.poppins,
                      ),
                    ),
                  ),
                ),

                const Gap(14),

                // Name + monospace handle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Furqan Uddin',
                        style: TextStyle(
                          color: onBg,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppFonts.poppins,
                        ),
                      ),
                      const Gap(2),
                      // Handle in monospace — distinctive
                      Text(
                        '@frkudn',
                        style: TextStyle(
                          color: primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFonts.sourceCodePro,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // "DEV" badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: primary.withValues(alpha: 0.12),
                    border: Border.all(
                        color: primary.withValues(alpha: 0.25), width: 1),
                  ),
                  child: Text(
                    'DEV',
                    style: TextStyle(
                      color: primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),

            const Gap(16),

            // Thin divider
            Divider(
                color: primary.withValues(alpha: 0.12),
                thickness: 1,
                height: 1),

            const Gap(16),

            // Tagline
            Text(
              'Flutter developer building FOSS tools for the open web.',
              style: TextStyle(
                color: onBg.withValues(alpha: 0.5),
                fontSize: 12,
                height: 1.5,
                fontFamily: AppFonts.poppins,
              ),
            ),

            const Gap(16),

            // Social link pills row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SocialPill(
                  icon: HugeIcons.strokeRoundedLinkedin01,
                  label: 'LinkedIn',
                  url: 'https://www.linkedin.com/in/frkudn/',
                  primary: primary,
                  onBg: onBg,
                ),
                _SocialPill(
                  icon: HugeIcons.strokeRoundedTwitter,
                  label: 'Twitter/X',
                  url: 'https://www.twitter.com/frkudn',
                  primary: primary,
                  onBg: onBg,
                ),
                _SocialPill(
                  icon: HugeIcons.strokeRoundedMail01,
                  label: 'Email',
                  url: 'mailto:frkudn@protonmail.com',
                  primary: primary,
                  onBg: onBg,
                ),
                _SocialPill(
                  icon: HugeIcons.strokeRoundedGithub,
                  label: 'GitHub',
                  url: 'https://github.com/frkudn',
                  primary: primary,
                  onBg: onBg,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOCIAL PILL — compact icon + label tappable chip
// ─────────────────────────────────────────────────────────────────────────────

class _SocialPill extends StatelessWidget {
  const _SocialPill({
    required this.icon,
    required this.label,
    required this.url,
    required this.primary,
    required this.onBg,
  });

  final IconData icon;
  final String label;
  final String url;
  final Color primary;
  final Color onBg;

  @override
  Widget build(BuildContext context) {
    return Link(
      uri: Uri.parse(url),
      target: LinkTarget.blank,
      builder: (context, followLink) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          followLink?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: onBg.withValues(alpha: 0.05),
            border: Border.all(
              color: onBg.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: primary),
              const Gap(6),
              Text(
                label,
                style: TextStyle(
                  color: onBg.withValues(alpha: 0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REPO SECTION
//
// Two large tappable cards for GitHub and GitLab — asymmetric sizing
// (GitHub slightly larger since it's the primary repo) with glow on hover.
// ─────────────────────────────────────────────────────────────────────────────

class _RepoSection extends StatelessWidget {
  const _RepoSection({
    required this.primary,
    required this.onBg,
    required this.isDark,
  });

  final Color primary;
  final Color onBg;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Text(
            'SOURCE CODE',
            style: TextStyle(
              color: onBg.withValues(alpha: 0.3),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
              fontFamily: AppFonts.poppins,
            ),
          ),
          const Gap(12),

          Row(
            children: [
              // GitHub (primary — wider)
              Expanded(
                flex: 5,
                child: _RepoCard(
                  icon: HugeIcons.strokeRoundedGithub,
                  label: 'GitHub',
                  sublabel: 'frkudn/player',
                  url: 'https://github.com/frkudn/player',
                  primary: primary,
                  onBg: onBg,
                  isDark: isDark,
                  isPrimary: true,
                ),
              ),
              const Gap(10),
              // GitLab (secondary — narrower)
              Expanded(
                flex: 4,
                child: _RepoCard(
                  icon: HugeIcons.strokeRoundedGitlab,
                  label: 'GitLab',
                  sublabel: 'Mirror',
                  url: 'https://gitlab.com/frkudn/player',
                  primary: primary,
                  onBg: onBg,
                  isDark: isDark,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepoCard extends StatelessWidget {
  const _RepoCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.url,
    required this.primary,
    required this.onBg,
    required this.isDark,
    required this.isPrimary,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final String url;
  final Color primary;
  final Color onBg;
  final bool isDark;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Link(
      uri: Uri.parse(url),
      target: LinkTarget.blank,
      builder: (context, followLink) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          followLink?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isPrimary
                ? primary.withValues(alpha: 0.1)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03)),
            border: Border.all(
              color: isPrimary
                  ? primary.withValues(alpha: 0.35)
                  : onBg.withValues(alpha: 0.08),
              width: isPrimary ? 1.5 : 1,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.12),
                      blurRadius: 16,
                      spreadRadius: -3,
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon,
                      size: 20,
                      color: isPrimary ? primary : onBg.withValues(alpha: 0.6)),
                  const Spacer(),
                  // Star CTA for primary repo
                  if (isPrimary)
                    Text(
                      '⭐ STAR',
                      style: TextStyle(
                        color: primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
              const Gap(10),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? primary : onBg.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppFonts.poppins,
                ),
              ),
              const Gap(2),
              Text(
                sublabel,
                style: TextStyle(
                  color: onBg.withValues(alpha: 0.35),
                  fontSize: 10,
                  fontFamily: AppFonts.sourceCodePro,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({required this.primary, required this.onBg});

  final Color primary;
  final Color onBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Thin full-width rule
          Divider(color: onBg.withValues(alpha: 0.08), thickness: 1),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Made with ',
                style: TextStyle(
                  color: onBg.withValues(alpha: 0.35),
                  fontSize: 12,
                  fontFamily: AppFonts.poppins,
                ),
              ),
              Text(
                '❤️',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                ' by ',
                style: TextStyle(
                  color: onBg.withValues(alpha: 0.35),
                  fontSize: 12,
                  fontFamily: AppFonts.poppins,
                ),
              ),
              Text(
                'Furqan',
                style: TextStyle(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppFonts.poppins,
                ),
              ),
            ],
          ),
          const Gap(6),
          Text(
            AppStrings.appTagline,
            style: TextStyle(
              color: onBg.withValues(alpha: 0.2),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
