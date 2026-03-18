import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/base/assets/fonts/styles.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/base/services/language/app_languages.dart';
import '../../../../../base/router/router.dart';
import '../cubit/language_cubit/language_cubit.dart';
import '../widgets/language_page_next_button_widget.dart';
import '../widgets/language_selection_tile_widget.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isLogin =
        MyHiveBoxes.user.get(MyHiveKeys.userIsLoggedIn, defaultValue: false);
    return Scaffold(
      appBar: AppBar(
        leading: isLogin
            ? IconButton(
                onPressed: () {
                  context.go(AppRoutes.mainRoute);
                },
                icon: const Icon(CupertinoIcons.back),
              )
            : null,
        automaticallyImplyLeading: false,
        title: Text(
          isLogin ? "Select Language" : "Choose a language",
          style: const TextStyle(fontFamily: AppFonts.poppins, fontSize: 18),
        ),
        actions: [
          if (!isLogin) const LanguagePageNextButtonWidget(),
        ],
      ),
      body: BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, state) {
          return ListView.separated(
              itemBuilder: (context, index) {
                final languageName =
                    AppLanguages.supportedLanguages[index]["name"].toString();
                final languageCode = AppLanguages.supportedLanguages[index]
                        ["code"]
                    .toString()
                    .toLowerCase();

                final SvgPicture countryFlag =
                    AppLanguages.supportedLanguages[index]["flag"];

                final currentLanguageCode = languageCode == state.languageCode;

                //----------Tile Widget
                return LanguageSelectionTileWidget(
                    languageCode: languageCode,
                    countryFlag: countryFlag,
                    languageName: languageName,
                    currentLanguageCode: currentLanguageCode);
              },

              //-------- Seperator
              separatorBuilder: (context, index) => Divider(
                    color: Colors.grey.shade300,
                  ),
              itemCount: AppLanguages.supportedLanguages.length);
        },
      ),
    );
  }
}
