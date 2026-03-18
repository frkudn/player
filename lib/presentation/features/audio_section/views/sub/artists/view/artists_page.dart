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

class ArtistsPage extends StatelessWidget {
  ArtistsPage({super.key});

  final ScrollController _controller =
      getIt<ScrollController>(instanceName: "audios");
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudiosBloc, AudiosState>(
      builder: (context, state) {
        if (state is AudiosLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AudiosSuccess) {
          final artists = _getArtistsFromAudios(state.allSongs);

          if (artists.isEmpty) {
            return Center(
              child: Text('No artists found'),
            );
          }

          return Scrollbar(
            child: CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16.0, bottom: 0, top: 40),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final artist = artists[index];
                        return ArtistCard(
                          artist: artist,
                          onTap: () {
                            // Navigate to artist details with filtered songs
                            final artistSongs = state.allSongs.where((audio) {
                              // Split the audio's artists and check if this artist is in the list
                              final audioArtists = audio.artists
                                  .split(',')
                                  .map((a) => a.trim())
                                  .toList();
                              return audioArtists.contains(artist.name);
                            }).toList();
                            // Navigate with artistSongs

                            final model = ArtistModel(
                                name: artist.name,
                                songCount: artistSongs.length,
                                albumCount: artist.albumCount,
                                songs: artistSongs);
                            context.push(AppRoutes.artistPreviewRoute,
                                extra: [model, state]);
                          },
                        );
                      },
                      childCount: artists.length,
                    ),
                  ),
                ),

                //--- Scroll Top
                if (artists.length > 10)
                  SliverToBoxAdapter(
                    child: TextButton.icon(
                      onPressed: () {
                        _controller.animToTop();
                      },
                      label: "Scroll Top".text.make(),
                      icon: Icon(CupertinoIcons.chevron_up),
                    ),
                  ),

                //------- Padding
                SliverPadding(
                  padding: EdgeInsets.only(bottom: 100),
                ),
              ],
            ),
          );
        }

        return Center(
          child: Text('Something went wrong'),
        );
      },
    );
  }

  //---------------- Methods -------------------//

  List<ArtistModel> _getArtistsFromAudios(List<AudioModel> audios) {
    // Create a map to group songs by artist
    final artistMap = <String, Map<String, Set<String>>>{};

    for (var audio in audios) {
      // Split artists string by comma and trim whitespace
      final artistsList =
          audio.artists.split(',').map((a) => a.trim()).toList();

      // If the string doesn't contain commas, artistsList will have just one item
      for (var artistName in artistsList) {
        // Skip empty artist names
        if (artistName.isEmpty) continue;

        if (!artistMap.containsKey(artistName)) {
          artistMap[artistName] = {
            'albums': <String>{},
            'songs': <String>{},
          };
        }

        artistMap[artistName]!['albums']!.add(audio.album);
        artistMap[artistName]!['songs']!.add(audio.title);
      }
    }

    // Convert the map to list of Artist objects
    return artistMap.entries.map((entry) {
      return ArtistModel(
        name: entry.key,
        songCount: entry.value['songs']!.length,
        albumCount: entry.value['albums']!.length,
        songs: [],
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name)); // Sort alphabetically
  }
}
