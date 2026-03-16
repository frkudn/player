import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/data/models/video_model.dart';
import 'package:open_player/data/services/favorites_video_hive_service/favorites_video_hive_service.dart';
import 'package:open_player/logic/videos_bloc/videos_bloc.dart';
import 'package:open_player/presentation/common/widgets/elegant_video_tile_widget.dart';
import 'package:open_player/utils/video_folder_grouper.dart';
import 'package:velocity_x/velocity_x.dart';
import 'video_page_title_and_sorting_button_widget.dart';

// ── Sort options ───────────────────────────────────────────────────────────────

enum _SortBy { name, date, size }

class VideoPageAllVideosViewWidget extends HookWidget {
  const VideoPageAllVideosViewWidget({
    super.key,
    required this.selectedFilter,
    required this.viewMode,
  });

  final ValueNotifier<VideoFilter> selectedFilter;
  final ValueNotifier<VideoViewMode> viewMode;

  @override
  Widget build(BuildContext context) {
    final sortBy = useState(_SortBy.name);
    final gridMode = useState(false); // list vs grid for video tiles

    return BlocBuilder<VideosBloc, VideosState>(
      builder: (context, state) {
        if (state is VideosLoading) return _LoadingSliver();
        if (state is VideosInitial) return _InitialSliver();
        if (state is VideosFailure) return _FailureSliver(state: state);

        if (state is VideosSuccess) {
          if (state.videos.isEmpty) return _EmptySliver();

          final fvrKeys = MyHiveBoxes.favoriteVideos.keys;

          final allVideos =
              _filter(state.videos, (v) => !v.title.startsWith('.'));
          final hiddenVideos =
              _filter(state.videos, (v) => v.title.startsWith('.'));
          final recentVideos = state.videos
              .where((v) => !v.title.startsWith('.'))
              .toList()
              .sortedByNum((v) => v.lastModified.microsecondsSinceEpoch)
              .reversed
              .toList();
          final favoriteVideos = _filter(
            state.videos,
            (v) =>
                fvrKeys
                    .contains(FavoritesVideoHiveService.generateKey(v.path)) &&
                FavoritesVideoHiveService().getFavoriteStatus(v.path),
          );

          var filtered = _getFiltered(
              allVideos, recentVideos, favoriteVideos, hiddenVideos);

          // Apply sort
          filtered = _applySort(filtered, sortBy.value);

          // Folder view
          if (viewMode.value == VideoViewMode.folders) {
            final folders = VideoFolderGrouper.group(allVideos);
            return _FolderGridSliver(folders: folders);
          }

          return MultiSliver(
            slivers: [
              // Sort + grid toggle row
              SliverToBoxAdapter(
                child: _SortBar(
                  sortBy: sortBy,
                  gridMode: gridMode,
                  count: filtered.length,
                ),
              ),

              // Video list or grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                sliver: gridMode.value
                    ? _VideoGrid(videos: filtered)
                    : _VideoList(videos: filtered),
              ),
            ],
          );
        }

        return const SliverToBoxAdapter(
          child: Center(child: Text('Something went wrong')),
        );
      },
    );
  }

  List<VideoModel> _filter(
    List<VideoModel> videos,
    bool Function(VideoModel) test,
  ) =>
      videos.where(test).toList()..sort((a, b) => a.title.compareTo(b.title));

  List<VideoModel> _applySort(List<VideoModel> v, _SortBy sort) {
    switch (sort) {
      case _SortBy.name:
        return v..sort((a, b) => a.title.compareTo(b.title));
      case _SortBy.date:
        return v..sort((a, b) => b.lastModified.compareTo(a.lastModified));
      case _SortBy.size:
        return v..sort((a, b) => b.fileSize.compareTo(a.fileSize));
    }
  }

  List<VideoModel> _getFiltered(
    List<VideoModel> all,
    List<VideoModel> recent,
    List<VideoModel> fav,
    List<VideoModel> hidden,
  ) {
    switch (selectedFilter.value) {
      case VideoFilter.hidden:
        return hidden;
      case VideoFilter.favorites:
        return fav;
      case VideoFilter.recentlyAdded:
        return recent;
      default:
        return all;
    }
  }
}

