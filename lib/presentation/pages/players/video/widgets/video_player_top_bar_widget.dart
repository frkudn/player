import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/logic/Control_visibility/controls_visibility_cubit.dart';
import 'package:open_player/logic/video_player_bloc/video_player_bloc.dart';
import 'package:open_player/presentation/pages/players/video/widgets/video_player_icon_button_widget.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../../../data/services/favorites_video_hive_service/favorites_video_hive_service.dart';
import '../../../../common/methods/set_orientation_potrait.dart';
import '../../../../common/methods/system_ui_mode.dart';
import '../../../../common/widgets/animated_auto_scroll_text_widget.dart';
import 'video_player_audios_selector_widget.dart';

class VideoPlayerTopBarWidget extends HookWidget {
  const VideoPlayerTopBarWidget(
      {super.key, required this.state, required this.cState});

  final VideoPlayerReadyState state;
  final ControlsVisibilityState cState;

  @override
  Widget build(BuildContext context) {
    final isFavorite = useState(
        FavoritesVideoHiveService().getFavoriteStatus(state.playingVideoPath));

    final showMoreIcons = useState(false);
    return SafeArea(
      top: true,
      bottom: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        child: Column(
          children: [
            //----------------- Top Menu ----------------//
            if (!cState.lockScreenTapping && cState.showVideoControls)
              FadeInDown(
                child: Row(
                  children: [
                    //------ Back Button
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        ifOrientationLandscapeMakeItPotrait(context);
                        setToDefaultSystemTopBar();
                        context.pop();
                      },
                    ),

                    //------------- TITLE ----------------//
                    Expanded(
                      child: AnimatedAutoScrollTextWidget(
                        state.currentVideo.title,
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  blurRadius: 3,
                                  offset: Offset(0, 0),
                                  color: Colors.black38),
                            ]),
                      ),
                    ),

                    //--------- Favorite/Like Button
                    IconButton(
                      iconSize: 28,
                      color: Colors.white,
                      onPressed: () async {
                        //-------- Update the favorite status and return it
                        final favorite = await FavoritesVideoHiveService()
                            .toggleFavorite(state.playingVideoPath);
                        isFavorite.value = favorite;
                      },
                      icon: Icon(isFavorite.value
                          ? CupertinoIcons.heart_fill
                          : CupertinoIcons.heart),
                    )
                  ],
                ),
              ),

            //----------- Second Row ----------//
            //---------- Floating  Buttons -----------------///
            if (cState.showVideoControls && !cState.lockScreenTapping)
              FadeInRight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    //------------ Screen Rotation
                    VideoPlayerIconButtonWidget(
                      icon: HugeIcons.strokeRoundedScreenRotation,
                      onTap: () {
                        if (MediaQuery.orientationOf(context) ==
                            Orientation.landscape) {
                          SystemChrome.setPreferredOrientations(
                              [DeviceOrientation.portraitUp]);
                        } else {
                          SystemChrome.setPreferredOrientations(
                              [DeviceOrientation.landscapeLeft]);
                        }
                        context
                            .read<ControlsVisibilityCubit>()
                            .toggleVideoControlsVisibilty();
                      },
                    ),

                    //------------ Audio Set Button
                    VideoPlayerIconButtonWidget(
                      icon: HugeIcons.strokeRoundedFileMusic,
                      onTap: () {
                        context
                            .read<ControlsVisibilityCubit>()
                            .toggleVideoControlsVisibilty();
                        showModalBottomSheet(
                          context: context,
                          builder: (context) =>
                              VideoPlayerAudiosSelector(state: state),
                        );
                      },
                    ),

                    //------------ Lock Button
                    if (showMoreIcons.value)
                      VideoPlayerIconButtonWidget(
                          icon: HugeIcons.strokeRoundedTouchLocked02,
                          onTap: () {
                            context
                                .read<ControlsVisibilityCubit>()
                                .toggleLockScreenButton();
                          }),

                    //---------- Picture in Picture
                    if (showMoreIcons.value)
                      VideoPlayerIconButtonWidget(
                          icon: HugeIcons.strokeRoundedPictureInPictureOn,
                          onTap: () async {
                            // // Create an instance of the PiP service
                            // final pipService = PictureInPictureService();

                            // // Attempt to enable PiP
                            // await pipService.enablePictureInPicture(context);

                            // TODO: Implement file subtitle addition
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('Picture in Picture'),
                                content: const Text('Coding in progress...'),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            );
                          }),

                    //---------- Background Play Button
                    if (showMoreIcons.value)
                      VideoPlayerIconButtonWidget(
                          icon: HugeIcons.strokeRoundedHeadphones,
                          onTap: () {
                            state.vlcPlayerController.allowBackgroundPlayback
                                .toggle();
                            context
                                .read<ControlsVisibilityCubit>()
                                .toggleVideoControlsVisibilty();

                            // TODO: Implement file subtitle addition
                            showCupertinoDialog(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('Background Audio'),
                                content: const Text(
                                    'Its enabled by default, for disabling coding is in progress...'),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            );
                          }),

                    //---------- Arrow Button to toggle more buttons
                    VideoPlayerIconButtonWidget(
                        icon: showMoreIcons.value
                            ? HugeIcons.strokeRoundedCircleArrowLeft01
                            : HugeIcons.strokeRoundedCircleArrowRight01,
                        onTap: () {
                          showMoreIcons.value = !showMoreIcons.value;
                          context
                              .read<ControlsVisibilityCubit>()
                              .toggleVideoControlsVisibilty();
                        }),
                  ],
                ),
              ),

            //-------- Lock Screen Toching Button ----------//
            if (cState.lockScreenTapping)
              VideoPlayerIconButtonWidget(
                  icon: Icons.lock,
                  onTap: () {
                    context
                        .read<ControlsVisibilityCubit>()
                        .toggleLockScreenButton();
                    context
                        .read<ControlsVisibilityCubit>()
                        .toggleVideoControlsVisibilty();
                    context
                        .read<ControlsVisibilityCubit>()
                        .toggleVideoControlsVisibilty();
                  }),
          ],
        ),
      ),
    );
  }
}
