import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/link.dart';

class SocialMediaIconButton extends StatelessWidget {
  SocialMediaIconButton(
      {super.key,
      required this.url,
       this.icon,
      this.iconSize,
      this.isHugeIcon = true, this.hugeIconData,
      });
  final String url;
  // ignore: prefer_typing_uninitialized_variables
  final iconSize;
   IconData? icon;
  final hugeIconData;
  final bool isHugeIcon;
  @override
  Widget build(BuildContext context) {
    return Link(
      uri: Uri.parse(url),
      target: LinkTarget.blank,
      builder: (context, followLink) => IconButton(
        onPressed: () {
          followLink!(); // Call followLink function to navigate
        },
        icon: isHugeIcon
            ? HugeIcon(icon: hugeIconData)
            : Icon(
                icon,
                size: iconSize ?? 40,
              ),
      ),
    );
  }
}
