import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/router/router.dart';
import 'package:open_player/data/models/audio_playlist_model.dart';
import 'package:open_player/presentation/features/audio_section/bloc/audio_playlist_bloc/audio_playlist_bloc.dart';
import 'package:velocity_x/velocity_x.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PLAYLIST TILE
//
// Card-style row for a single playlist entry in PlaylistsPage.
//
// Key improvements vs the original PlaylistTile:
//
//   • imageAsset param removed — the tile now derives artwork from the
//     playlist's own tracks. _firstThumb() safely traverses:
//       playlist.audios → first track → thumbnail list → first bytes
//     with a null/empty check at every step.
//   • Falls back to _DefaultArt (gradient + icon) when no artwork is found.
//   • Delete action opens a bottom sheet (_PlaylistOptionsSheet) instead of
//     a popup menu — easier to tap on touch screens, follows Material 3 style.
//   • Confirmation snackbar shown after deletion.
//   • Uses Material + InkWell so the ripple spans the full card.
//   • Text is in Expanded so names of any length truncate cleanly.
//   • Responsive thumbnail size: 72 dp on tablets, 62 dp on phones.
// ─────────────────────────────────────────────────────────────────────────────

class PlaylistTile extends StatelessWidget {
  const PlaylistTile({
    super.key,
    required this.title,
    required this.trackCount,
    required this.playlist,
    // imageAsset removed — artwork is derived from playlist.audios instead
  });

  final String title;
  final String trackCount;
  final AudioPlaylistModel playlist;

  @override
  Widget build(BuildContext context) {
    final Color pr = Theme.of(context).colorScheme.primary;
    final Color os = Theme.of(context).colorScheme.onSurface;
    final mq = MediaQuery.sizeOf(context);

    // Thumbnail size: slightly larger on tablets
    final double thumbSize = mq.width >= 600 ? 72.0 : 62.0;

    // Safely extract the first track's embedded artwork bytes
    final Uint8List? thumbBytes = _firstThumb(playlist);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () =>
            context.push(AppRoutes.playlistPreviewRoute, extra: playlist),
        borderRadius: BorderRadius.circular(14),
        splashColor: pr.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // color: Theme.of(context).colorScheme.surfaceContainerLowest,
            color: Colors.transparent,
            border: Border.all(color: os.withValues(alpha: 0.07)),
          ),
          child: Row(
            children: [
              // ── Artwork thumbnail ──────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: thumbSize,
                  height: thumbSize,
                  child: thumbBytes != null
                      ? Image.memory(
                          thumbBytes,
                          fit: BoxFit.cover,
                          // Fall back gracefully if bytes are corrupted
                          errorBuilder: (_, __, ___) => _DefaultArt(pr: pr),
                        )
                      : _DefaultArt(pr: pr),
                ),
              ),

              const SizedBox(width: 14),

              // ── Playlist name + track count ──────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFonts.poppins,
                        
                        // color: os,
                        color: Colors.white
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trackCount,
                      style: TextStyle(
                        fontSize: 12,
                        // color: os.withValues(alpha: 0.45),
                        color: Colors.white60
                      ),
                    ),
                  ],
                ),
              ),

              // ── Options button ────────────────────────────────────
              _MoreButton(playlist: playlist, pr: pr, os: os),
            ],
          ),
        ),
      ),
    );
  }

  /// Safely extracts the first track's embedded thumbnail bytes.
  ///
  /// Returns null when any of the following is true:
  ///   - playlist.audios is empty (no tracks added yet)
  ///   - first track has no embedded artwork (thumbnail list is empty)
  ///   - thumbnail bytes are empty (0-length Uint8List from a corrupt tag)
  Uint8List? _firstThumb(AudioPlaylistModel playlist) {
    if (playlist.audios.isEmpty) return null;

    final firstAudio = playlist.audios.first;
    if (firstAudio.thumbnail.isEmpty) return null;

    final bytes = firstAudio.thumbnail.first.bytes;
    return bytes.isNotEmpty ? bytes : null;
  }
}

// ── Default artwork placeholder ────────────────────────────────────────────────
// Shown when no track thumbnail is available.
// Gradient background + music-queue icon gives each empty playlist a
// consistent but brand-consistent look.

class _DefaultArt extends StatelessWidget {
  const _DefaultArt({required this.pr});
  final Color pr;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pr.withValues(alpha: 0.30),
            pr.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.queue_music_rounded,
          color: pr.withValues(alpha: 0.50),
          size: 24,
        ),
      ),
    ).glassMorphic(borderRadius: BorderRadius.circular(10), blur: 4);
  }
}

// ── More options button ────────────────────────────────────────────────────────

class _MoreButton extends StatelessWidget {
  const _MoreButton({
    required this.playlist,
    required this.pr,
    required this.os,
  });

  final AudioPlaylistModel playlist;
  final Color pr, os;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        HugeIcons.strokeRoundedMoreVertical,
        size: 20,
        // color: os.withValues(alpha: 0.40),
        color: Colors.white,
      ),
      onPressed: () => _showOptions(context),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaylistOptionsSheet(
        playlist: playlist,
        pr: pr,
        os: os,
        // Pass the bloc so the sheet can dispatch events after popping
        bloc: context.read<AudioPlaylistBloc>(),
      ),
    );
  }
}

// ── Options bottom sheet ───────────────────────────────────────────────────────
// A StatelessWidget that receives the BLoC directly to avoid a
// "BlocProvider not found" error inside the modal's isolated widget tree.

class _PlaylistOptionsSheet extends StatelessWidget {
  const _PlaylistOptionsSheet({
    required this.playlist,
    required this.pr,
    required this.os,
    required this.bloc,
  });

  final AudioPlaylistModel playlist;
  final Color pr, os;
  final AudioPlaylistBloc bloc;

  @override
  Widget build(BuildContext context) {
    // Use a dark translucent background in dark mode for depth
    final Color bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF141420)
        : Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: os.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: os.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Playlist name
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              playlist.name,
              style: TextStyle(
                color: os,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: AppFonts.poppins,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Delete option
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 18,
              ),
            ),
            title: const Text(
              'Delete Playlist',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'This cannot be undone',
              style: TextStyle(
                color: Colors.red.withValues(alpha: 0.50),
                fontSize: 11,
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context); // Close the sheet first

              // Dispatch to the bloc we received — safe even after pop
              bloc.add(DeletePlaylistEvent(playlist));

              // Brief confirmation snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${playlist.name}" deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
