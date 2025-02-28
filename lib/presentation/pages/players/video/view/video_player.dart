// video_player/presentation/pages/video_player_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/logic/Control_visibility/controls_visibility_cubit.dart';
import 'package:open_player/presentation/common/methods/set_orientation_potrait.dart';
import 'package:open_player/presentation/common/methods/system_ui_mode.dart';
import 'package:open_player/presentation/common/widgets/nothing_widget.dart';
import '../../../../../logic/video_player_bloc/video_player_bloc.dart';
import '../widgets/video_content_widget.dart';

class VideoPlayerPage extends StatelessWidget {
  const VideoPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    hideSystemTopBar();
    return BlocBuilder<ControlsVisibilityCubit, ControlsVisibilityState>(
      builder: (context, cState) {
        return PopScope(
          canPop: (!isLandscapeOriention(context) && !cState.lockScreenTapping),
          onPopInvokedWithResult: (didPop, result) {
            if (!cState.lockScreenTapping) {
              ifOrientationLandscapeMakeItPotrait(context);
              setToDefaultSystemTopBar();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: BlocBuilder<VideoPlayerBloc, VideoPlayerState>(
              builder: (context, state) {
                if (state is VideoPlayerLoadingState) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is VideoPlayerErrorState) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(state.message),
                    ),
                  );
                } else if (state is VideoPlayerReadyState) {
                  return VideoContentWidget(
                    videoPlayerReadyState: state,
                  );
                }

                return nothing;
              },
            ),
          ),
        );
      },
    );
  }
}
