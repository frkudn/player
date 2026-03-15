import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/presentation/pages/main/widgets/bottom-navbar/bottom_nav_bar_button_widget.dart';
import 'package:open_player/utils/extensions.dart';
import 'package:velocity_x/velocity_x.dart';
import '../../../../../logic/theme_cubit/theme_state.dart';

class CustomBottomNavBarWidget extends StatelessWidget {
  const CustomBottomNavBarWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double mqWidth = MediaQuery.sizeOf(context).width;
    final double mqHeight = MediaQuery.sizeOf(context).height;
    final currentIndex = context.bottomNavBarCubit.state.index;
    final ThemeState themeState = context.themeCubit.state;

    return Transform.rotate(
      angle: themeState.bottomNavBarRotation,
      child: Container(
        //---Default Height is 5% of Screen Height -----///
        height: mqHeight * themeState.bottomNavBarHeight,
        //---Default Width is 60% of Screen Width -----///
        width: mqWidth * themeState.bottomNavBarWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
        ),

        //---------------- Buttons ---------------//
        child: [
          //--- Audio Button ---//
          BottomNavBarButtonWidget(
            icon: HugeIcons.strokeRoundedMusicNote02,
            isSelected: currentIndex == 0,
            pageIndex: 0,
          ),

          //--- Video Button ---//
          BottomNavBarButtonWidget(
            icon: HugeIcons.strokeRoundedVideo02,
            isSelected: currentIndex == 1,
            pageIndex: 1,
          ),

          //--- Settings Button ---//
          BottomNavBarButtonWidget(
              icon: HugeIcons.strokeRoundedSettings05,
              isSelected: currentIndex == 2,
              pageIndex: 2),
        ].row(),
      ).glassMorphic(
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
              color: themeState.isDarkMode ? Colors.white54 : Colors.black45)),
    ).positioned(
      //------Default Margin Bottom is  5% of Screen Height  --------//
      bottom: mqHeight * themeState.bottomNavBarPositionFromBottom,
      //------Default Margin Left is  20% of Screen Width  --------//
      left: mqWidth * themeState.bottomNavBarPositionFromLeft,
      //------Default Margin Right is  20% of Screen Width  --------//
      right: themeState.isDefaultBottomNavBarPosition
          ? mqWidth * themeState.bottomNavBarPositionFromLeft
          : null,
      // top: mqHeight* themeState.bottomNavBarPositionFromTop,
    );
  }
}
