import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_bottom_navigation_bar_customization_widget.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_change_app_bar_color_background_tile_widget.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_change_scaffold_color_tile_widget.dart';
import 'package:open_player/utils/extensions.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../../shared/cubit/theme_cubit/theme_state.dart';

class SettingCustomizationWidget extends StatelessWidget {
  const SettingCustomizationWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
       //-- Language Code
    final String lc = context.languageCubit.state.languageCode;
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return Visibility(
          visible: !state.defaultTheme,
          child: ExpansionTile(title: AppStrings.customization[lc]!.text.make(), children: [
            ExpansionTile(
              title: AppStrings.colors[lc]!.text.bold.make(),
              children: [
                //--------- Change Scaffold Color
                SettingChangeScaffoldColorTileWidget(),

                //--------- Change App Bar Color
                SettingChangeAppBarColorBackgroundTileWidget(),
              ],
            ),

            //----------- Bottom Navigation Bar
            SettingBottomNavigationBarCustomizationWidget(),
          ]),
        );
      },
    );
  }
}
