import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/logic/theme_cubit/theme_cubit.dart';
import 'package:open_player/logic/theme_cubit/theme_state.dart';
import 'package:open_player/utils/extensions.dart';

class SettingBottomNavigationBarCustomizationWidget extends StatelessWidget {
  const SettingBottomNavigationBarCustomizationWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    //-- Language Code
    final String lc = context.languageCubit.state.languageCode;
    //-- ThemeState from extensions
    final ThemeState themeState = context.themeCubit.state;

    return ExpansionTile(
      title: Text(
        AppStrings.bottomNavigationBar[lc]!,
        style: TextStyle(
            fontSize: 13,
            fontFamily: AppFonts.poppins,
            fontWeight: FontWeight.bold),
      ),
      children: [
        const Text(
          "Positions",
          style: TextStyle(
              fontFamily: AppFonts.poppins,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        const Gap(20),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              "Left",
            ),
            Text(
              "Right",
            ),
            Text(
              "Top",
            ),
            Text(
              "Bottom",
            ),
          ],
        ),
        const Gap(20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 45,
              onPressed: () {
                context.read<ThemeCubit>().changeBottomNavBarPositionLeft();
              },
              icon: const Icon(
                CupertinoIcons.arrow_left_circle,
              ),
            ),
            IconButton(
              iconSize: 45,
              onPressed: () {
                context.read<ThemeCubit>().changeBottomNavBarPositionRight();
              },
              icon: const Icon(CupertinoIcons.arrow_right_circle),
            ),
            IconButton(
              iconSize: 45,
              onPressed: () {
                context.read<ThemeCubit>().changeBottomNavBarPositionTop();
              },
              icon: const Icon(
                CupertinoIcons.arrow_up_circle,
              ),
            ),
            IconButton(
              iconSize: 45,
              onPressed: () {
                context.read<ThemeCubit>().changeBottomNavBarPositionBottom();
              },
              icon: const Icon(
                CupertinoIcons.arrow_down_circle,
              ),
            ),
          ],
        ),
        const Gap(10),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Hold the circle slightly and move it vertically or horizontally",
          ),
        ),
        const Gap(10),
        GestureDetector(
          onHorizontalDragStart: (d) {
            context
                .read<ThemeCubit>()
                .enableHoldBottomNavBarCirclePositionButton();
          },
          onHorizontalDragEnd: (d) {
            context
                .read<ThemeCubit>()
                .disableHoldBottomNavBarCirclePositionButton();
          },
          onVerticalDragStart: (d) {
            context
                .read<ThemeCubit>()
                .enableHoldBottomNavBarCirclePositionButton();
          },
          onVerticalDragEnd: (d) {
            context
                .read<ThemeCubit>()
                .disableHoldBottomNavBarCirclePositionButton();
          },
          onHorizontalDragUpdate: (d) {
            log("On Horizontal Drag update : ${d.delta.dx}");

            final dx = d.delta.dx;

            if (dx > 0) {
              context.read<ThemeCubit>().changeBottomNavBarPositionRight();
            } else {
              context.read<ThemeCubit>().changeBottomNavBarPositionLeft();
            }
          },
          onVerticalDragUpdate: (d) {
            log("On Vertical Drag update : ${d.delta.dy}");
            final dy = d.delta.dy;

            if (dy > 0) {
              context.read<ThemeCubit>().changeBottomNavBarPositionBottom();
            } else {
              context.read<ThemeCubit>().changeBottomNavBarPositionTop();
            }
          },
          child: CircleAvatar(
            radius: themeState.isHoldBottomNavBarCirclePositionButton ? 50 : 30,
            backgroundColor: themeState.isHoldBottomNavBarCirclePositionButton
                ? Colors.transparent
                : Color(themeState.primaryColor),
            child: HugeIcon(
                icon: HugeIcons.strokeRoundedNavigation01,
                color: Theme.of(context).iconTheme.color!),
          ),
        ),
        const Gap(20),
        const Text(
          "Size",
          style: TextStyle(
              fontFamily: AppFonts.poppins,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        const Gap(20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text(
              "Width",
              style: TextStyle(),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<ThemeCubit>().increaseBottomNavBarWidth();
                  },
                  label: const Text(
                    "Increase",
                  ),
                  icon: const Icon(Icons.add),
                ),
                const Gap(10),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<ThemeCubit>().decreaseBottomNavBarWidth();
                  },
                  label: const Text(
                    "Decrease",
                  ),
                  icon: const Icon(Icons.remove),
                ),
              ],
            ),
          ],
        ),
        const Gap(10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text(
              "Height",
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<ThemeCubit>().increaseBottomNavBarHeight();
                  },
                  label: const Text(
                    "Increase",
                  ),
                  icon: const Icon(Icons.add),
                ),
                const Gap(10),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<ThemeCubit>().decreaseBottomNavBarHeight();
                  },
                  label: const Text(
                    "Decrease",
                  ),
                  icon: const Icon(Icons.remove),
                ),
              ],
            ),
          ],
        ),
        const Gap(20),

        ///------------------- Transform ----------------//

        const Text(
          "Transform",
          style: TextStyle(
              fontFamily: AppFonts.poppins,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        const Gap(20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Rotation",
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    child: IconButton(
                      onPressed: () {
                        context
                            .read<ThemeCubit>()
                            .updateBottomNavigationBarRotationToLeft();
                      },
                      icon: const Icon(Icons.rotate_left),
                    ),
                  ),
                  const Gap(20),
                  CircleAvatar(
                    child: IconButton(
                      onPressed: () {
                        context
                            .read<ThemeCubit>()
                            .updateBottomNavigationBarRotationToRight();
                      },
                      icon: const Icon(Icons.rotate_right),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),

        const Gap(20),
        const Text(
          "Reset To default",
        ),
        const Gap(10),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  context
                      .read<ThemeCubit>()
                      .resetToDefaultBottomNavBarPosition();
                },
                label: const Text(
                  "Position",
                ),
                icon: const Icon(HugeIcons.strokeRoundedNavigation01),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  context
                      .read<ThemeCubit>()
                      .resetToDefaultBottomNavBarHeightAndWidth();
                },
                label: const Text(
                  "Size",
                ),
                icon: const Icon(HugeIcons.strokeRoundedResize01),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  context
                      .read<ThemeCubit>()
                      .resetToDefaultBottomNavBarRotation();
                },
                label: const Text(
                  "Rotation",
                ),
                icon: const Icon(Icons.rotate_90_degrees_cw_sharp),
              ),
            ],
          ),
        ),

        const Gap(20),
      ],
    );
  }
}
