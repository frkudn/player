import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/base/assets/images/app_images.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/router/router.dart';
import 'package:open_player/data/models/album_model.dart';
import 'package:open_player/presentation/features/audio_section/bloc/audio_bloc/audios_bloc.dart';
import '../../../../../../shared/widgets/quality_badge/quality_badge_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ALBUM CARD
//
// Tappable grid card showing album artwork, name, artist, song count,
// and audio quality badge.
//
// Null safety:
//   album.thumbnail is a Uint8List — it can be empty (0 bytes) when the
//   audio file has no embedded artwork. We guard every access with
//   album.thumbnail.isNotEmpty so we never pass an empty list to Image.memory.
//
// Responsive:
//   The card uses Expanded flex ratios so it fills whatever height the parent
//   SliverGrid cell provides. crossAxisCount is set by the parent page
//   (2 on phone, 3 on tablet).
// ─────────────────────────────────────────────────────────────────────────────

class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.album,
    required this.state,
  });

  final AlbumModel album;
  final AudiosSuccess state;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;
    final bool hasThumbnail = album.thumbnail.isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () =>
            context.push(AppRoutes.albumPreviewRoute, extra: [album, state]),
        borderRadius: BorderRadius.circular(16),
        splashColor: primary.withValues(alpha: 0.12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Card background — subtle surface tint
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
              // ── Album artwork ────────────────────────────────────────
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: hasThumbnail
                      ? Image.memory(
                          album.thumbnail,
                          fit: BoxFit.cover,
                          // Graceful fallback if bytes are malformed
                          errorBuilder: (_, __, ___) => _PlaceholderArt(
                              primary: primary, name: album.name),
                        )
                      : _PlaceholderArt(primary: primary, name: album.name),
                ),
              ),

              // ── Album info ───────────────────────────────────────────
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Album name + artist
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: AppFonts.poppins,
                              color: onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            album.artist.isNotEmpty
                                ? album.artist
                                : 'Unknown Artist',
                            style: TextStyle(
                              fontSize: 10,
                              color: onSurface.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Song count + quality badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${album.songCount} songs',
                            style: TextStyle(
                              fontSize: 10,
                              color: onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                          QualityBadge(quality: album.quality),
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

// ── Placeholder when no embedded artwork is available ────────────────────────
// Shows a colored gradient with the first letter of the album name.
// This is much more informative and visually interesting than a grey square.

class _PlaceholderArt extends StatelessWidget {
  const _PlaceholderArt({required this.primary, required this.name});

  final Color primary;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.35),
            primary.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '♪',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: primary.withValues(alpha: 0.7),
            fontFamily: AppFonts.poppins,
          ),
        ),
      ),
    );
  }
}
