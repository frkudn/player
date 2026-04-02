import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/presentation/features/audio_section/bloc/audio_playlist_bloc/audio_playlist_bloc.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/playlists/widgets/playlist_floating_button.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/playlists/widgets/playlist_tile.dart';
import 'package:open_player/presentation/shared/widgets/active_audio_bg/active_playing_audio_background_widget.dart';
// The dialog is used by both the FAB (via PlaylistFloatingButton) and by the
// empty-state CTA button below — importing it here keeps both entry points
// using the same function so they stay in sync automatically.
import 'package:open_player/presentation/shared/methods/show_create_audio_playlist_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PLAYLISTS PAGE
//
// Displays user-created playlists as styled cards.
//
// Improvements vs the original:
//   • Card-based tiles (see PlaylistTile) showing actual track artwork instead
//     of a static default-profile asset.
//   • Meaningful empty state with icon, description, and a CTA button that
//     triggers the same create-playlist dialog as the FAB.
//   • Responsive horizontal padding — tablets get wider margins.
//   • Bottom padding clears both the FAB and the floating nav bar.
//   • No Divider between items — spacing alone looks cleaner on cards.
// ─────────────────────────────────────────────────────────────────────────────

class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    // Wider side padding on tablets (≥600 dp) so cards don't stretch edge-to-edge
    final double hPad = mq.width >= 600 ? mq.width * 0.08 : 14.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // FAB sits above the floating nav bar — PlaylistFloatingButton handles its
      // own bottom offset via .pOnly(bottom: 100, right: 10) internally
      floatingActionButton: const PlaylistFloatingButton(),
      body: BlocBuilder<AudioPlaylistBloc, AudioPlaylistState>(
        builder: (context, state) {
          // ── Empty state ─────────────────────────────────────────────────
          if (state.playlists.isEmpty) {
            return _EmptyPlaylists(
              onCreateTap: () {
                // Open the same dialog the FAB uses — single source of truth
                final nameNotifier = ValueNotifier<String>('');
                showCreateAudioPlaylistDialog(context, nameNotifier);
              },
            );
          }

          // ── Playlist list ───────────────────────────────────────────────
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Small count header — gives users a sense of how many playlists
              // they have without being intrusive
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 6),
                  child: Text(
                    '${state.playlists.length} '
                    '${state.playlists.length == 1 ? 'playlist' : 'playlists'}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
                sliver: SliverList.separated(
                  itemCount: state.playlists.length,
                  // Gap between cards — cleaner than a Divider line
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final playlist = state.playlists[index];
                    return PlaylistTile(
                      title: playlist.name,
                      trackCount: '${playlist.audios.length} '
                          '${playlist.audios.length == 1 ? 'track' : 'tracks'}',
                      playlist: playlist,
                    );
                  },
                ),
              ),

              // Bottom padding — clears FAB (100 dp) + floating nav bar (30 dp)
              const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
//
// Shown when the user has no playlists yet. Provides an icon, description,
// and a CTA button that opens the create-playlist dialog directly so the
// user doesn't have to hunt for the FAB.
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyPlaylists extends StatelessWidget {
  const _EmptyPlaylists({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    final Color pr = Theme.of(context).colorScheme.primary;
    final Color os = Theme.of(context).colorScheme.onSurface;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Playlist icon in a soft primary circle
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pr.withValues(alpha: 0.08),
                border:
                    Border.all(color: pr.withValues(alpha: 0.15), width: 1.5),
              ),
              child: Icon(
                Icons.queue_music_rounded,
                size: 40,
                color: pr.withValues(alpha: 0.5),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'No playlists yet',
              style: TextStyle(
                // color: os.withValues(alpha: 0.55),
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Tap + to create your first playlist\nand organize your music.',
              textAlign: TextAlign.center,
              style: TextStyle(
                // color: os.withValues(alpha: 0.35),
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            // CTA — same dialog as the FAB
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Playlist'),
              style: FilledButton.styleFrom(
                backgroundColor: pr,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
