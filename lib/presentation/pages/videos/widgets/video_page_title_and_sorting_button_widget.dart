import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// ── Enums (shared across video files) ─────────────────────────────────────────

enum VideoFilter { all, recentlyAdded, favorites, hidden }

enum VideoViewMode { list, folders }

extension VideoFilterExtension on VideoFilter {
  String get displayName {
    switch (this) {
      case VideoFilter.all:
        return 'All';
      case VideoFilter.recentlyAdded:
        return 'Recent';
      case VideoFilter.favorites:
        return 'Favorites';
      case VideoFilter.hidden:
        return 'Hidden';
    }
  }

  IconData get icon {
    switch (this) {
      case VideoFilter.all:
        return Icons.play_circle_outline_rounded;
      case VideoFilter.recentlyAdded:
        return Icons.access_time_rounded;
      case VideoFilter.favorites:
        return Icons.favorite_border_rounded;
      case VideoFilter.hidden:
        return Icons.visibility_off_outlined;
    }
  }
}

// ── Widget ─────────────────────────────────────────────────────────────────────

class VideoPageTitleAndSortingButtonWidget extends HookWidget {
  const VideoPageTitleAndSortingButtonWidget({
    super.key,
    required this.selectedFilter,
  });

  final ValueNotifier<VideoFilter> selectedFilter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final onSurface = cs.onSurface;

    return SliverToBoxAdapter(
      child: FadeInDown(
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: VideoFilter.values.map((filter) {
              final isSelected = selectedFilter.value == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    selectedFilter.value = filter;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: isSelected
                          ? primary
                          : onSurface.withValues(alpha: 0.06),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : onSurface.withValues(alpha: 0.08),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                spreadRadius: -3,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          filter.icon,
                          size: 13,
                          color: isSelected
                              ? cs.onPrimary
                              : onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          filter.displayName,
                          style: TextStyle(
                            color: isSelected
                                ? cs.onPrimary
                                : onSurface.withValues(alpha: 0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
