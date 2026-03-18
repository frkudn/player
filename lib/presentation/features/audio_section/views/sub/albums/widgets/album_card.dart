import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/base/assets/images/app_images.dart';
import 'package:open_player/base/router/router.dart';
import 'package:open_player/data/models/album_model.dart';
import 'package:open_player/presentation/features/audio_section/bloc/audio_bloc/audios_bloc.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../../../../shared/widgets/quality_badge/quality_badge_widget.dart';

class AlbumCard extends StatelessWidget {
  final AlbumModel album;

  const AlbumCard({super.key, required this.album, required this.state});

  final AudiosSuccess state;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to album details with songs
        // You can implement navigation here
        context.push(AppRoutes.albumPreviewRoute, extra: [album, state]);
      },
      borderRadius: BorderRadius.circular(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Album Cover
          Expanded(
            flex: 3,
            child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: album.thumbnail.isNotEmpty
                    ? Image.memory(
                        album.thumbnail,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        AppImages.defaultProfile,
                        fit: BoxFit.cover,
                      )),
          ),
          // Album Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        album.artist,
                        style: TextStyle(fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${album.songCount} songs',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      QualityBadge(quality: album.quality),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ).glassMorphic(
        circularRadius: 15,
        blur: 10,
        shadowStrength: 1,
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}
