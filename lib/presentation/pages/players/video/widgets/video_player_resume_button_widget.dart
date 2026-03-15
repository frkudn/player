import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/logic/video_playback/video_playback_bloc.dart';
import 'package:open_player/presentation/pages/players/video/widgets/video_content_widget.dart';
import 'package:velocity_x/velocity_x.dart';

class VideoPlayerResumeButtonWidget extends StatelessWidget {
  const VideoPlayerResumeButtonWidget({
    super.key,
    required this.widget,
  });

  final VideoContentWidget widget;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoPlaybackHiveBloc, VideoPlaybackHiveState>(
      builder: (context, state) {
        return FadeInLeft(
          child: GestureDetector(
            onTap: () {
              widget.videoPlayerReadyState.vlcPlayerController
                  .seekTo(Duration(seconds: state.position));
              context
                  .read<VideoPlaybackHiveBloc>()
                  .add(HideVideoPlaybackResumeButtonEvent());
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: [
                "Resume ".text.black.make(),
                Icon(
                  HugeIcons.strokeRoundedPlay,
                  color: Colors.black,
                )
              ].row(
                axisSize: MainAxisSize.min,
              ),
            ),
          ).p8(),
        ).hide(isVisible: state.showResumeButton,).positioned(top: 150, left: 0);
      },
    );
  }
}
