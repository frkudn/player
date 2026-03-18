import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/base/di/dependency_injection.dart';
import 'package:open_player/data/models/album_model.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/albums/widgets/album_card.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../../../../../data/models/audio_model.dart';
import '../../../../bloc/audio_bloc/audios_bloc.dart';

class AlbumsPage extends StatelessWidget {
  AlbumsPage({super.key});

  final ScrollController _controller =
      getIt<ScrollController>(instanceName: "audios");
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudiosBloc, AudiosState>(
      builder: (context, state) {
        if (state is AudiosLoading) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is AudiosSuccess) {
          final albums = _getAlbumsFromAudios(state.allSongs);

          if (albums.isEmpty) {
            return Center(
              child: Text('No albums found'),
            );
          }

          return Scrollbar(
            child: CustomScrollView(
              physics: BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(
                      left: 16.0, right: 16.0, bottom: 5, top: 40),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final album = albums[index];
                        return AlbumCard(album: album, state: state);
                      },
                      childCount: albums.length,
                    ),
                  ),
                ),

                //--- Scroll Top
                if (albums.length > 10)
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

  //------------- Methods -------//

  List<AlbumModel> _getAlbumsFromAudios(List<AudioModel> audios) {
    // Create a map to group songs by album
    final albumMap = <String, List<AudioModel>>{};

    for (var audio in audios) {
      if (!albumMap.containsKey(audio.album)) {
        albumMap[audio.album] = [];
      }
      albumMap[audio.album]!.add(audio);
    }

    // Convert the map to list of Album objects
    return albumMap.entries.map((entry) {
      final songs = entry.value;
      // Use the first song's data for album details
      final firstSong = songs.first;

      return AlbumModel(
        name: entry.key,
        artist: firstSong.artists,
        songCount: songs.length,
        songs: songs,
        thumbnail: firstSong.thumbnail.first.bytes,
        year: firstSong.year,
        quality: firstSong.quality,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name)); // Sort alphabetically
  }
}
