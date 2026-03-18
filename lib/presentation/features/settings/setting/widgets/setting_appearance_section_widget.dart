import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_player/base/strings/app_strings.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_black_mode_switch_list_tile_widget.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_change_theme_list_tile_widget.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_dark_mode_button_widget.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_restore_to_default_setting_widget.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_toggle_default_theme_switch_list_tile_widget.dart';
import 'package:open_player/presentation/features/settings/setting/widgets/setting_visual_customization_widget.dart';
import 'package:open_player/utils/extensions.dart';

//
// NOTE: With the new SettingPage this widget is no longer needed as a
// separate ExpansionTile. All appearance controls are inlined into the
// _SectionCard in SettingPage for better visual hierarchy.
//
// If you  want the old ExpansionTile approach (e.g. embedded in another
// screen), the code below is the cleaned-up version.
class SettingAppearanceSectionWidget extends StatelessWidget {
  const SettingAppearanceSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final String lc = context.languageCubit.state.languageCode;
    return ExpansionTile(
      initiallyExpanded: true,
      title: Row(children: [
        Text(AppStrings.appearance[lc]!, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Icon(CupertinoIcons.color_filter,
            color: Theme.of(context).primaryColor),
      ]),
      children: const [
        SettingRestoreToDefaultSettingWidget(),
        SettingThemeModeSwitchButtonWidget(),
        SettingToggleDefaultThemeSwitchListTileWidget(),
        SettingChangeThemeSwitchListTileWidget(),
        SettingBlackModeSwitchListTileWidget(),
        SettingCustomizationWidget(),
      ],
    );
  }
}
