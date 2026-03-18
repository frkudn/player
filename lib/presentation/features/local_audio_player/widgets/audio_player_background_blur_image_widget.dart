import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/base/assets/images/app_images.dart';

import '../bloc/audio_player_bloc.dart';

class AudioPlayerBackgroundBlurImageWidget extends StatelessWidget {
  const AudioPlayerBackgroundBlurImageWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: BlocSelector<AudioPlayerBloc, AudioPlayerState,
          AudioPlayerSuccessState?>(
        selector: (state) {
          return state is AudioPlayerSuccessState ? state : null;
        },
        builder: (context, state) {
          if (state is AudioPlayerSuccessState) {
            return StreamBuilder(
              stream: state.audioPlayerCombinedStream,
              builder: (context, snapshot) {
                int? currentIndex = snapshot.data?.currentIndex ??
                    state.audioPlayer.currentIndex;
                Uint8List? thumbnail = currentIndex != null
                    ? state.audios[currentIndex].thumbnail.isNotEmpty
                        ? state.audios[currentIndex].thumbnail.first.bytes
                        : null
                    : null;
                if (thumbnail != null) {
                  return Container(
                    height: double.infinity,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: MemoryImage(thumbnail),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
                return _DefaultImageWidget();
              },
            );
          }
          return _DefaultImageWidget();
        },
      ),
    );
  }
}

class _DefaultImageWidget extends StatelessWidget {
  const _DefaultImageWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.defaultProfile),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
