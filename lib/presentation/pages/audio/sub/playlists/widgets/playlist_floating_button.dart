import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/presentation/common/methods/show_create_audio_playlist_dialog.dart';
import 'package:velocity_x/velocity_x.dart';

class PlaylistFloatingButton extends HookWidget {
  const PlaylistFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<String> playlistName = useState("");
    return FloatingActionButton(
      onPressed: () {
        showCreateAudioPlaylistDialog(context, playlistName);
      },
      child: Icon(
        HugeIcons.strokeRoundedPlayListAdd,
      ),
    ).pOnly(bottom: 100, right: 10);
  }
}
