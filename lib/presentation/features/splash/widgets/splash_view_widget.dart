import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:open_player/base/assets/svgs/app_svgs.dart';

class SplashViewWidget extends StatelessWidget {
  final Animation<double> logoAnimation;

  const SplashViewWidget({super.key, required this.logoAnimation});

  @override
  Widget build(BuildContext context) {
    final logo = Theme.of(context).brightness == Brightness.dark
        ? AppSvgs.logoDarkMode
        : AppSvgs.logoLightMode;
    return Center(
      child: ScaleTransition(
        scale: logoAnimation,
        child: Hero(
          tag: 'app_logo',
          child: SvgPicture.asset(
            logo,
            height: 200,
          ),
        ),
      ),
    );
  }
}
