import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/data/models/artist_model.dart';
import 'package:open_player/presentation/pages/audio/sub/artists/widgets/artist_card.dart';
import '../../../../../../data/models/audio_model.dart';
import '../../../../../../logic/audio_bloc/audios_bloc.dart';

class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key});

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
          final artists = _getArtistsFromAudios(state.songs);

          if (artists.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(
                child: Text('No artists found'),
              ),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                      final artistSongs = state.songs.where((audio) {
                        // Split the audio's artists and check if this artist is in the list
                        final audioArtists = audio.artists
                            .split(',')
                            .map((a) => a.trim())
                            .toList();
                        return audioArtists.contains(artist.name);
                      }).toList();
                      // Navigate with artistSongs
                    },
                  );
                },
                childCount: artists.length,
              ),
            ),
          );
        }

        return const SliverToBoxAdapter(
          child: Center(
            child: Text('Something went wrong'),
          ),
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
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name)); // Sort alphabetically
  }
}
