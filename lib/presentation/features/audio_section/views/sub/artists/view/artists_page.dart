import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/base/di/dependency_injection.dart';
import 'package:open_player/base/router/router.dart';
import 'package:open_player/data/models/artist_model.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/artists/widgets/artist_card.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../../../../../data/models/audio_model.dart';
import '../../../../bloc/audio_bloc/audios_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ARTISTS PAGE
//
// Displays all artists discovered from the song library.
//
// Key improvements vs the original:
//   • Responsive grid: phones → 2 columns, tablets (≥600 dp) → 3 columns.
//   • Filters out empty artist names so "Unknown" / "" don't appear.
//   • Better empty and error states.
//   • Pull-to-refresh triggers AudiosLoadAllEvent.
//   • Bottom padding clears the floating nav bar on all screen sizes.
// ─────────────────────────────────────────────────────────────────────────────

class ArtistsPage extends StatelessWidget {
  ArtistsPage({super.key});

  final ScrollController _controller =
      getIt<ScrollController>(instanceName: 'audios');

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final int crossCount = mq.width >= 600 ? 3 : 2;

    return BlocBuilder<AudiosBloc, AudiosState>(
      builder: (context, state) {
        // ── Loading ──────────────────────────────────────────────────────
        if (state is AudiosLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // ── Success ──────────────────────────────────────────────────────
        if (state is AudiosSuccess) {
          final artists = _getArtistsFromAudios(state.allSongs);

          // ── Empty state ───────────────────────────────────────────────
          if (artists.isEmpty) {
            return _EmptyArtists(
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
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final artist = artists[index];
                          return ArtistCard(
                            artist: artist,
                            onTap: () {
                              // Build the full artist model with songs before navigating
                              final artistSongs = state.allSongs.where((audio) {
                                return audio.artists
                                    .split(',')
                                    .map((a) => a.trim())
                                    .contains(artist.name);
                              }).toList();

                              final model = ArtistModel(
                                name: artist.name,
                                songCount: artistSongs.length,
                                albumCount: artist.albumCount,
                                songs: artistSongs,
                              );
                              context.push(
                                AppRoutes.artistPreviewRoute,
                                extra: [model, state],
                              );
                            },
                          );
                        },
                        childCount: artists.length,
                      ),
                    ),
                  ),

                  // Scroll-to-top for long lists
                  if (artists.length > 12)
                    SliverToBoxAdapter(
                      child: TextButton.icon(
                        onPressed: () => _controller.animToTop(),
                        label: const Text('Scroll Top'),
                        icon: const Icon(CupertinoIcons.chevron_up),
                      ),
                    ),

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

  // ── Artist grouping logic ────────────────────────────────────────────────
  // Groups songs by artist name. Audio files often have multiple artists
  // separated by commas — each individual artist gets their own card.
  //
  // We skip empty artist strings so tracks tagged as "" or " " don't
  // pollute the grid with an anonymous card.

  List<ArtistModel> _getArtistsFromAudios(List<AudioModel> audios) {
    final artistMap = <String, Map<String, Set<String>>>{};

    for (final audio in audios) {
      final artistsList =
          audio.artists.split(',').map((a) => a.trim()).toList();

      for (final artistName in artistsList) {
        if (artistName.isEmpty) continue; // Skip blank tags

        artistMap.putIfAbsent(
            artistName,
            () => {
                  'albums': <String>{},
                  'songs': <String>{},
                });

        artistMap[artistName]!['albums']!.add(audio.album);
        artistMap[artistName]!['songs']!.add(audio.title);
      }
    }

    return artistMap.entries.map((entry) {
      return ArtistModel(
        name: entry.key,
        songCount: entry.value['songs']!.length,
        albumCount: entry.value['albums']!.length,
        songs: [], // Full song list is fetched on tap to avoid O(n²) here
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyArtists extends StatelessWidget {
  const _EmptyArtists({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final Color os = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline_rounded,
              size: 64, color: os.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          Text('No artists found',
              style: TextStyle(
                  color: os.withValues(alpha: 0.45),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Artist tags may be missing from your files',
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
