import 'package:color_log/color_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/data/models/audio_model.dart';
import 'package:open_player/data/services/audio_playlist_service/audio_playlist_service.dart';
import 'package:open_player/logic/audio_playlist_bloc/audio_playlist_bloc.dart';
import 'package:open_player/presentation/common/widgets/create_new_playlist_button.dart';
import 'package:velocity_x/velocity_x.dart';

Future<dynamic> showAddToPlaylistModalBottomSheet(
    BuildContext context, AudioModel audio) {
  return showModalBottomSheet(
      context: context,
      builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Gap(5),
              "Playlists".text.xl3.bold.make(),
              Gap(10),
              CreateNewPlaylistButton(),
              BlocBuilder<AudioPlaylistBloc, AudioPlaylistState>(
                builder: (context, state) {
                  return Expanded(
                    child: ListView.builder(
                        itemCount: state.playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = state.playlists[index];
                          return ListTile(
                            title: state.playlists[index].name.text.make(),
                            leading: Icon(HugeIcons.strokeRoundedPlayList),
                            trailing: !AudioPlaylistService()
                                    .checkIfPlaylistAlreadyHaveAudio(
                                        playlist, audio)
                                ? Icon(Icons.playlist_add)
                                : null,
                            onTap: () {
                              if (!AudioPlaylistService()
                                  .checkIfPlaylistAlreadyHaveAudio(
                                      playlist, audio)) {
                                clog.debug("${playlist.name} is clicked");
                                context.read<AudioPlaylistBloc>().add(
                                    AddAudioToPlaylistEvent(playlist, audio));

                                VxToast.show(context,
                                    msg:
                                        "${audio.title} is added to the ${playlist.name} Playlist");
                              }
                              context.pop();
                            },
                            subtitle: AudioPlaylistService()
                                    .checkIfPlaylistAlreadyHaveAudio(
                                        playlist, audio)
                                ? "Audio already exists".text.make()
                                : null,
                          );
                        }),
                  );
                },
              ),
            ],
          ));
}
