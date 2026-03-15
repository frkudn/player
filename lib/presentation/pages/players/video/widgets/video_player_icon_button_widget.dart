// video_player/presentation/pages/video_player_page.dart

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class VideoPlayerIconButtonWidget extends StatelessWidget {
  const VideoPlayerIconButtonWidget(
      {super.key,
       this.icon,
      this.size,
      this.color,
      this.hugeIconData,
      this.isHugeIcon = true,
      required this.onTap});

  final double? size;
  final IconData? icon;
  final bool isHugeIcon;
  final hugeIconData;
  final Color? color;
  final Function()? onTap;
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: isHugeIcon
          ? HugeIcon(
              icon: hugeIconData,
              color: color ?? Colors.white,
              size: size ?? 28,
            )
          : Icon(
              icon??Icons.abc,
              color: color ?? Colors.white,
              size: size ?? 28,
            ),
    );
  }
}
