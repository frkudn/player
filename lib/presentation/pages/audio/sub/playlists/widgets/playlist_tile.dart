import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/router/router.dart';
import 'package:open_player/data/models/audio_playlist_model.dart';
import 'package:open_player/logic/audio_playlist_bloc/audio_playlist_bloc.dart';
import 'package:open_player/utils/app_menu.dart';

class PlaylistTile extends StatelessWidget {
  final String title;
  final String trackCount;
  final String imageAsset;
  final AudioPlaylistModel playlist;
  const PlaylistTile(
      {super.key,
      required this.title,
      required this.trackCount,
      required this.imageAsset,
      required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        context.push(AppRoutes.playlistPreviewRoute, extra: playlist);
      },
      visualDensity: VisualDensity.adaptivePlatformDensity,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: AssetImage(imageAsset),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: AppFonts.poppins),
      ),
      subtitle: Text(
        trackCount,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      ),
      trailing: GestureDetector(
        onTapDown: (details) {
          Offset position = details.globalPosition;
          AppMenuHelper.showPopMenuAtPosition(
              context: context,
              position: position,
              items: [
                _deletePlaylist(context, playlist),
              ]);
        },
        child: Icon(HugeIcons.strokeRoundedMoreVertical,
            color: Colors.grey.shade500),
      ),
    );
  }

  //----------------------------------------------------//
  ///-----------------  Widgets  --------------------///
  ///-------------------------------------------------///

  ///--------------- Delete a Playlist
  PopupMenuItem<dynamic> _deletePlaylist(
      BuildContext context, AudioPlaylistModel playlist) {
    return PopupMenuItem(
      onTap: () {
        context.read<AudioPlaylistBloc>().add(DeletePlaylistEvent(playlist));
      },
      child: ListTile(
        title: Text("Delete"),
        trailing: Icon(Icons.delete),
      ),
    );
  }
}
