import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/presentation/features/settings/change_accent_color/view/change_accent_color_page.dart';

import '../../../../shared/cubit/theme_cubit/theme_cubit.dart';
import '../../../../shared/cubit/theme_cubit/theme_state.dart';

class SettingChangeThemeSwitchListTileWidget extends StatelessWidget {
  const SettingChangeThemeSwitchListTileWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return Visibility(
          visible: !state.defaultTheme,
          child: ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text(
               "Change Theme",
            ),
            trailing: CircleAvatar(
              radius: 15,
              backgroundColor: Color(state.primaryColor),
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeAccentColorPage(),
                  ));
            },
          ),
        );
      },
    );
  }
}
