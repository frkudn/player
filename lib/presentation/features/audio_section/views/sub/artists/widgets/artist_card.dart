import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/data/models/artist_model.dart';
import 'package:velocity_x/velocity_x.dart';

class ArtistCard extends StatelessWidget {
  final ArtistModel artist;
  final VoidCallback? onTap;

  const ArtistCard({
    super.key,
    required this.artist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: Icon(
                CupertinoIcons.person,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    artist.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppFonts.poppins
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${artist.albumCount} albums',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${artist.songCount} songs',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ).glassMorphic(blur: 10,border: Border.all(color: Colors.black26)),
    );
  }
}
