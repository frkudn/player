import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/theme/colors_palates.dart';
import 'package:open_player/logic/theme_cubit/theme_cubit.dart';

import '../../../../../logic/theme_cubit/theme_state.dart';

class ChangePrimaryPageColorSelectorWidget extends StatelessWidget {
  const ChangePrimaryPageColorSelectorWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return Container(
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AppAccentColors
                .colorHexCodesList.length, // Number of colors available
            itemBuilder: (context, index) {
              final isSelected = state.primaryColorListIndex ==
                  index; // Check if the color is selected
              final color = AppAccentColors.colorHexCodesList[index];

              return GestureDetector(
                onTap: () {
                  context.read<ThemeCubit>()
                    // Change primary color and update selected index
                    ..changeprimaryColor(color)
                    ..changeprimaryColorListIndex(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Color(color).withValues(alpha: 0.5),
                            width: 3,
                          )
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(color),
                    child: isSelected
                        ? const Icon(
                            HugeIcons.strokeRoundedTick01,
                            color: Colors.white, // Tick icon for selected color
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
