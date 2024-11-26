import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/data/models/video_model.dart';
import 'package:open_player/data/services/favorites_video_hive_service/favorites_video_hive_service.dart';

import 'package:open_player/logic/videos_bloc/videos_bloc.dart';
import 'package:open_player/presentation/common/widgets/custom_video_tile_widget.dart';
import 'package:open_player/presentation/pages/videos/widgets/video_page_title_and_sorting_button_widget.dart';
import 'package:velocity_x/velocity_x.dart';

class VideoPageAllVideosViewWidget extends HookWidget {
  const VideoPageAllVideosViewWidget({super.key, required this.selectedFilter});

  final ValueNotifier<VideoFilter> selectedFilter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideosBloc, VideosState>(
      builder: (context, state) {
        if (state is VideosLoading) {
          // Show loading indicator while videos are being loaded
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is VideosSuccess) {
          // Show the list of videos
          if (state.videos.isEmpty) {
            return SliverToBoxAdapter(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No videos found. refresh now"),
                  IconButton(
                    onPressed: () {
                      context.read<VideosBloc>().add(VideosLoadEvent());
                    },
                    icon: const Icon(HugeIcons.strokeRoundedRefresh),
                  ),
                ],
              ),
            );
          }

          final fvrKeys = MyHiveBoxes.favoriteVideos.keys;

          //Filter out videos  whose title starts with dot &  Sorting the filtered List
          List<VideoModel> filteredVideos = state.videos
              .where((video) => selectedFilter.value == VideoFilter.hidden
                  ? video.title.startsWith('.')
                  : !video.title.startsWith('.'))
              .toList()
            ..sort((a, b) => a.title.compareTo(b.title));

          if (selectedFilter.value == VideoFilter.favorites) {
            filteredVideos = filteredVideos
                .where((video) =>
                    fvrKeys.contains(
                        FavoritesVideoHiveService.generateKey(video.path)) &&
                    FavoritesVideoHiveService().getFavoriteStatus(video.path))
                .toList()..sort((a, b) => a.title.compareTo(b.title),);
          }

          ///----------- List Builder ----------///
          return SliverPadding(
            padding: EdgeInsets.only(bottom: 100),
            sliver: SliverList.builder(
              itemCount: filteredVideos.length,
              itemBuilder: (context, index) {
                final VideoModel video = filteredVideos[index];
                final String videoTitle = video.title;
                return Column(
                  children: [
                    //------ TOP Bar --------//
                    if (index == 0)
                      [
                        "videos : ${filteredVideos.length}"
                            .text
                            .minFontSize(12)
                            .fontWeight(FontWeight.w500)
                            .make(),
                      ].row().pSymmetric(h: 12),

                    //------- CustomVideoTileWidget --------//
                    CustomVideoTileWidget(
                        filteredVideos: filteredVideos,
                        videoTitle: videoTitle,
                        index: index,
                        video: video),
                  ],
                );
              },
            ),
          );
        } else if (state is VideosFailure) {
          // Display error message if loading failed
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(state.message),
              ),
            ),
          );
        } else if (state is VideosInitial) {
          // Initial state could be informative
          return const SliverToBoxAdapter(
            child: Center(
              child: Text("Fetching videos..."),
            ),
          );
        } else {
          return const SliverToBoxAdapter(
            child: Center(
              child: Text("Something went wrong."),
            ),
          );
        }
      },
    );
  }
}
