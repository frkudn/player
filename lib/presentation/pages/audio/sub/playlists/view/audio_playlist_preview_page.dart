import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/data/models/audio_model.dart';
import 'package:open_player/data/models/audio_playlist_model.dart';
import 'package:open_player/logic/audio_playlist_bloc/audio_playlist_bloc.dart';
import 'package:open_player/utils/formater.dart';
import '../../../../../../logic/audio_bloc/audios_bloc.dart';
import '../../../../../common/widgets/audio_tile_widget.dart';
import '../../../../../common/widgets/custom_back_button.dart';
import '../../../../../common/widgets/preview_sliver_app_bar/preview_sliver_app_bar.dart';

class AudioPlaylistPreviewPage extends StatelessWidget {
  const AudioPlaylistPreviewPage({super.key, required this.playlist});

  final AudioPlaylistModel playlist;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final scaffold = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      body: BlocSelector<AudiosBloc, AudiosState, AudiosSuccess?>(
        selector: (s) => s is AudiosSuccess ? s : null,
        builder: (context, audioState) {
          if (audioState == null) {
            return Center(
              child: Text('No audios found',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.35))),
            );
          }

          return BlocBuilder<AudioPlaylistBloc, AudioPlaylistState>(
            builder: (context, state) {
              final AudioPlaylistModel currentPlaylist =
                  state.playlists.firstWhere(
                (e) => e.name == playlist.name,
                orElse: () => playlist,
              );

              final List<AudioModel> audios = List.from(currentPlaylist.audios)
                ..sort((a, b) => a.lastModified.compareTo(b.lastModified));

              return CustomScrollView(
                slivers: [
                  // ── Custom playlist header ────────────────────────────
                  _PlaylistSliverAppBar(
                    playlist: currentPlaylist,
                    audios: audios,
                    primary: primary,
                    scaffold: scaffold,
                  ),

                  // ── Empty state ───────────────────────────────────────
                  if (audios.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyPlaylist(
                          primary: primary, onSurface: onSurface),
                    ),

                  // ── Section label ─────────────────────────────────────
                  if (audios.isNotEmpty)
                    SliverToBoxAdapter(
                      child: PreviewSectionHeader(
                        label: 'TRACKS',
                        trailing: Text(
                          'Modified ${Formatter.formatDateCustom(currentPlaylist.modified)}',
                          style: TextStyle(
                            color: onSurface.withValues(alpha: 0.28),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),

                  // ── Track list ────────────────────────────────────────
                  if (audios.isNotEmpty)
                    SliverList.builder(
                      addAutomaticKeepAlives: true,
                      itemCount: audios.length,
                      itemBuilder: (context, index) => AudioTileWidget(
                        audios: audios,
                        index: index,
                        state: audioState,
                        showRemoveFromPlaylistButton: true,
                        playlistRemoveOnTap: () {
                          // ── YOUR original logic untouched ─────────────
                          HapticFeedback.selectionClick();
                          context.read<AudioPlaylistBloc>().add(
                              RemoveAudioFromPlaylistEvent(
                                  currentPlaylist, audios[index]));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${audios[index].title} removed from ${currentPlaylist.name}',
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ── Playlist-specific sliver app bar (icon instead of photo) ──────────────────

class _PlaylistSliverAppBar extends StatelessWidget {
  const _PlaylistSliverAppBar({
    required this.playlist,
    required this.audios,
    required this.primary,
    required this.scaffold,
  });

  final AudioPlaylistModel playlist;
  final List<AudioModel> audios;
  final Color primary;
  final Color scaffold;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      expandedHeight: 340,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background: gradient mesh
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withValues(alpha: 0.55),
                    primary.withValues(alpha: 0.2),
                    scaffold.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Noise dots pattern
            Positioned.fill(
              child: CustomPaint(
                painter:
                    _DotPatternPainter(color: primary.withValues(alpha: 0.06)),
              ),
            ),

            // Glow orb
            Positioned(
              top: 40,
              right: 30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.2),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: const SizedBox.expand(),
                ),
              ),
            ),

            // Scaffold colour bleed from bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
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
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glass icon card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: -6,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          HugeIcons.strokeRoundedPlaylist01,
                          color: primary,
                          size: 38,
                        ),
                      ),
                    ),
                  ),

                  const Gap(14),

                  // Playlist name
                  Text(
                    playlist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 16,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  const Gap(10),

                  // Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      GlassChip(
                        label: '${audios.length} songs',
                        icon: Icons.music_note_rounded,
                        isPrimary: true,
                        primary: primary,
                      ),
                      GlassChip(
                        label:
                            'Created ${Formatter.formatDate(playlist.created)}',
                        icon: Icons.calendar_today_rounded,
                        primary: primary,
                      ),
                    ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      _GlassBackButton(primary: primary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dot pattern painter ────────────────────────────────────────────────────────

class _DotPatternPainter extends CustomPainter {
  final Color color;
  const _DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 22.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) => old.color != color;
}

// ── Empty playlist ─────────────────────────────────────────────────────────────

class _EmptyPlaylist extends StatelessWidget {
  const _EmptyPlaylist({required this.primary, required this.onSurface});
  final Color primary;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(HugeIcons.strokeRoundedPlaylist01,
              size: 60, color: onSurface.withValues(alpha: 0.12)),
          const Gap(16),
          Text('This playlist is empty',
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.4),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const Gap(6),
          Text('Add songs to get started',
              style: TextStyle(
                  color: onSurface.withValues(alpha: 0.25), fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Glass back button (reused) ─────────────────────────────────────────────────

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.13),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: const CustomBackButton(),
        ),
      ),
    );
  }
}
