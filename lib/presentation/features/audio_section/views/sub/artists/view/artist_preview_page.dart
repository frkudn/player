import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_player/base/assets/images/app_images.dart';
import 'package:open_player/data/models/artist_model.dart';
import 'package:open_player/presentation/features/audio_section/bloc/audio_bloc/audios_bloc.dart';
import '../../../../../../shared/widgets/audio_tile_widget.dart';
import '../../../../../../shared/widgets/preview_sliver_app_bar/preview_sliver_app_bar.dart';

class ArtistPreviewPage extends StatelessWidget {
  const ArtistPreviewPage({
    super.key,
    required this.artist,
    required this.state,
  });

  final ArtistModel artist;
  final AudiosSuccess state;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final artistImg = artist.picture != null
        ? FileImage(File(artist.picture!.file.path)) as ImageProvider
        : AssetImage(AppImages.defaultProfile) as ImageProvider;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Cinematic header ──────────────────────────────────────────
          PreviewSliverAppBar(
            backgroundImage: artistImg,
            thumbnailImage: artistImg,
            thumbnailIsCircle: true,
            title: artist.name,
            infoRow: Wrap(
              spacing: 8,
              children: [
                GlassChip(
                  label: '${artist.songCount} songs',
                  icon: Icons.music_note_rounded,
                  isPrimary: true,
                  primary: primary,
                ),
              ],
            ),
          ),

          // ── Section label ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: PreviewSectionHeader(label: 'DISCOGRAPHY'),
          ),

          // ── Track list ─────────────────────────────────────────────────
          SliverList.builder(
            addAutomaticKeepAlives: true,
            itemCount: artist.songCount,
            itemBuilder: (context, index) => AudioTileWidget(
              audios: artist.songs,
              index: index,
              state: state,
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 200)),
        ],
      ),
    );
  }
}
