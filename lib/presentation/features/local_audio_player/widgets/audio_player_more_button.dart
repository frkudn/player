import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AudioPlayerMoreButton extends StatelessWidget {
 const AudioPlayerMoreButton({
    super.key,
    required this.onPressed,
  });
final  void Function()? onPressed;
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      color: Colors.white,
      iconSize: 25,
      tooltip: "More",
      icon: const Icon(HugeIcons.strokeRoundedArrowLeft01),
    );
  }
}
