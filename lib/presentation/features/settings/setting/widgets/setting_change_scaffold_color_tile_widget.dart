import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_custom_color_selection_list_tile_widget.dart';

import '../../../../shared/cubit/theme_cubit/theme_state.dart';

class SettingChangeScaffoldColorTileWidget extends StatelessWidget {
  const SettingChangeScaffoldColorTileWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return SettingCustomColorSelectionListTileWidget(
          tileLabelEn: "Change Scaffold Color",

          defaultThemeColor: Colors.transparent,
          isDefaultThemeColor: themeState.isDefaultScaffoldColor,
          resetToDefaultThemeColorButton: () {
            context.read<ThemeCubit>().resetToDefaultScaffoldColor();
            Navigator.pop(context);
          },
          selectColorOnTap: ({required colorCode}) {
            context.read<ThemeCubit>().changeScaffoldBgColor(colorCode);
             
          },
          customColor:themeState.customScaffoldColor!=null? Color(themeState.customScaffoldColor!):null,
        );
      },
    );
  }
}
