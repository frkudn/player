import 'package:color_log/color_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/data/models/audio_model.dart';
import 'package:open_player/data/services/audio_playlist_service/audio_playlist_service.dart';
import 'package:open_player/presentation/features/audio_section/bloc/audio_playlist_bloc/audio_playlist_bloc.dart';
import 'package:open_player/presentation/shared/widgets/create_new_playlist_button.dart';

Future<dynamic> showAddToPlaylistModalBottomSheet(
    BuildContext context, AudioModel audio) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      final onSurface = cs.onSurface;
      final primary = cs.primary;
      final scaffold = Theme.of(context).scaffoldBackgroundColor;
      final cardBg =
          scaffold == Colors.black ? const Color(0xFF0D0D0D) : cs.surface;

      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.12),
              blurRadius: 32,
              spreadRadius: -4,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      HugeIcons.strokeRoundedPlayList,
                      color: primary,
                      size: 18,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to Playlist',
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          audio.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: onSurface.withValues(alpha: 0.07),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: onSurface.withValues(alpha: 0.5),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Gap(16),

            // ── Create new playlist button (YOUR original widget) ─────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CreateNewPlaylistButton(),
            ),

            const Gap(12),

            // ── Section label ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: onSurface.withValues(alpha: 0.08),
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'YOUR PLAYLISTS',
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.28),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: onSurface.withValues(alpha: 0.08),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),

            const Gap(8),

            // ── Playlist list (YOUR original BlocBuilder + logic) ─────────
            Flexible(
              child: BlocBuilder<AudioPlaylistBloc, AudioPlaylistState>(
                builder: (context, state) {
                  if (state.playlists.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            HugeIcons.strokeRoundedPlayList,
                            color: onSurface.withValues(alpha: 0.18),
                            size: 48,
                          ),
                          const Gap(12),
                          Text(
                            'No playlists yet',
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.4),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    shrinkWrap: true,
                    itemCount: state.playlists.length,
                    separatorBuilder: (_, __) => Divider(
                      color: onSurface.withValues(alpha: 0.05),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final playlist = state.playlists[index];

                      // ── YOUR original logic, untouched ──────────────────
                      final alreadyAdded = AudioPlaylistService()
                          .checkIfPlaylistAlreadyHaveAudio(playlist, audio);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0, vertical: 4),
                        onTap: () {
                          // ── YOUR original onTap logic ───────────────────
                          if (!alreadyAdded) {
                            clog.debug("${playlist.name} is clicked");
                            context
                                .read<AudioPlaylistBloc>()
                                .add(AddAudioToPlaylistEvent(playlist, audio));

                            HapticFeedback.selectionClick();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        color: primary, size: 18),
                                    const Gap(10),
                                    Expanded(
                                      child: Text(
                                        '${audio.title} added to ${playlist.name}',
                                        style: TextStyle(
                                          color: onSurface,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: cardBg,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                      color: onSurface.withValues(alpha: 0.08)),
                                ),
                                margin:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                          context.pop();
                        },
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: alreadyAdded
                                ? onSurface.withValues(alpha: 0.06)
                                : primary.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            HugeIcons.strokeRoundedPlayList,
                            color: alreadyAdded
                                ? onSurface.withValues(alpha: 0.3)
                                : primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          playlist.name,
                          style: TextStyle(
                            color: alreadyAdded
                                ? onSurface.withValues(alpha: 0.4)
                                : onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: alreadyAdded
                            ? Text(
                                'Already in playlist',
                                style: TextStyle(
                                  color: onSurface.withValues(alpha: 0.28),
                                  fontSize: 11,
                                ),
                              )
                            : null,
                        trailing: alreadyAdded
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: onSurface.withValues(alpha: 0.06),
                                ),
                                child: Text(
                                  'Added',
                                  style: TextStyle(
                                    color: onSurface.withValues(alpha: 0.3),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            : Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primary.withValues(alpha: 0.12),
                                ),
                                child: Icon(
                                  Icons.playlist_add_rounded,
                                  color: primary,
                                  size: 17,
                                ),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
