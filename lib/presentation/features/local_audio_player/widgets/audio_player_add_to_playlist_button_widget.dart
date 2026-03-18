import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/data/models/audio_model.dart';
import 'package:open_player/presentation/features/local_audio_player/bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/shared/methods/show_add_to_playlist_modal_bottom_sheet.dart';
import 'package:open_player/presentation/shared/widgets/nothing_widget.dart';
import 'package:velocity_x/velocity_x.dart';

class AudioPlayerAddToPlaylistButtonWidget extends StatelessWidget {
  const AudioPlayerAddToPlaylistButtonWidget({
    super.key,
  });


  @override
  Widget build(BuildContext context) {
    return [
       BlocSelector<AudioPlayerBloc, AudioPlayerState,
              AudioPlayerSuccessState?>(
            selector: (state) {
              return state is AudioPlayerSuccessState ? state : null;
            },
            builder: (context, state) {
              if (state == null) return nothing;
          return StreamBuilder(
              stream: state.audioPlayer.currentIndexStream,
              builder: (context, snapshot) {
                final int? currentIndex =
                    snapshot.data ?? state.audioPlayer.currentIndex;
                final AudioModel? audio =
                    currentIndex != null ? state.audios[currentIndex] : null;
                return IconButton(
                  onPressed: () {
                    if (audio != null) {
                      context.pop();
                      showAddToPlaylistModalBottomSheet(context, audio);
                    }
                  },
                  icon: Icon(
                    Icons.playlist_add_outlined,
                    color: Colors.white,
                    size: 35,
                  ),
                );
              });
        },
      ),
      "Add to Playlist".text.xs.white.make(),
    ].column();
  }
}
