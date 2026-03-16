import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/base/router/router.dart';
import 'package:open_player/data/models/video_model.dart';
import 'package:open_player/logic/audio_player_bloc/audio_player_bloc.dart';
import 'package:open_player/logic/video_player_bloc/video_player_bloc.dart';

class LastPlayedVideoPlayButtonWidget extends StatelessWidget {
  const LastPlayedVideoPlayButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Re-read on every build so state stays in sync ──────────────────
    final VideoModel? lastPlayedVideo = MyHiveBoxes.videoPlayback
        .get(MyHiveKeys.lastPlayedVideo, defaultValue: null);

    if (lastPlayedVideo == null) return const SizedBox.shrink();

    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    // Max width = screen width - FAB horizontal margins (2 × 16) - some breathing room
    final maxWidth = MediaQuery.sizeOf(context).width * 0.72;

    return Padding(
      padding: const EdgeInsets.only(bottom: 70),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          // Re-read at tap time — always fresh
          final VideoModel? lastVideo = MyHiveBoxes.videoPlayback
              .get(MyHiveKeys.lastPlayedVideo, defaultValue: null);
          context.read<AudioPlayerBloc>().add(AudioPlayerStopEvent());
          if (lastVideo != null) {
            context.read<VideoPlayerBloc>().add(
                  VideoInitializeEvent(videoIndex: 0, playlist: [lastVideo]),
                );
            GoRouter.of(context).push(AppRoutes.videoPlayerRoute);
          }
        },
        child: ConstrainedBox(
          // ── Constrain width so text can't overflow ─────────────────
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Play icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: onPrimary.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: onPrimary,
                        size: 18,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // ── Text column — Flexible so it can shrink ────────
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Continue watching',
                            style: TextStyle(
                              color: onPrimary.withValues(alpha: 0.65),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            lastPlayedVideo.title,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis, // ← now actually works
                            style: TextStyle(
                              color: onPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Arrow indicator
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: onPrimary.withValues(alpha: 0.5),
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