// ── Multi sliver helper ────────────────────────────────────────────────────────

class MultiSliver extends StatelessWidget {
  const MultiSliver({super.key, required this.slivers});
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(slivers: slivers);
  }
}

// ── Sort bar ───────────────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.sortBy,
    required this.gridMode,
    required this.count,
  });

  final ValueNotifier<_SortBy> sortBy;
  final ValueNotifier<bool> gridMode;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final onSurface = cs.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Row(
        children: [
          // Count
          Text(
            '$count ${count == 1 ? 'video' : 'videos'}',
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.35),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const Spacer(),

          // Sort chips
          ..._SortBy.values.map((s) {
            final isActive = sortBy.value == s;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                sortBy.value = s;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(left: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isActive
                      ? primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  border: Border.all(
                    color: isActive
                        ? primary.withValues(alpha: 0.3)
                        : onSurface.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  _sortLabel(s),
                  style: TextStyle(
                    color:
                        isActive ? primary : onSurface.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 8),

          // Grid / list toggle
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              gridMode.value = !gridMode.value;
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onSurface.withValues(alpha: 0.06),
              ),
              child: Icon(
                gridMode.value
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
                color: onSurface.withValues(alpha: 0.5),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(_SortBy s) {
    switch (s) {
      case _SortBy.name:
        return 'Name';
      case _SortBy.date:
        return 'Date';
      case _SortBy.size:
        return 'Size';
    }
  }
}

// ── Video list ─────────────────────────────────────────────────────────────────

class _VideoList extends StatelessWidget {
  const _VideoList({required this.videos});
  final List<VideoModel> videos;

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final video = videos[index];
        return FadeInUp(
          duration: Duration(milliseconds: 180 + (index * 15).clamp(0, 250)),
          child: ElegantVideoTileWidget(
            filteredVideos: videos,
            videoTitle: video.title,
            index: index,
            video: video,
          ),
        );
      },
    );
  }
}

// ── Video grid ─────────────────────────────────────────────────────────────────

class _VideoGrid extends StatelessWidget {
  const _VideoGrid({required this.videos});
  final List<VideoModel> videos;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final onSurface = cs.onSurface;

    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return FadeInUp(
          duration: Duration(milliseconds: 160 + (index * 20).clamp(0, 300)),
          child: _VideoGridCard(
            video: video,
            videos: videos,
            index: index,
            primary: primary,
            onSurface: onSurface,
          ),
        );
      },
    );
  }
}

class _VideoGridCard extends StatelessWidget {
  const _VideoGridCard({
    required this.video,
    required this.videos,
    required this.index,
    required this.primary,
    required this.onSurface,
  });

  final VideoModel video;
  final List<VideoModel> videos;
  final int index;
  final Color primary;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        // Reuse your existing tile navigation
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          border:
              Border.all(color: onSurface.withValues(alpha: 0.06), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              if (video.thumbnail != null)
                Image.memory(video.thumbnail!, fit: BoxFit.cover)
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary.withValues(alpha: 0.2),
                        primary.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Icon(Icons.movie_outlined,
                      color: primary.withValues(alpha: 0.3), size: 36),
                ),

              // Gradient scrim
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Play button center
              Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 20),
                ),
              ),

              // Title bottom
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    fontFamily: AppFonts.poppins,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 6),
                    ],
                  ),
                ),
              ),

              // Ext badge
              Positioned(
                top: 8,
                right: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.black.withValues(alpha: 0.4),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        video.ext.replaceAll('.', '').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Folder grid sliver ─────────────────────────────────────────────────────────

class _FolderGridSliver extends StatelessWidget {
  const _FolderGridSliver({required this.folders});
  final List<VideoFolder> folders;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) => FadeInUp(
          duration: Duration(milliseconds: 180 + (index * 30).clamp(0, 400)),
          child: _FolderCard(folder: folders[index]),
        ),
      ),
    );
  }
}

