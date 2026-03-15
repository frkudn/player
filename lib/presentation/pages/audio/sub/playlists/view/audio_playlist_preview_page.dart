import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/data/models/audio_model.dart';
import 'package:open_player/data/models/audio_playlist_model.dart';
import 'package:open_player/logic/audio_playlist_bloc/audio_playlist_bloc.dart';
import 'package:open_player/utils/formater.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../../../../base/assets/fonts/styles.dart';
import '../../../../../../base/assets/images/app_images.dart';
import '../../../../../../logic/audio_bloc/audios_bloc.dart';
import '../../../../../common/widgets/audio_tile_widget.dart';
import '../../../../../common/widgets/custom_back_button.dart';

class AudioPlaylistPreviewPage extends StatelessWidget {
  const AudioPlaylistPreviewPage({super.key, required this.playlist});

  final AudioPlaylistModel playlist;

  @override
  Widget build(BuildContext context) {
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).brightness == Brightness.light
        ? Colors.black
        : Colors.white;
    return Scaffold(
      body: BlocSelector<AudiosBloc, AudiosState, AudiosSuccess?>(
        selector: (audiosState) {
          return audiosState is AudiosSuccess ? audiosState : null;
        },
        builder: (context, audioState) {
          if (audioState == null) return "No Audios found".text.make();
          return BlocBuilder<AudioPlaylistBloc, AudioPlaylistState>(
            builder: (context, state) {
              final AudioPlaylistModel currentPlaylist =
                  state.playlists.firstWhere(
                (element) => element.name == playlist.name,
              );

              final List<AudioModel> audios = currentPlaylist.audios..sort((a, b) => a.lastModified.compareTo(b.lastModified));
              return CustomScrollView(
                slivers: [
                  _AppBar(
                      playlist: currentPlaylist,
                      scaffoldColor: scaffoldColor,
                      textColor: textColor),

                  //------------- Music List ------///
                  if (playlist.audios.isNotEmpty)
                    SliverList.builder(
                      addAutomaticKeepAlives: true,
                      itemCount: audios.length,
                      itemBuilder: (context, index) {
                        return AudioTileWidget(
                          audios: audios,
                          index: index,
                          state: audioState,
                          showRemoveFromPlaylistButton: true,
                          playlistRemoveOnTap: () {
                            context.read<AudioPlaylistBloc>().add(
                                RemoveAudioFromPlaylistEvent(currentPlaylist,
                                    audios[index]));
                            VxToast.show(context,
                                msg:
                                    "${audios[index].title} is removed from ${currentPlaylist.name}");
                          },
                        );
                      },
                    ),

                  if (playlist.audios.isEmpty)
                    SliverToBoxAdapter(
                      child: "Empty Playlist".text.makeCentered(),
                    )
                ],
              );
            },
          );
        },
      ),
    );
  }
}

//---------- APPBAR --------------//
class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.playlist,
    required this.scaffoldColor,
    required this.textColor,
  });

  final AudioPlaylistModel playlist;
  final Color scaffoldColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      expandedHeight: 300,
      floating: true,
      flexibleSpace: Container(
        height: 300,
        width: double.infinity,
        //------------- Playlist Background ----------//
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage(AppImages.defaultProfile), fit: BoxFit.cover),
        ),
        child: [
          //------------- Bottom Gradient ----------//
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  scaffoldColor,
                  scaffoldColor.withValues(alpha: 0.4),
                  scaffoldColor.withValues(alpha: 0.1),
                ],
              )),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: [
              //----- Thumbnail
              Icon(
                HugeIcons.strokeRoundedPlaylist01,
                color: Theme.of(context).primaryColor,
                size: 45,
              ).p24().glassMorphic(
                  blur: 5,
                  border: Border.all(color: Colors.black26),
                  circularRadius: 15),
              Gap(20),

              //--------- Title, Songs Length, Created & Modified
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  //-------- Playlist Name
                  playlist.name.text.xl3
                      .color(textColor)
                      .fontFamily(AppFonts.poppins)
                      .fontWeight(FontWeight.w500)
                      .make(),

                  //------- Songs Length
                  [
                    "${playlist.audios.length}"
                        .text
                        .color(textColor.withValues(alpha: 0.5))
                        .size(12)
                        .bold
                        .make(),
                    " songs"
                        .text
                        .color(textColor.withValues(alpha: 0.5))
                        .size(12)
                        .color(Theme.of(context).primaryColor)
                        .bold
                        .make()
                  ].row().pSymmetric(h: 12, v: 4).glassMorphic(
                      blur: 10, border: Border.all(color: Colors.black26)),
                  Gap(5),
                  [
                    //-------Created
                    [
                      Formatter.formatDate(playlist.created)
                          .text
                          .xs
                          .size(1)
                          .gray500
                          .make(),
                      " created"
                          .text
                          .xs
                          .color(Theme.of(context).primaryColor)
                          .size(2)
                          .make()
                    ].row(),

                    //-------- Last Modified
                    [
                      "${Formatter.formatDateCustom(playlist.modified)} (${playlist.modified.hour}:${playlist.modified.minute}: ${playlist.modified.second} Time)"
                          .text
                          .xs
                          .size(1)
                          .gray500
                          .make(),
                      " last Modified"
                          .text
                          .xs
                          .color(Theme.of(context).primaryColor)
                          .size(2)
                          .make()
                    ].row(),
                  ]
                      .column(crossAlignment: CrossAxisAlignment.start)
                      .pSymmetric(h: 12, v: 5)
                      .glassMorphic(
                          blur: 3,
                          shadowStrength: 1,
                          border: Border.all(color: Colors.black12),
                          circularRadius: 8)
                      .scrollHorizontal(),
                ],
              )
            ].row().pOnly(bottom: 50, left: 12, right: 12).scrollHorizontal(),
          ),

          //-------- Back Button
          CustomBackButton().safeArea(),
        ].stack(),
      ),
    );
  }
}
