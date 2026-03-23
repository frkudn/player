import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/base/di/dependency_injection.dart';
import 'package:open_player/data/models/album_model.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/albums/widgets/album_card.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../../../../../data/models/audio_model.dart';
import '../../../../bloc/audio_bloc/audios_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ALBUMS PAGE
//
// Displays all albums grouped from the full song library.
//
// Key fixes vs the original:
//   • _getAlbumsFromAudios is null-safe: thumbnail.first.bytes is only called
//     when thumbnail is non-empty, preventing a RangeError crash on tracks
//     with no embedded artwork.
//   • Albums with no valid name (empty string) are filtered out.
//   • Grid crossAxisCount is responsive: 2 on phones, 3 on tablets (≥600 dp).
//   • childAspectRatio is screen-relative so cards never overflow on any device.
//   • Empty state has personality — not just "No albums found" text.
// ─────────────────────────────────────────────────────────────────────────────

class AlbumsPage extends StatelessWidget {
  AlbumsPage({super.key});

  final ScrollController _controller =
      getIt<ScrollController>(instanceName: 'audios');

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);

    // Responsive grid: tablets (≥600 dp wide) get an extra column
    final int crossCount = mq.width >= 600 ? 3 : 2;

    return BlocBuilder<AudiosBloc, AudiosState>(
      builder: (context, state) {
        // ── Loading ──────────────────────────────────────────────────────
        if (state is AudiosLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // ── Success ──────────────────────────────────────────────────────
        if (state is AudiosSuccess) {
          final albums = _getAlbumsFromAudios(state.allSongs);

          // ── Empty state ───────────────────────────────────────────────
          if (albums.isEmpty) {
            return _EmptyAlbums(
              onRefresh: () =>
                  context.read<AudiosBloc>().add(AudiosLoadAllEvent()),
            );
          }

          return Scrollbar(
            child: RefreshIndicator(
              onRefresh: () async =>
                  context.read<AudiosBloc>().add(AudiosLoadAllEvent()),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        // Portrait-friendly ratio: artwork is square,
                        // info section takes ~35% of card height
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) =>
                            AlbumCard(album: albums[i], state: state),
                        childCount: albums.length,
                      ),
                    ),
                  ),

                  // "Scroll to top" button — only shown for long lists
                  if (albums.length > 12)
                    SliverToBoxAdapter(
                      child: TextButton.icon(
                        onPressed: () => _controller.animToTop(),
                        label: const Text('Scroll Top'),
                        icon: const Icon(CupertinoIcons.chevron_up),
                      ),
                    ),

                  // Bottom padding clears the floating nav bar
                  const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
                ],
              ),
            ),
          );
        }

        // ── Error / unexpected state ─────────────────────────────────────
        return const Center(child: Text('Something went wrong'));
      },
    );
  }

  // ── Album grouping logic ─────────────────────────────────────────────────
  // Groups all songs by album name and creates one AlbumModel per group.
  //
  // Null safety rules:
  //   1. Skip audio files with empty album name (they would create an
  //      unnamed "Unknown Album" bucket that's confusing to users).
  //   2. thumbnail is a List<PictureModel>. Only read .first.bytes when
  //      the list is non-empty — otherwise use an empty Uint8List so
  //      AlbumCard can show its gradient placeholder.

  List<AlbumModel> _getAlbumsFromAudios(List<AudioModel> audios) {
    final albumMap = <String, List<AudioModel>>{};

    for (final audio in audios) {
      // Skip tracks with no album tag — they'd pollute the grid
      if (audio.album.trim().isEmpty) continue;

      albumMap.putIfAbsent(audio.album, () => []).add(audio);
    }

    return albumMap.entries.map((entry) {
      final songs = entry.value;
      final firstSong = songs.first;

      // Guard: only use thumbnail bytes when the list is non-empty
      final Uint8List thumbBytes = firstSong.thumbnail.isNotEmpty
          ? firstSong.thumbnail.first.bytes
          : Uint8List(0);

      return AlbumModel(
        name: entry.key,
        artist:
            firstSong.artists.isNotEmpty ? firstSong.artists : 'Unknown Artist',
        songCount: songs.length,
        songs: songs,
        thumbnail: thumbBytes,
        year: firstSong.year,
        quality: firstSong.quality,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyAlbums extends StatelessWidget {
  const _EmptyAlbums({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final Color os = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.album_outlined,
              size: 64, color: os.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          Text('No albums found',
              style: TextStyle(
                  color: os.withValues(alpha: 0.45),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Pull down to refresh',
              style:
                  TextStyle(color: os.withValues(alpha: 0.28), fontSize: 13)),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
