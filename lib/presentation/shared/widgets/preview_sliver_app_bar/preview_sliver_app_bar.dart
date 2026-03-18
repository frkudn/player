import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:open_player/presentation/shared/widgets/custom_back_button.dart';

// ─── Shared Sliver App Bar ────────────────────────────────────────────────────

class PreviewSliverAppBar extends StatelessWidget {
  const PreviewSliverAppBar({
    super.key,
    required this.backgroundImage,
    required this.title,
    required this.infoRow,
    this.thumbnailImage,
    this.thumbnailIsCircle = false,
    this.onThumbnailTap,
    this.accentColor,
  });

  final ImageProvider? backgroundImage;
  final ImageProvider? thumbnailImage;
  final String title;
  final Widget infoRow;
  final bool thumbnailIsCircle;
  final VoidCallback? onThumbnailTap;

  /// Optional dominant color extracted from art (pass null to use primary)
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scaffold = Theme.of(context).scaffoldBackgroundColor;
    final primary = accentColor ?? Theme.of(context).colorScheme.primary;

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      expandedHeight: 380,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _AppBarBackground(
          backgroundImage: backgroundImage,
          thumbnailImage: thumbnailImage,
          title: title,
          infoRow: infoRow,
          scaffoldBg: scaffold,
          primary: primary,
          thumbnailIsCircle: thumbnailIsCircle,
          onThumbnailTap: onThumbnailTap,
        ),
      ),
    );
  }
}

class _AppBarBackground extends StatelessWidget {
  const _AppBarBackground({
    required this.backgroundImage,
    required this.thumbnailImage,
    required this.title,
    required this.infoRow,
    required this.scaffoldBg,
    required this.primary,
    required this.thumbnailIsCircle,
    this.onThumbnailTap,
  });

  final ImageProvider? backgroundImage;
  final ImageProvider? thumbnailImage;
  final String title;
  final Widget infoRow;
  final Color scaffoldBg;
  final Color primary;
  final bool thumbnailIsCircle;
  final VoidCallback? onThumbnailTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Full bleed background ─────────────────────────────────
          if (backgroundImage != null)
            Image(
              image: backgroundImage!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primary.withValues(alpha: 0.6),
                    primary.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),

          // ── 2. Global blur over entire image ─────────────────────────
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: const SizedBox.expand(),
            ),
          ),

          // ── 3. Dark scrim so text always readable ─────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.0, 0.3, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // ── 4. Scaffold colour bleeds up from bottom ──────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [scaffoldBg, Colors.transparent],
                ),
              ),
            ),
          ),

          // ── 5. Primary colour accent glow (bottom-left) ───────────────
          Positioned(
            bottom: 60,
            left: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.18),
              ),
            ),
          ),

          // ── 6. Bottom content: thumbnail + title + info ───────────────
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thumbnail + title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Thumbnail
                    if (thumbnailImage != null)
                      GestureDetector(
                        onTap: onThumbnailTap,
                        child: _GlassThumbnail(
                          image: thumbnailImage!,
                          isCircle: thumbnailIsCircle,
                          primary: primary,
                        ),
                      ),

                    if (thumbnailImage != null) const Gap(16),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.15,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 20,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Gap(14),

                // Info row (chips / metadata)
                infoRow,
              ],
            ),
          ),

          // ── 7. Back button ────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _GlassBackButton(primary: primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass thumbnail ────────────────────────────────────────────────────────────

class _GlassThumbnail extends StatelessWidget {
  const _GlassThumbnail({
    required this.image,
    required this.isCircle,
    required this.primary,
  });

  final ImageProvider image;
  final bool isCircle;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final radius = isCircle ? 50.0 : 16.0;

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Image(image: image, fit: BoxFit.cover, width: 96, height: 96),
            // Glass sheen overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Glass back button ──────────────────────────────────────────────────────────

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: const CustomBackButton(),
        ),
      ),
    );
  }
}

// ── Glass info chip ────────────────────────────────────────────────────────────

class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.isPrimary = false,
    this.primary,
  });

  final String label;
  final IconData? icon;
  final bool isPrimary;
  final Color? primary;

  @override
  Widget build(BuildContext context) {
    final accent = primary ?? Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: isPrimary
                ? accent.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: isPrimary
                  ? accent.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: isPrimary ? accent : Colors.white, size: 12),
                const Gap(5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? accent : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class PreviewSectionHeader extends StatelessWidget {
  const PreviewSectionHeader({
    super.key,
    required this.label,
    this.trailing,
  });

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(8),
          Text(
            label,
            style: TextStyle(
              color: primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}
