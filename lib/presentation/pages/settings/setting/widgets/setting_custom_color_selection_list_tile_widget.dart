import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:open_player/base/theme/colors_palates.dart';
import 'package:open_player/logic/theme_cubit/theme_cubit.dart';
import 'package:open_player/logic/theme_cubit/theme_state.dart';
import 'package:open_player/presentation/common/texty.dart';

class SettingCustomColorSelectionListTileWidget extends StatelessWidget {
  const SettingCustomColorSelectionListTileWidget(
      {super.key,
      required this.tileLabelEn,
       this.tileLabelUr,
       this.tileLabelEs,
       this.tileLabelHi,
       this.tileLabelFr,
       this.tileLabelPs,
       this.tileLabelRu,
       this.tileLabelKr,
       this.tileLabelAr,
       this.tileLabelZh,
      required this.isDefaultThemeColor,
      required this.customColor,
      required this.defaultThemeColor,
      required this.resetToDefaultThemeColorButton,
      required this.selectColorOnTap});

  final String tileLabelEn;
  final String? tileLabelUr;
  final String? tileLabelHi;
  final String? tileLabelAr;
  final String? tileLabelFr;

  final String? tileLabelEs;
  final String? tileLabelPs;
  final String? tileLabelRu;
  final String? tileLabelKr;
  final String? tileLabelZh;

  final bool isDefaultThemeColor;
  final Color defaultThemeColor;
  final Color? customColor;
  final Function({required int colorCode}) selectColorOnTap;
  final Function() resetToDefaultThemeColorButton;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Visibility(
          visible: !themeState.defaultTheme,
          child: ListTile(
            title: Texty(
              en: tileLabelEn,
              ar: tileLabelAr,
              es: tileLabelEs,
              fr: tileLabelFr,
              hi: tileLabelHi,
              kr: tileLabelKr,
              ru: tileLabelRu,
              ps: tileLabelPs,
              zh: tileLabelZh,
            ),
            trailing: Container(
              height: 35,
              width: 35,
              decoration: BoxDecoration(
                border: Border.all(
                    color: themeState.isDarkMode ? Colors.white : Colors.black),
                shape: BoxShape.circle,
                color: isDefaultThemeColor ? defaultThemeColor : customColor,
              ),
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Gap(20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: resetToDefaultThemeColorButton,
                          label: const Text("Reset to default"),
                          icon: const Icon(Icons.color_lens),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: GridView.builder(
                          itemCount: AppColors.colorHexCodesList.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6),
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () {
                              final int color =
                                  AppColors.colorHexCodesList[index];
                              Navigator.pop(context);
                              return selectColorOnTap(colorCode: color);
                            },
                            child: CircleAvatar(
                              backgroundColor:
                                  Color(AppColors.colorHexCodesList[index]),
                            ),
                          ),
                        ),
                      )
                    ],
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
