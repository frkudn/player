import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/data/models/video_model.dart';
import 'package:open_player/data/services/favorites_video_hive_service/favorites_video_hive_service.dart';
import 'package:open_player/logic/videos_bloc/videos_bloc.dart';
import 'package:open_player/presentation/common/widgets/elegant_video_tile_widget.dart';
import 'package:open_player/utils/video_folder_grouper.dart';
import 'package:velocity_x/velocity_x.dart';
import 'video_page_title_and_sorting_button_widget.dart';

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
    return BlocBuilder<VideosBloc, VideosState>(
      builder: (context, state) {
        if (state is VideosLoading) return _LoadingSliver();
        if (state is VideosInitial) return _InitialSliver();
        if (state is VideosFailure) return _FailureSliver(state: state);

        if (state is VideosSuccess) {
          if (state.videos.isEmpty) return _EmptySliver();

          final fvrKeys = MyHiveBoxes.favoriteVideos.keys;

          final allVideos = _sorted(
              state.videos.where((v) => !v.title.startsWith('.')).toList());

          final hiddenVideos = _sorted(
              state.videos.where((v) => v.title.startsWith('.')).toList());

          final recentVideos = state.videos
              .where((v) => !v.title.startsWith('.'))
              .toList()
              .sortedByNum((v) => v.lastModified.microsecondsSinceEpoch)
              .reversed
              .toList();

          final favoriteVideos = _sorted(state.videos
              .where((v) =>
                  fvrKeys.contains(
                      FavoritesVideoHiveService.generateKey(v.path)) &&
                  FavoritesVideoHiveService().getFavoriteStatus(v.path))
              .toList());

          final filtered = _getFiltered(
              allVideos, recentVideos, favoriteVideos, hiddenVideos);

          // ── Folder view ──────────────────────────────────────────────
          if (viewMode.value == VideoViewMode.folders) {
            final folders = VideoFolderGrouper.group(allVideos);
            return _FolderGridSliver(folders: folders);
          }

          // ── List view ────────────────────────────────────────────────
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final video = filtered[index];
                return FadeInUp(
                  duration:
                      Duration(milliseconds: 200 + (index * 20).clamp(0, 300)),
                  child: ElegantVideoTileWidget(
                    filteredVideos: filtered,
                    videoTitle: video.title,
                    index: index,
                    video: video,
                  ),
                );
              },
            ),
          );
        }

        return const SliverToBoxAdapter(
          child: Center(child: Text('Something went wrong')),
        );
      },
    );
  }

  List<VideoModel> _sorted(List<VideoModel> v) =>
      v..sort((a, b) => a.title.compareTo(b.title));

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
        itemBuilder: (context, index) {
          return FadeInUp(
            duration: Duration(milliseconds: 180 + (index * 30).clamp(0, 400)),
            child: _FolderCard(folder: folders[index]),
          );
        },
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
          border: Border.all(
            color: onSurface.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
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
              // ── Cover image area ───────────────────────────────────
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail or fallback gradient
                    if (folder.coverVideo.thumbnail != null)
                      Image.memory(
                        folder.coverVideo.thumbnail!,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primary.withValues(alpha: 0.3),
                              primary.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.folder_rounded,
                          color: primary.withValues(alpha: 0.45),
                          size: 48,
                        ),
                      ),

                    // Bottom gradient scrim
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Count badge — top right
                    Positioned(
                      top: 10,
                      right: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.black.withValues(alpha: 0.35),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${folder.count}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Folder icon — center
                    Center(
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.folder_open_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Folder name + count ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
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
          // ── Header ────────────────────────────────────────────────
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
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary.withValues(alpha: 0.45),
                          primary.withValues(alpha: 0.15),
                          scaffold,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  // Scaffold bleed from bottom
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

                  // Folder info content
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Folder icon badge
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: primary.withValues(alpha: 0.18),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(Icons.folder_rounded,
                              color: primary, size: 28),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          folder.name,
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Glass chip
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: primary.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.3),
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

                  // Back button
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
                                    color: onSurface.withValues(alpha: 0.1),
                                    border: Border.all(
                                      color: onSurface.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: onSurface,
                                      size: 18,
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

          // ── Section label ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VIDEOS',
                    style: TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Video list ─────────────────────────────────────────────
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

// ── Loading state ──────────────────────────────────────────────────────────────

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
              width: 36,
              height: 36,
              child:
                  CircularProgressIndicator(color: primary, strokeWidth: 2.5),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading videos...',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.4),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Initial state ──────────────────────────────────────────────────────────────

class _InitialSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Text(
          'Fetching videos...',
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

// ── Failure state ──────────────────────────────────────────────────────────────

class _FailureSliver extends StatelessWidget {
  const _FailureSliver({required this.state});
  final VideosFailure state;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: onSurface.withValues(alpha: 0.2), size: 56),
              const SizedBox(height: 14),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

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
                color: onSurface.withValues(alpha: 0.12), size: 72),
            const SizedBox(height: 16),
            Text(
              'No videos found',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.45),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pull down to refresh',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.28),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
