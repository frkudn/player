import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/utils/extensions.dart';
import '../../../../../../logic/audio_player_bloc/audio_player_bloc.dart';

class AudioPageTabBarWidget extends StatelessWidget {
  const AudioPageTabBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    //------ Language Code Extension --- Defined in extension on BuildContext"
    final String lc = context.languageCubit.state.languageCode;
    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (state) {
        return state is AudioPlayerSuccessState ? state : null;
      },
      builder: (context, state) {
        return SliverAppBar(
          toolbarHeight: 50,
          automaticallyImplyLeading: false,
          pinned: true,
          primary: state != null ? false : true,
          actions: [
            Expanded(
              child: TabBar(
                onTap: (value) {},
                tabs: [
                  Tab(
                    text: AppStrings.songs[lc],
                    icon: const Icon(HugeIcons.strokeRoundedMusicNoteSquare02),
                  ),
            
                  Tab(
                    text: AppStrings.artists[lc],
                    icon: const Icon(HugeIcons.strokeRoundedMusicNoteSquare01),
                  ),
                  Tab(
                    text: AppStrings.albums[lc],
                    icon: const Icon(Icons.album),
                  ),
                  Tab(
                    text: AppStrings.playlists[lc],
                    icon: const Icon(HugeIcons.strokeRoundedPlayList),
                  ),

                  Tab(
                    text: AppStrings.folders[lc],
                    icon: const Icon(HugeIcons.strokeRoundedFolder01),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
