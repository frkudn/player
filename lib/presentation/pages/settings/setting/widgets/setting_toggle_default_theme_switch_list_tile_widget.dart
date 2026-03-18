import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/logic/theme_cubit/theme_cubit.dart';
import 'package:open_player/logic/theme_cubit/theme_state.dart';

class SettingToggleDefaultThemeSwitchListTileWidget extends StatelessWidget {
  const SettingToggleDefaultThemeSwitchListTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // BUG FIX: was reading context.themeCubit.state OUTSIDE BlocBuilder.
    // That means toggling never caused a rebuild — the switch stayed visually
    // stuck until the user navigated away and back.
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return SwitchListTile(
          value: !state.defaultTheme,
          onChanged: (_) => context.read<ThemeCubit>().toggleDefaultTheme(),
          title: Row(children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedColors,
              color: Theme.of(context).iconTheme.color!,
            ),
            const Gap(10),
            const Text('Custom Themes', overflow: TextOverflow.ellipsis),
          ]),
        );
      },
    );
  }
}
