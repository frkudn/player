import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/logic/audio_player_bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/common/widgets/nothing_widget.dart';
import 'package:velocity_x/velocity_x.dart';

class AudioPlayerLyricsBoxWidget extends HookWidget {
  const AudioPlayerLyricsBoxWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.sizeOf(context);
    final fontSize = useState(16);
    return BlocSelector<AudioPlayerBloc, AudioPlayerState,
        AudioPlayerSuccessState?>(
      selector: (state) {
        return state is AudioPlayerSuccessState ? state : null;
      },
      builder: (context, state) {
        if (state == null) {
          return nothing;
        } else {
          return StreamBuilder(
              stream: state.audioPlayer.currentIndexStream,
              builder: (context, snapshot) {
                int? currentIndex =
                    snapshot.data ?? state.audioPlayer.currentIndex;
                String lyrics = currentIndex != null
                    ? state.audios[currentIndex].lyrics ?? "No Lyrics"
                    : " No Lyrics found";
                return Column(
                  children: [
                    //------------- Top Bar ---------------///
                    [
                      IconButton(
                        color: Colors.white,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: lyrics));
                        },
                        icon: Icon(Icons.copy),
                      ),
                      Spacer(),
                      IconButton(
                        color: Colors.white,
                        onPressed: () {
                          fontSize.value = fontSize.value - 1;
                        },
                        icon: Icon(HugeIcons.strokeRoundedRemove01),
                      ),
                      IconButton(
                        color: Colors.white,
                        onPressed: () {
                          fontSize.value = fontSize.value + 1;
                        },
                        icon: Icon(HugeIcons.strokeRoundedAdd01),
                      ),
                    ].row(),

                    //------------- Lyrics Box
                    lyrics.text
                        .shadow(0, 1, 1, Colors.black)
                        .white
                        .fontFamily(AppFonts.poppins)
                        .size(fontSize.value.toDouble())
                        .heightRelaxed
                        .makeCentered()
                  ],
                ).scrollVertical().p16().glassMorphic(blur: 10);
              }).pSymmetric(h: mq.width * 0.05);
        }
      },
    );
  }
}
