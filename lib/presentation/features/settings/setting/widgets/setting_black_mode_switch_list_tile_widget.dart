import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_state.dart';

class SettingBlackModeSwitchListTileWidget extends StatelessWidget {
  const SettingBlackModeSwitchListTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        // Only visible in dark mode — black mode only makes sense then
        return Visibility(
          visible: state.isDarkMode,
          child: SwitchListTile(
            value: state.isBlackMode,
            onChanged: (_) => context.read<ThemeCubit>().toggleBlackMode(),
            title: const Row(children: [
              Icon(HugeIcons.strokeRoundedBlackHole),
              Gap(10),
              Text('Black Mode'),
            ]),
          ),
        );
      },
    );
  }
}
