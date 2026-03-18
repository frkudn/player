import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/assets/images/app_images.dart';
import 'package:open_player/logic/audio_bloc/audios_bloc.dart';
import 'package:open_player/logic/audio_player_bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/common/widgets/quality_badge/quality_badge_widget.dart';
import 'package:open_player/presentation/pages/audio/sub/songs/widgets/audio_tile_more_button_widget.dart';
import 'package:open_player/presentation/pages/players/audio/view/audio_player.dart';
import 'package:open_player/presentation/pages/players/audio/widgets/audio_player_play_pause_button_widget.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../data/models/audio_model.dart';

class AudioTileWidget extends StatelessWidget {
  const AudioTileWidget(
      {super.key,
      required this.index,
      required this.state,
      required this.audios,
      this.showRemoveFromPlaylistButton = false,
      this.playlistRemoveOnTap});
  final int index;
  final List<AudioModel> audios;

  final AudiosSuccess state;
  final bool showRemoveFromPlaylistButton;
  final Function()? playlistRemoveOnTap;

  @override
  Widget build(BuildContext context) {
    final audio = audios[index];
    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (state) {
        return state is AudioPlayerSuccessState ? state : null;
      },
      builder: (context, playerState) {
        if (playerState == null) {
          return _AudioTile(
            songPath: audio.path,
            state: state,
            audios: audios,
            audio: audio,
            showRemoveFromPlaylistButton: showRemoveFromPlaylistButton,
            playlistRemoveOnTap: playlistRemoveOnTap,
            onTap: () {
              context.read<AudioPlayerBloc>().add(AudioPlayerInitializeEvent(
                  initialMediaIndex: index, audioList: audios));

              ///!-----Show Player Screen ----///
              showModalBottomSheet(
                showDragHandle: false,
                isScrollControlled: true,
                context: context,
                constraints: const BoxConstraints(
                    maxWidth: double.infinity), // 👈 force full width
                builder: (context) => const AudioPlayerPage(),
              );
            },
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          );
        }

        return StreamBuilder(
            stream: playerState.audioPlayerCombinedStream,
            builder: (context, snapshot) {
              int? currentIndex = snapshot.data?.currentIndex ??
                  playerState.audioPlayer.currentIndex;
              bool? isSelected = currentIndex != null
                  ? playerState.audios[currentIndex].id == audio.id
                  : null;
              return _AudioTile(
                songPath: audio.path,
                audios: audios,
                state: state,
                audio: audio,
                isSelected: isSelected,
                showRemoveFromPlaylistButton: showRemoveFromPlaylistButton,
                playlistRemoveOnTap: playlistRemoveOnTap,
                onTap: () {
                  if (isSelected != null && !isSelected) {
                    context.read<AudioPlayerBloc>().add(
                          AudioPlayerInitializeEvent(
                              initialMediaIndex: index, audioList: audios),
                        );
                  }
                  if (isSelected != null && isSelected) {
                    ///!-----Show Player Screen ----///
                    showModalBottomSheet(
                      showDragHandle: false,
                      isScrollControlled: true,
                      context: context,
                      builder: (context) => const AudioPlayerPage(),
                    );
                  }
                },
                color: isSelected != null
                    ? isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              );
            });
      },
    );
  }
}

class _AudioTile extends StatelessWidget {
  const _AudioTile({
    required this.songPath,
    required this.state,
    required this.audio,
    required this.color,
    required this.onTap,
    required this.audios,
    this.isSelected,
    this.showRemoveFromPlaylistButton = false,
    this.playlistRemoveOnTap,
  });

  final String songPath;
  final AudiosSuccess state;
  final AudioModel audio;
  final List<AudioModel> audios;

  final Function()? onTap;

  final Color color;
  final bool? isSelected;
  final bool showRemoveFromPlaylistButton;
  final Function()? playlistRemoveOnTap;

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = isSelected != null
        ? isSelected!
            ? true
            : false
        : false;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              //------ Thumbnail Image -----//
              Card(
                margin: isPlaying ? EdgeInsets.zero : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  width: isPlaying ? 77 : 70,
                  height: isPlaying ? 77 : 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: [
                    //--------- Thumbnail
                    SlideInLeft(
                      animate: true,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: audio.thumbnail.isEmpty
                            ? Image.asset(
                                AppImages.defaultProfile,
                              )
                            : Image.memory(
                                width: isPlaying ? 77 : 70,
                                height: isPlaying ? 77 : 70,
                                audio.thumbnail.first.bytes,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),

                    //------ Play Button Icon
                    if (isPlaying)
                      Center(
                        child: AudioPlayerPlayPauseButtonWidget(
                          iconSize: 25,
                        ),
                      )
                  ].stack(),
                ),
              ),

              const Gap(10),

              ///------------ Title & Artists -----------///
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //---Title
                    Text(
                      audio.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isPlaying ? Colors.white : null,
                          fontSize: 15,
                          fontWeight:
                              isPlaying ? FontWeight.bold : FontWeight.w500),
                    ),

                    //----Artist
                    Text(
                      audio.artists.toString(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 11,
                          fontFamily: AppFonts.poppins,
                          fontWeight: FontWeight.w500,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? isPlaying
                                      ? Colors.white70
                                      : Colors.grey
                                  : Colors.white54),
                    ),

                    Gap(2),

                    if (isPlaying)
                      QualityBadge(
                        quality: audio.quality,
                        isDark: true,
                        size: 10,
                      ),
                  ],
                ),
              ),

              //-------- More Button
              if (!showRemoveFromPlaylistButton)
                AudioTileMoreButtonWidget(
                  audios: audios,
                  path: songPath,
                  audio: audio,
                  isPlaying: isPlaying,
                ),

              if (showRemoveFromPlaylistButton)
                IconButton(
                    onPressed: playlistRemoveOnTap,
                    icon: Icon(Icons.playlist_remove))
            ],
          ),
        ),
      ),
    );
  }
}
