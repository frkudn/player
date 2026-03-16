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

            // ── Stats bar (video count + storage) ────────────────────
            _StatsBar(primary: primary, onSurface: onSurface),

            // ── Filter chips ─────────────────────────────────────────
            VideoPageTitleAndSortingButtonWidget(
                selectedFilter: selectedFilter),

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
  final ValueNotifier<VideoViewMode> viewMode;

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
        // Folder / List toggle
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
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: viewMode.value == VideoViewMode.folders
                    ? primary.withValues(alpha: 0.14)
                    : onSurface.withValues(alpha: 0.06),
                border: Border.all(
                  color: viewMode.value == VideoViewMode.folders
                      ? primary.withValues(alpha: 0.32)
                      : onSurface.withValues(alpha: 0.09),
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
                        : onSurface.withValues(alpha: 0.45),
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Folders',
                    style: TextStyle(
                      color: viewMode.value == VideoViewMode.folders
                          ? primary
                          : onSurface.withValues(alpha: 0.45),
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
              color: onSurface.withValues(alpha: 0.06),
            ),
            child: IconButton(
              onPressed: () =>
                  GoRouter.of(context).push(AppRoutes.searchVideosRoute),
              icon: Icon(Icons.search_rounded,
                  color: onSurface.withValues(alpha: 0.65)),
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

// ── Stats bar ──────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.primary, required this.onSurface});
  final Color primary;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: BlocBuilder<VideosBloc, VideosState>(
        builder: (context, state) {
          if (state is! VideosSuccess) return const SizedBox.shrink();

          final total =
              state.videos.where((v) => !v.title.startsWith('.')).length;
          final hidden =
              state.videos.where((v) => v.title.startsWith('.')).length;
          final totalSz =
              state.videos.fold<int>(0, (sum, v) => sum + v.fileSize);

          return FadeInDown(
            duration: const Duration(milliseconds: 280),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  _StatChip(
                    value: '$total',
                    label: 'videos',
                    icon: Icons.play_circle_outline_rounded,
                    primary: primary,
                    onSurface: onSurface,
                  ),
                  const SizedBox(width: 8),
                  if (hidden > 0)
                    _StatChip(
                      value: '$hidden',
                      label: 'hidden',
                      icon: Icons.visibility_off_outlined,
                      primary: onSurface.withValues(alpha: 0.4),
                      onSurface: onSurface,
                      subtle: true,
                    ),
                  if (hidden > 0) const SizedBox(width: 8),
                  _StatChip(
                    value: _fmtSize(totalSz),
                    label: 'total',
                    icon: Icons.storage_rounded,
                    primary: primary,
                    onSurface: onSurface,
                    subtle: true,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmtSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.primary,
    required this.onSurface,
    this.subtle = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color primary;
  final Color onSurface;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: subtle
            ? onSurface.withValues(alpha: 0.05)
            : primary.withValues(alpha: 0.08),
        border: Border.all(
          color: subtle
              ? onSurface.withValues(alpha: 0.07)
              : primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color: subtle
                  ? onSurface.withValues(alpha: 0.35)
                  : primary.withValues(alpha: 0.8)),
          const SizedBox(width: 5),
          Text(
            '$value $label',
            style: TextStyle(
              color: subtle ? onSurface.withValues(alpha: 0.45) : primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
