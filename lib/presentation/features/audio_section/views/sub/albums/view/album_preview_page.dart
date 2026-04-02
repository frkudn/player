import 'package:flutter/material.dart';
import 'package:open_player/base/assets/images/app_images.dart';
import 'package:open_player/data/models/album_model.dart';
import 'package:open_player/presentation/features/audio_section/bloc/audio_bloc/audios_bloc.dart';
import 'package:open_player/presentation/shared/widgets/active_audio_bg/active_playing_audio_background_widget.dart';
import '../../../../../../shared/widgets/audio_tile_widget.dart';
import '../../../../../../shared/widgets/preview_sliver_app_bar/preview_sliver_app_bar.dart';
import '../../../../../settings/user_profile/widgets/user_profile_preview.dart';

class AlbumPreviewPage extends StatelessWidget {
  const AlbumPreviewPage({
    super.key,
    required this.album,
    required this.state,
  });

  final AlbumModel album;
  final AudiosSuccess state;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final thumbImg = album.thumbnail.isNotEmpty
        ? MemoryImage(album.thumbnail) as ImageProvider
        : AssetImage(AppImages.defaultProfile) as ImageProvider;

    return Scaffold(
      body: Stack(
        children: [
          //---- Active Audio Background
          ActivePlayingAudioBackgroundWidget(),

          CustomScrollView(
            slivers: [
              // ── Cinematic header ─────────────────────────────────────────
              PreviewSliverAppBar(
                backgroundImage: thumbImg,
                thumbnailImage: thumbImg,
                title: album.name,
                onThumbnailTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfilePreview(bytes: album.thumbnail),
                  ),
                ),
                infoRow: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    GlassChip(
                      label: album.artist,
                      icon: Icons.person_outline_rounded,
                      primary: primary,
                    ),
                    GlassChip(
                      label: '${album.songCount} songs',
                      icon: Icons.music_note_rounded,
                      isPrimary: true,
                      primary: primary,
                    ),
                  ],
                ),
              ),
          
              // ── Section label ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: PreviewSectionHeader(label: 'TRACKS'),
              ),
          
              // ── Track list ────────────────────────────────────────────────
              SliverList.builder(
                addAutomaticKeepAlives: true,
                itemCount: album.songCount,
                itemBuilder: (context, index) => AudioTileWidget(
                  audios: album.songs,
                  index: index,
                  state: state,
                ),
              ),
          
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ],
      ),
    );
  }
}
