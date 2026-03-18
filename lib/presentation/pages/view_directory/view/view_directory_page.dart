import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_player/base/assets/fonts/styles.dart';

class ViewDirectoryPage extends StatelessWidget {
  const ViewDirectoryPage({
    super.key,
    required this.title,
    required this.path,
    required this.items,
    this.onItemTap,
  });

  final String title;
  final String path;
  final List<DirectoryItem> items;
  final void Function(DirectoryItem)? onItemTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final onSurface = cs.onSurface;
    final scaffold = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffold,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            expandedHeight: 160,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.fadeTitle],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient bg
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary.withValues(alpha: 0.35),
                          primary.withValues(alpha: 0.08),
                          scaffold,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),

                  // Scaffold bleed
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 60,
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

                  // Content
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Folder icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            color: primary.withValues(alpha: 0.15),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Icon(Icons.folder_rounded,
                              color: primary, size: 22),
                        ),
                        const SizedBox(height: 10),
                        Text(title,
                            style: TextStyle(
                              color: onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: AppFonts.poppins,
                              letterSpacing: -0.5,
                            )),
                        const SizedBox(height: 4),
                        // Breadcrumb path
                        Text(
                          path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.35),
                            fontSize: 11,
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
                                    color: onSurface.withValues(alpha: 0.08),
                                    border: Border.all(
                                      color: onSurface.withValues(alpha: 0.1),
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

          // ── Item count label ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
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
                  Text(
                    '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Directory items ───────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(
                color: onSurface.withValues(alpha: 0.05),
                height: 1,
                indent: 56,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _DirectoryTile(
                  item: item,
                  primary: primary,
                  onSurface: onSurface,
                  surfaceTint: cs.surfaceContainerHighest,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onItemTap?.call(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Directory tile ─────────────────────────────────────────────────────────────

class _DirectoryTile extends StatelessWidget {
  const _DirectoryTile({
    required this.item,
    required this.primary,
    required this.onSurface,
    required this.surfaceTint,
    required this.onTap,
  });

  final DirectoryItem item;
  final Color primary;
  final Color onSurface;
  final Color surfaceTint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: item.isFolder
                    ? primary.withValues(alpha: 0.1)
                    : onSurface.withValues(alpha: 0.06),
              ),
              child: Icon(
                item.isFolder
                    ? Icons.folder_rounded
                    : Icons.play_circle_outline_rounded,
                color:
                    item.isFolder ? primary : onSurface.withValues(alpha: 0.5),
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFonts.poppins,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.35),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing
            Icon(
              item.isFolder
                  ? Icons.chevron_right_rounded
                  : Icons.play_arrow_rounded,
              color: onSurface.withValues(alpha: 0.25),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class DirectoryItem {
  final String name;
  final String path;
  final bool isFolder;
  final String? subtitle;

  const DirectoryItem({
    required this.name,
    required this.path,
    required this.isFolder,
    this.subtitle,
  });
}
