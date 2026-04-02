import 'package:flutter/material.dart';
import 'package:open_player/base/di/dependency_injection.dart';
import 'package:open_player/presentation/shared/widgets/miniplayer/mini_audio_player_widget.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/albums/view/albums_page.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/artists/view/artists_page.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/folders/view/audio_folders_page.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/playlists/view/audio_playlists_page.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/songs/view/songs_page.dart';
import '../../../../../shared/widgets/active_audio_bg/active_playing_audio_background_widget.dart';
import '../widgets/appbar/audio_page_app_bar_widget.dart';
import '../widgets/tabbar/audio_page_tab_bar_widget.dart';

class AudioPage extends StatelessWidget {
  const AudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        //----------- Still/Active Playing Audio Background ------//
        ActivePlayingAudioBackgroundWidget(),

        Column(children: [
          //-------- Mini Player Widget -----//
          const MiniAudioPlayerWidget(),
          Expanded(
            child: DefaultTabController(
              length: 5,
              child: NestedScrollView(
                controller: getIt<ScrollController>(instanceName: "audios"),
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    // Your existing SliverAppBar
                    const AudioPageAppBarWidget(),

                    // Your existing SliverTabBar
                    const AudioPageTabBarWidget(),
                  ];
                },
                body: TabBarView(
                  physics: NeverScrollableScrollPhysics(), // Prevent swiping
                  children: [
                    SongsPage(),
                    ArtistsPage(),
                    AlbumsPage(),
                    PlaylistsPage(),
                    AudioFoldersPage(),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ],
    ));
  }
}
