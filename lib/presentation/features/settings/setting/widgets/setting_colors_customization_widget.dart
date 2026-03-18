import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_state.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_change_scaffold_color_tile_widget.dart';
import 'package:velocity_x/velocity_x.dart';

import '../../../../shared/cubit/theme_cubit/theme_cubit.dart';
import 'setting_change_app_bar_color_background_tile_widget.dart';

class SettingColorsCustomizationWidget extends StatelessWidget {
  const SettingColorsCustomizationWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return Visibility(
            visible: !state.defaultTheme,
            child: ExpansionTile(
              title: "Colors Customization".text.tight.make(),
              children: [
                //--------- Change Scaffold Color
                SettingChangeScaffoldColorTileWidget(),

                //--------- Change App Bar Color
                SettingChangeAppBarColorBackgroundTileWidget(),
              ],
            ));
      },
    );
  }
}
