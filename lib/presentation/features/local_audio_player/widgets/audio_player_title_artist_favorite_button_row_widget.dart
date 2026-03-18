import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/data/services/favorite_audio_hive_service/audio_hive_service.dart';
import 'package:open_player/presentation/shared/widgets/animated_auto_scroll_text_widget.dart';
import 'package:open_player/presentation/shared/widgets/nothing_widget.dart';
import 'package:open_player/presentation/shared/widgets/quality_badge/quality_badge_widget.dart';
import 'package:open_player/presentation/shared/widgets/reaction_button/reaction_button.dart';
import 'package:open_player/utils/extensions.dart';
import 'package:velocity_x/velocity_x.dart';
import '../bloc/audio_player_bloc.dart';

class AudioPlayerTitleArtistFavoriteButtonAudioQualityBadgeRowWidget
    extends StatelessWidget {
  const AudioPlayerTitleArtistFavoriteButtonAudioQualityBadgeRowWidget(
      {super.key});

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);
    final themeState = context.themeCubit.state;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: mq.width * 0.03, vertical: mq.height * 0.02),
      child: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
        builder: (context, audioPlayerState) {
          if (audioPlayerState is AudioPlayerSuccessState) {
            return StreamBuilder(
              stream: audioPlayerState.audioPlayerCombinedStream,
              builder: (context, snapshot) {
                int? currentIndex = snapshot.data?.currentIndex ??
                    audioPlayerState.audioPlayer.currentIndex;
                String title = currentIndex != null
                    ? audioPlayerState.audios[currentIndex].title
                    : "";

                String artists = currentIndex != null
                    ? audioPlayerState.audios[currentIndex].artists
                    : "";

                String audioQuality = currentIndex != null
                    ? audioPlayerState.audios[currentIndex].quality
                    : "MQ";

                int currentAudioId = currentIndex != null
                    ? audioPlayerState.audios[currentIndex].id
                    : 0;

                bool isFavorite =  FavoritesAudioHiveService()
                    .getFavoriteStatus(currentAudioId);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: [
                        //------------- TITLE ----------------//
                        AnimatedAutoScrollTextWidget(
                          title,
                          style: TextStyle(
                              fontSize: 25,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                    blurRadius: 3,
                                    offset: Offset(0, 0),
                                    color: Colors.black38),
                              ]),
                        ),

                        //------------------- ARTISTS ------------------//
                        [
                          artists.text.gray100
                              .minFontSize(10)
                              .maxFontSize(12)
                              .fontFamily(AppFonts.poppins)
                              .maxLines(1)
                              .shadow(0, 0, 2, Colors.black26)
                              .make()
                              .flexible(),
                          Gap(5),

                          //--------- Audio Quality
                          Dance(
                            duration: Duration(seconds: 3),
                            child: QualityBadge(
                              quality: audioQuality,
                            ),
                          ),
                        ].row(axisSize: MainAxisSize.min),
                      ].column(
                        crossAlignment: CrossAxisAlignment.start,
                      ),
                    ),

                    //------------- Like Button -------------//
                    ReactionButton(
                      size: 40,
                      liked: isFavorite, // Control the initial state
                      activeColor: Color(themeState.primaryColor),
                      inactiveColor: Colors.white24,
                      bubbleColors: [
                        Color(themeState.primaryColor).withValues(alpha: 0.1),
                        Color(themeState.primaryColor).withValues(alpha: 0.3),
                        Color(themeState.primaryColor).withValues(alpha: 0.6),
                        Color(themeState.primaryColor).withValues(alpha: 0.9),
                      ],

                      onTap: () {
                        FavoritesAudioHiveService()
                            .toggleFavorite(currentAudioId);
                      },
                    ).pOnly(left: 5, bottom: 5),
                  ],
                );
              },
            );
          }
          return nothing;
        },
      ),
    );
  }
}
