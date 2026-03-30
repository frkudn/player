import 'dart:typed_data';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/base/assets/images/app_images.dart';
import '../bloc/audio_player_bloc.dart';

class AudioPlayerThumbnailCardWidget extends StatelessWidget {
  const AudioPlayerThumbnailCardWidget(
      {super.key,
      this.height,
      this.width,
      this.horizontalPadding,
      this.verticalPadding,
      this.borderRadius});

  final double? height;
  final double? width;
  final double? horizontalPadding;
  final double? verticalPadding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);
    return FadeInDownBig(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding ?? mq.width * 0.05,
            vertical: verticalPadding ?? 0),
        child: Card(
          shadowColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(20),
          ),
          color: Colors.transparent,
          child: BlocSelector<AudioPlayerBloc, AudioPlayerState,
              AudioPlayerSuccessState?>(
            selector: (state) {
              return state is AudioPlayerSuccessState ? state : null;
            },
            builder: (context, state) {
              if (state == null) {
                return defaultThumbnailCard();
              }

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
                        height: height,
                        width: width,
                        decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius:
                                borderRadius ?? BorderRadius.circular(20),
                            //--                  Image             --//
                            image: DecorationImage(
                              filterQuality: FilterQuality.high,
                              fit: BoxFit.cover,
                              image: MemoryImage(
                                thumbnail,
                              ),
                            )),
                      );
                    }
                    return defaultThumbnailCard();
                  });
            },
          ),
        ),
      ),
    );
  }

  //------- Widgtes 

  Container defaultThumbnailCard() {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          //--                  Image             --//
          image: const DecorationImage(
            filterQuality: FilterQuality.high,
            fit: BoxFit.cover,
            image: AssetImage(
              AppImages.defaultThumbnail,
            ),
          )),
    );
  }
}
