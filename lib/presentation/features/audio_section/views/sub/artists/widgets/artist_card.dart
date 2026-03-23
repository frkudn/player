import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/data/models/artist_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ARTIST CARD
//
// Grid card for the Artists tab. Shows:
//   • Artist photo (from artist.picture file) if available
//   • Gradient circle avatar with first letter as fallback
//   • Name, album count, song count
//
// The original card only showed a CupertinoIcons.person icon with no
// personalization. This version uses the actual picture path stored in
// ArtistModel.picture and falls back gracefully when it's null or the file
// doesn't exist.
//
// Responsive: card fills whatever size the parent SliverGrid cell gives it.
// ─────────────────────────────────────────────────────────────────────────────

class ArtistCard extends StatelessWidget {
  const ArtistCard({
    super.key,
    required this.artist,
    this.onTap,
  });

  final ArtistModel artist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: primary.withValues(alpha: 0.12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            border: Border.all(
              color: onSurface.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: onSurface.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Artist image ─────────────────────────────────────────
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _ArtistImage(artist: artist, primary: primary),
                ),
              ),

              // ── Artist info ──────────────────────────────────────────
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Artist name
                      Text(
                        artist.name.isNotEmpty ? artist.name : 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppFonts.poppins,
                          color: onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Album count + song count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatChip(
                            value: '${artist.albumCount}',
                            label: 'albums',
                            color: onSurface,
                          ),
                          _StatChip(
                            value: '${artist.songCount}',
                            label: 'songs',
                            color: primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Artist image widget ────────────────────────────────────────────────────────
// Tries to load artist.picture (a file path). Falls back to a gradient
// avatar with the first letter of the name if the file is null or missing.

class _ArtistImage extends StatelessWidget {
  const _ArtistImage({required this.artist, required this.primary});

  final ArtistModel artist;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    // Try to resolve the artist picture file
    final File? file = artist.picture?.file;
    final bool hasFile = file != null && file.existsSync();

    if (hasFile) {
      return Image.file(
        file!,
        fit: BoxFit.cover,
        // Fall back to gradient avatar if the image fails to decode
        errorBuilder: (_, __, ___) =>
            _GradientAvatar(name: artist.name, primary: primary),
      );
    }

    return _GradientAvatar(name: artist.name, primary: primary);
  }
}

// ── Gradient avatar fallback ───────────────────────────────────────────────────
// A colored gradient rectangle showing the artist's first initial.
// Much more distinctive than a grey icon — every artist gets a unique feel
// based on the app's primary color + the initial character.

class _GradientAvatar extends StatelessWidget {
  const _GradientAvatar({required this.name, required this.primary});

  final String name;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.45),
            primary.withValues(alpha: 0.12),
          ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: primary.withValues(alpha: 0.65),
            fontFamily: AppFonts.poppins,
          ),
        ),
      ),
    );
  }
}

// ── Tiny stat chip (e.g. "3 albums") ──────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          TextSpan(
            text: ' $label',
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
