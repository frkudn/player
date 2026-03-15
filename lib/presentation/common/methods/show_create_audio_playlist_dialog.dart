import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/data/models/audio_playlist_model.dart';
import 'package:open_player/logic/audio_playlist_bloc/audio_playlist_bloc.dart';
import 'package:velocity_x/velocity_x.dart';

Future<Object?> showCreateAudioPlaylistDialog(
    BuildContext context, ValueNotifier<String> playlistName) {
  return showGeneralDialog(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            "Create Playlist".text.xl2.bold.make(),
            Gap(15),
            TextField(
              onChanged: (v) {
                playlistName.value = v.trim();
              },
              decoration: InputDecoration(
                  suffixIcon: Icon(HugeIcons.strokeRoundedPlayList),
                  hintText: "playlist name"),
            ),
            Gap(10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: Text("Cancel"),
                  ),
                ),
                Gap(5),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AudioPlaylistBloc>().add(CreatePlaylistEvent(
                          AudioPlaylistModel(
                              name: playlistName.value,
                              created: DateTime.now(),
                              modified: DateTime.now(),
                              audios: [])));
                      context.pop();
                    },
                    child: Text("Create"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ),
  );
}
