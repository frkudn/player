import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/presentation/common/methods/show_create_audio_playlist_dialog.dart';

class CreateNewPlaylistButton extends HookWidget {
  const CreateNewPlaylistButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<String> playlistName = useState("");
    return ElevatedButton.icon(
      onPressed: () {
        showCreateAudioPlaylistDialog(context, playlistName);
      },
      icon: Icon(HugeIcons.strokeRoundedPlaylist01),
      label: Text("Create New Playlist"),
    );
  }
}
