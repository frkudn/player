import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/data/models/video_model.dart';
import 'package:open_player/data/services/favorites_video_hive_service/favorites_video_hive_service.dart';
import 'package:open_player/logic/videos_bloc/videos_bloc.dart';
import 'package:open_player/presentation/common/widgets/ElegantVideoTileWidget.dart';
import 'package:velocity_x/velocity_x.dart';

import 'video_page_title_and_sorting_button_widget.dart';

class VideoPageAllVideosViewWidget extends HookWidget {
  const VideoPageAllVideosViewWidget({super.key, required this.selectedFilter});

  /// A notifier to manage the currently selected video filter.
  final ValueNotifier<VideoFilter> selectedFilter;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideosBloc, VideosState>(
      builder: (context, state) {
        if (state is VideosLoading) {
          // Show a loading indicator while videos are being loaded.
          return _VideoLoading();
        } else if (state is VideosSuccess) {
          if (state.videos.isEmpty) {
            // Display a message when no videos are found.
            return SliverToBoxAdapter(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No videos found. Refresh now"),
                  IconButton(
                    onPressed: () {
                      // Reload videos when refresh is clicked.
                      context.read<VideosBloc>().add(VideosLoadEvent());
                    },
                    icon: const Icon(HugeIcons.strokeRoundedRefresh),
                  ),
                ],
              ),
            );
          }

          // Fetch keys for favorite videos from the Hive database.
          final fvrKeys = MyHiveBoxes.favoriteVideos.keys;

          // Separate videos into different categories.
          final allVideos = _filterAndSortVideos(
            state.videos,
            (video) => !video.title.startsWith('.'),
          );

          final hiddenVideos = _filterAndSortVideos(
            state.videos,
            (video) => video.title.startsWith('.'),
          );

          final recentVideos = state.videos
              .where(
                (video) => !video.title.startsWith('.'),
              )
              .toList()
              .sortedByNum(
                (element) => element.lastModified.microsecondsSinceEpoch,
              )
              .reversed
              .toList();

          final favoriteVideos = _filterAndSortVideos(
            state.videos,
            (video) =>
                fvrKeys.contains(
                  FavoritesVideoHiveService.generateKey(video.path),
                ) &&
                FavoritesVideoHiveService().getFavoriteStatus(video.path),
          );

          // Get videos based on the selected filter.
          final filteredVideos =
              _getVideos(allVideos, recentVideos, favoriteVideos, hiddenVideos);

          // Render the list of filtered videos.
          return SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverList.builder(
              itemCount: filteredVideos.length,
              itemBuilder: (context, index) {
                final video = filteredVideos[index];

                return Column(
                  children: [
                    if (index == 0)
                      // Display the total count of videos as a header.
                      [
                        "videos: ${filteredVideos.length}"
                            .text
                            .minFontSize(12)
                            .fontWeight(FontWeight.w500)
                            .make(),
                      ].row().pSymmetric(h: 12),
                    ElegantVideoTileWidget(
                      filteredVideos: filteredVideos,
                      videoTitle: video.title,
                      index: index,
                      video: video,
                    ),
                  ],
                );
              },
            ),
          );
        } else if (state is VideosFailure) {
          // Show an error message when video loading fails.
          return _VideoFailure(
            state: state,
          );
        } else if (state is VideosInitial) {
          // Show a message while the initial videos are being fetched.
          return _VideoInitial();
        } else {
          // Show a generic error message for unexpected states.
          return const SliverToBoxAdapter(
            child: Center(
              child: Text("Something went wrong."),
            ),
          );
        }
      },
    );
  }

  /// Filters and sorts videos based on a given condition.
  List<VideoModel> _filterAndSortVideos(
    List<VideoModel> videos,
    bool Function(VideoModel) condition,
  ) {
    return videos.where(condition).toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  /// Determines which videos to display based on the selected filter.
  List<VideoModel> _getVideos(
    List<VideoModel> allVideos,
    List<VideoModel> recentVideos,
    List<VideoModel> favoriteVideos,
    List<VideoModel> hiddenVideos,
  ) {
    switch (selectedFilter.value) {
      case VideoFilter.hidden:
        return hiddenVideos;
      case VideoFilter.favorites:
        return favoriteVideos;
      case VideoFilter.recentlyAdded:
        return recentVideos;
      default:
        return allVideos;
    }
  }
}

//-----------------------  Widgets ---------------------///

class _VideoInitial extends StatelessWidget {
  const _VideoInitial();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Center(
        child: Text("Fetching videos..."),
      ),
    );
  }
}

class _VideoFailure extends StatelessWidget {
  const _VideoFailure({required this.state});

  final VideosFailure state;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text(state.message),
        ),
      ),
    );
  }
}

class _VideoLoading extends StatelessWidget {
  const _VideoLoading();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
