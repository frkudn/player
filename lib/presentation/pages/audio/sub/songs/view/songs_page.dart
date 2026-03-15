import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/di/injection.dart';
import 'package:open_player/data/models/audio_model.dart';
import 'package:open_player/presentation/common/widgets/audio_tile_widget.dart';
import 'package:open_player/presentation/pages/audio/sub/songs/widgets/songs_top_bar_buttons_widget.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../../../../base/db/hive_service.dart';
import '../../../../../../data/services/favorite_audio_hive_service/audio_hive_service.dart';
import '../../../../../../logic/audio_bloc/audios_bloc.dart';

class SongsPage extends HookWidget {
  SongsPage({super.key});

  final ScrollController _controller =
      locator<ScrollController>(instanceName: "audios");
  @override
  Widget build(BuildContext context) {
    final selectedFilter = useState(SongsFiltered.all);
    final mq = MediaQuery.sizeOf(context);

    return BlocBuilder<AudiosBloc, AudiosState>(
      builder: (context, audioState) {
        if (audioState is AudiosSuccess) {
          if (audioState.allSongs.isNotEmpty) {
            final fvrKeys = MyHiveBoxes.favoriteAudios.keys;

            final allsongsByName = audioState.allSongs
                .where((audio) => !audio.title.startsWith('.'))
                .toList()
              ..sort((a, b) => a.title.compareTo(b.title));

            List<AudioModel> favoriteSongs = audioState.allSongs
                .where((audio) =>
                    FavoritesAudioHiveService().getFavoriteStatus(audio.id))
                .toList()
              ..sort((a, b) => a.title.compareTo(b.title));

            final recentlyAdded = audioState.allSongs
                .where((audio) => !audio.title.startsWith('.'))
                .toList()
              ..sort((a, b) => a.lastModified.compareTo(b.lastModified));

            final hiddenSongs = audioState.allSongs
                .where((audio) => audio.title.startsWith('.'))
                .toList()
              ..sort((a, b) => a.size.compareTo(b.size));

            final filteredSongs = _returnSongs(favoriteSongs, recentlyAdded,
                allsongsByName, hiddenSongs, selectedFilter);

            int songsLength = filteredSongs.length;

            return Stack(
              children: [
                //------------ Songs List
                RefreshIndicator(
                  onRefresh: () async {
                    context.read<AudiosBloc>().add(AudiosLoadAllEvent());
                  },
                  child: Scrollbar(
                    child: CustomScrollView(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      slivers: [
                        // Songs Length, Sort Chips
                        SliverToBoxAdapter(
                          child: SongsTopBarButtonsWidget(
                            songsLength: songsLength,
                            selectedFilter: selectedFilter,
                          ),
                        ),

                        //---- SongTiles List
                        SliverList.builder(
                          addAutomaticKeepAlives: true,
                          itemCount: songsLength,
                          itemBuilder: (context, index) {
                            return AudioTileWidget(
                              audios: filteredSongs,
                              index: index,
                              state: audioState,
                            );
                          },
                        ),

                        //--- Scroll Top
                        if (selectedFilter.value == SongsFiltered.all &&
                            allsongsByName.length > 10)
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
                          padding: EdgeInsets.only(bottom: mq.height * 0.1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: [
                "No Audios found".text.make(),
                IconButton(
                  onPressed: () {
                    context.read<AudiosBloc>().add(AudiosLoadAllEvent());
                  },
                  icon: const Icon(HugeIcons.strokeRoundedRefresh),
                ),
              ].column(alignment: MainAxisAlignment.center),
            );
          }
        } else if (audioState is AudiosLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (audioState is AudiosFailure) {
          return Center(
            child: Text(audioState.message),
          );
        } else if (audioState is AudiosInitial) {
          return "Initializing ...".text.makeCentered();
        } else {
          return "Something went wrong".text.makeCentered();
        }
      },
    );
  }

  List<AudioModel> _returnSongs(
      List<AudioModel> favorites,
      List<AudioModel> recents,
      List<AudioModel> all,
      List<AudioModel> hidden,
      ValueNotifier<SongsFiltered> selectedFilter) {
    if (selectedFilter.value == SongsFiltered.all) {
      return all;
    } else if (selectedFilter.value == SongsFiltered.favorites) {
      return favorites;
    } else if (selectedFilter.value == SongsFiltered.recents) {
      return recents.reversed.toList();
    } else {
      return hidden;
    }
  }
}
