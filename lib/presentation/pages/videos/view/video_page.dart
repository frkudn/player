import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/base/router/router.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/logic/videos_bloc/videos_bloc.dart';
import 'package:open_player/utils/extensions.dart';
import '../widgets/last_played_video_play_button_widget.dart';
import '../widgets/video_page_all_videos_view_widget.dart';
import '../widgets/video_page_title_and_sorting_button_widget.dart';

class VideosPage extends HookWidget {
  const VideosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedFilter = useState(VideoFilter.all);
    final viewMode = useState(VideoViewMode.list);
    final lc = context.languageCubit.state.languageCode;
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final onSurface = cs.onSurface;

    return Scaffold(
      floatingActionButton: const LastPlayedVideoPlayButtonWidget(),
      body: RefreshIndicator(
        color: primary,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          context.read<VideosBloc>().add(VideosLoadEvent());
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App bar ──────────────────────────────────────────────
            _VideosSliverAppBar(
              lc: lc,
              primary: primary,
              onSurface: onSurface,
              viewMode: viewMode,
            ),

            // ── Filter chips ─────────────────────────────────────────
            VideoPageTitleAndSortingButtonWidget(
              selectedFilter: selectedFilter,
            ),

            // ── Content ──────────────────────────────────────────────
            VideoPageAllVideosViewWidget(
              selectedFilter: selectedFilter,
              viewMode: viewMode,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sliver app bar ─────────────────────────────────────────────────────────────

class _VideosSliverAppBar extends StatelessWidget {
  const _VideosSliverAppBar({
    required this.lc,
    required this.primary,
    required this.onSurface,
    required this.viewMode,
  });

  final String lc;
  final Color primary;
  final Color onSurface;
  final ValueNotifier<VideoViewMode> viewMode; // ← public enum now

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      floating: true,
      snap: true,
      title: Text(
        AppStrings.videos[lc] ?? 'Videos',
        style: TextStyle(
          color: onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
      ),
      actions: [
        // View toggle: list ↔ folders
        SlideInRight(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              viewMode.value = viewMode.value == VideoViewMode.list
                  ? VideoViewMode.folders
                  : VideoViewMode.list;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: viewMode.value == VideoViewMode.folders
                    ? primary.withValues(alpha: 0.15)
                    : onSurface.withValues(alpha: 0.07),
                border: Border.all(
                  color: viewMode.value == VideoViewMode.folders
                      ? primary.withValues(alpha: 0.35)
                      : onSurface.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    viewMode.value == VideoViewMode.folders
                        ? Icons.folder_open_rounded
                        : Icons.folder_rounded,
                    color: viewMode.value == VideoViewMode.folders
                        ? primary
                        : onSurface.withValues(alpha: 0.5),
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Folders',
                    style: TextStyle(
                      color: viewMode.value == VideoViewMode.folders
                          ? primary
                          : onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Search
        SlideInRight(
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onSurface.withValues(alpha: 0.07),
            ),
            child: IconButton(
              onPressed: () =>
                  GoRouter.of(context).push(AppRoutes.searchVideosRoute),
              icon: Icon(Icons.search_rounded,
                  color: onSurface.withValues(alpha: 0.7)),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ),
      ],
    );
  }
}
