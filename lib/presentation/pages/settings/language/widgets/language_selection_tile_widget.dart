import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/logic/greeting/greeting_cubit.dart';
import 'package:open_player/logic/language_cubit/language_cubit.dart';

class LanguageSelectionTileWidget extends StatelessWidget {
  const LanguageSelectionTileWidget({
    super.key,
    required this.languageCode,
    required this.countryFlag,
    required this.languageName,
    required this.currentLanguageCode,
  });

  final String languageCode;
  final SvgPicture countryFlag;
  final String languageName;
  final bool currentLanguageCode;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: currentLanguageCode ? false : true,
      selected: currentLanguageCode,
      onTap: () {
        context.read<LanguageCubit>().changeLanguage(languageCode);
        context
            .read<GreetingCubit>()
            .updateGreeting(languageCode: languageCode);
        log(languageCode);
      },
      leading: countryFlag,
      title: Text(
        languageName,
        style: TextStyle(
            fontWeight:
                currentLanguageCode ? FontWeight.w600 : FontWeight.normal,
            fontFamily: AppFonts.poppins),
      ),
      trailing: currentLanguageCode
          ? const Icon(HugeIcons.strokeRoundedTick04)
          : null,
    );
  }
}
