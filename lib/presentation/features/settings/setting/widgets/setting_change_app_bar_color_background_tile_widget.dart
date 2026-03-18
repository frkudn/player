import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_custom_color_selection_list_tile_widget.dart';

import '../../../../shared/cubit/theme_cubit/theme_state.dart';

class SettingChangeAppBarColorBackgroundTileWidget extends StatelessWidget {
  const SettingChangeAppBarColorBackgroundTileWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return SettingCustomColorSelectionListTileWidget(
     tileLabelEn: "Change AppBar Color",


          defaultThemeColor: Colors.white,
          isDefaultThemeColor:
              themeState.isDefaultAppBarColor,
              selectColorOnTap: ({required colorCode}) {
            context
                .read<ThemeCubit>()
                .changeAppBarColor(colorCode);
          },
          resetToDefaultThemeColorButton: () {
            context
                .read<ThemeCubit>()
                .resetToDefaultAppBarColor();
            context.pop();
          },
          customColor:themeState.customAppBarColor!=null? Color(themeState.customAppBarColor!):null,
        );
      },
    );
  }
}
