// video_player/presentation/pages/video_player_page.dart

import 'package:flutter/material.dart';

class VideoPlayerIconButtonWidget extends StatelessWidget {
  const VideoPlayerIconButtonWidget(
      {super.key, required this.icon, this.size, this.color, required this.onTap});

  final double? size;
  final IconData icon;
  final Color? color;
 final Function()? onTap;
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        color: color ?? Colors.white,
        size: size ?? 28,
      ),
    );
  }
}
