import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';

class AudioPlayerLyricsButtonWidget extends StatelessWidget {
  const AudioPlayerLyricsButtonWidget({
    super.key,
    required this.showLyrics,
  });

  final ValueNotifier<bool> showLyrics;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
            style: TextButton.styleFrom(
              iconColor: Colors.white,
            ),
            onPressed: () {
              showLyrics.value = !showLyrics.value;
            },
            icon: Icon(!showLyrics.value
                ? CupertinoIcons.chevron_down
                : CupertinoIcons.chevron_up),
            label: showLyrics.value
                ? "Close Lyrics".text.white.make()
                : "Show Lyrics".text.white.make())
        .positioned(bottom: 0, left: 0, right: 0);
  }
}