// ── Folder card ────────────────────────────────────────────────────────────────

class _FolderCard extends StatelessWidget {
  const _FolderCard({required this.folder});
  final VideoFolder folder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final onSurface = cs.onSurface;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _FolderPreviewPage(folder: folder),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surfaceContainerHighest,
          border:
              Border.all(color: onSurface.withValues(alpha: 0.06), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              spreadRadius: -4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (folder.coverVideo.thumbnail != null)
                      Image.memory(folder.coverVideo.thumbnail!,
                          fit: BoxFit.cover)
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primary.withValues(alpha: 0.25),
                              primary.withValues(alpha: 0.06),
                            ],
                          ),
                        ),
                        child: Icon(Icons.folder_rounded,
                            color: primary.withValues(alpha: 0.4), size: 44),
                      ),

                    // Scrim
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Count badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.black.withValues(alpha: 0.35),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            child: Text('${folder.count}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                        ),
                      ),
                    ),

                    // Folder icon center
                    Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.38),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(Icons.folder_open_rounded,
                            color: Colors.white, size: 17),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      '${folder.count} ${folder.count == 1 ? 'video' : 'videos'}',
                      style: TextStyle(
                        color: primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Folder preview page ────────────────────────────────────────────────────────

class _FolderPreviewPage extends StatelessWidget {
  const _FolderPreviewPage({required this.folder});
  final VideoFolder folder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final onSurface = cs.onSurface;
    final scaffold = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary.withValues(alpha: 0.42),
                          primary.withValues(alpha: 0.12),
                          scaffold,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [scaffold, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: primary.withValues(alpha: 0.15),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.28),
                              width: 1,
                            ),
                          ),
                          child: Icon(Icons.folder_rounded,
                              color: primary, size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(folder.name,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              fontFamily: AppFonts.poppins,
                            )),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: primary.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_circle_outline_rounded,
                                    color: primary,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${folder.count} ${folder.count == 1 ? 'video' : 'videos'}',
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: onSurface.withValues(alpha: 0.09),
                                    border: Border.all(
                                      color: onSurface.withValues(alpha: 0.11),
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: onSurface,
                                      size: 17,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 12,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('VIDEOS',
                      style: TextStyle(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      )),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverList.separated(
              itemCount: folder.videos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final video = folder.videos[index];
                return ElegantVideoTileWidget(
                  filteredVideos: folder.videos,
                  videoTitle: video.title,
                  index: index,
                  video: video,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── State widgets ──────────────────────────────────────────────────────────────

class _LoadingSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child:
                  CircularProgressIndicator(color: primary, strokeWidth: 2.5),
            ),
            const SizedBox(height: 14),
            Text('Loading videos...',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.38),
                  fontSize: 13,
                )),
          ],
        ),
      ),
    );
  }
}

class _InitialSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Text('Fetching videos...',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.32),
            )),
      ),
    );
  }
}

class _FailureSliver extends StatelessWidget {
  const _FailureSliver({required this.state});
  final VideosFailure state;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: onSurface.withValues(alpha: 0.18), size: 56),
              const SizedBox(height: 14),
              Text(state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.38),
                    fontSize: 13,
                  )),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.read<VideosBloc>().add(VideosLoadEvent()),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: primary.withValues(alpha: 0.1),
                    border: Border.all(color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Text('Retry',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_library_outlined,
                color: onSurface.withValues(alpha: 0.1), size: 68),
            const SizedBox(height: 16),
            Text('No videos found',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.4),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            Text('Pull down to refresh',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.25),
                  fontSize: 13,
                )),
          ],
        ),
      ),
    );
  }
}
