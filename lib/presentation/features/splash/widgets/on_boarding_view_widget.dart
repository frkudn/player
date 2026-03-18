import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:open_player/base/assets/svgs/app_svgs.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/base/theme/app_textstyles.dart';

class OnBoardingViewWidget extends StatelessWidget {
  final Animation<double> logoAnimation;

  const OnBoardingViewWidget({super.key, required this.logoAnimation});

  @override
  Widget build(BuildContext context) {
        final logo = Theme.of(context).brightness == Brightness.dark
        ? AppSvgs.logoDarkMode
        : AppSvgs.logoLightMode;
    return Stack(
      children: [
        // Logo
        Positioned(
          top: MediaQuery.of(context).size.height * 0.2,
          left: 0,
          right: 0,
          child: ScaleTransition(
            scale: logoAnimation,
            child: Hero(
              tag: 'app_logo',
              child: SvgPicture.asset(
                logo, 
                height: 100,
              ),
            ),
          ),
        ),
        // Animated text
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              AnimatedTextKit(
                isRepeatingAnimation: false,
                animatedTexts: [
                  _buildFeatureText(AppStrings.noAds),
                  _buildFeatureText(AppStrings.noSubscription),
                  _buildFeatureText(AppStrings.noTracking),
                ],
                onNextBeforePause: (index, isLast) {
                  if (index == 2) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      // Add any additional animations or transitions here
                    });
                  }
                },
              ),
            ],
          ),
        ),
        // Bottom text
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: logoAnimation,
            child: Text(
              'Experience Pure Music & Video',
              style: AppTextStyles.onBoarding.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  RotateAnimatedText _buildFeatureText(String text) {
    return RotateAnimatedText(
      text,
      textStyle: AppTextStyles.onBoarding,
      duration: const Duration(milliseconds: 2000),
      rotateOut: false,
      alignment: Alignment.center,
    );
  }
}
