import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/logic/theme_cubit/theme_cubit.dart';
import 'package:open_player/logic/theme_cubit/theme_state.dart';
import 'package:open_player/utils/custom_snackbars.dart';

class SettingRestoreToDefaultSettingWidget extends StatelessWidget {
  const SettingRestoreToDefaultSettingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        // Only shown when the user has deviated from defaults
        return Visibility(
          visible: !state.defaultTheme,
          child: ListTile(
            dense: true,
            onTap: () {
              HapticFeedback.lightImpact();
              context.read<ThemeCubit>().restoreDefaultSetting();
              AppCustomSnackBars.normalSuccess('Restored to default settings');
            },
            title: Text(
              'Restore to default setting',
              style: TextStyle(fontFamily: AppFonts.poppins),
            ),
            trailing: const Icon(Icons.settings_backup_restore_rounded),
          ),
        );
      },
    );
  }
}
