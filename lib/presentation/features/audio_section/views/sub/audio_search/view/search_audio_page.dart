import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/audio_search/widgets/audio_search_app_bar_widget.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../../../../../data/models/audio_model.dart';
import '../../../../bloc/audio_bloc/audios_bloc.dart';
import '../../../../../../shared/widgets/nothing_widget.dart';
import '../../../../../../shared/widgets/audio_tile_widget.dart';

enum SearchFilter { all, title, artist, album, genre }

class SearchAudioPage extends HookWidget {
  const SearchAudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    //-- Language Code
    final query = useState("");
    final selectedFilter = useState(SearchFilter.all);
    final isFilterVisible = useState(false);

    List<AudioModel> filterAudios(List<AudioModel> audios, String searchQuery) {
      if (searchQuery.isEmpty) return audios;

      return audios.where((audio) {
        switch (selectedFilter.value) {
          case SearchFilter.title:
            return audio.title.toLowerCase().contains(searchQuery);
          case SearchFilter.artist:
            return audio.artists.toLowerCase().contains(searchQuery);
          case SearchFilter.album:
            return audio.album.toLowerCase().contains(searchQuery);
          case SearchFilter.genre:
            return audio.genre
                .any((g) => g.toLowerCase().contains(searchQuery));
          case SearchFilter.all:
          return audio.matchesSearch(searchQuery);
        }
      }).toList();
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar with Filter
            SliverAppBar(
              automaticallyImplyLeading: false,
              floating: true,
              expandedHeight: isFilterVisible.value ? 120 : 80,
              flexibleSpace: FlexibleSpaceBar(
                background: Column(
                  children: [
                    AudioSearchAppBarWidget(
                      query: query,
                      onFilterTap: () =>
                          isFilterVisible.value = !isFilterVisible.value,
                    ),
                    if (isFilterVisible.value)
                      Row(
                        children: SearchFilter.values.map((filter) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(
                              selected: selectedFilter.value == filter,
                              label: Text(filter.name.toUpperCase()),
                              onSelected: (selected) {
                                selectedFilter.value = filter;
                              },
                            ),
                          );
                        }).toList(),
                      ).scrollHorizontal(),
                  ],
                ),
              ),
            ),

            // Audios List
            BlocSelector<AudiosBloc, AudiosState, AudiosSuccess?>(
              selector: (state) => state is AudiosSuccess ? state : null,
              builder: (context, state) {
                if (state == null) return nothing;

                final filteredAudios =
                    filterAudios(state.allSongs, query.value);

                if (filteredAudios.isEmpty) {
                  return SliverToBoxAdapter(
                      child: "No Result".text.makeCentered().p12());
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => AudioTileWidget(
                      index: index,
                      state: state,
                      audios: filteredAudios,
                    ),
                    childCount: filteredAudios.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
