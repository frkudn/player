import 'package:flutter/material.dart';
import 'package:open_player/base/assets/fonts/styles.dart';

import '../../presentation/shared/cubit/theme_cubit/theme_state.dart';

class AppThemes {
  //------ Select/Choose Theme -------------//
  themes(ThemeState themeState) {
    //     ? themeState.isDarkMode
    return themeState.isDarkMode
        ? _defaultDarkTheme(themeState: themeState)
        : _defaultLightTheme(themeState: themeState);
    //     ? _flexDarkTheme(themeState: themeState)
  }

  //--- Default Light Theme ---//
  _defaultLightTheme({required ThemeState themeState}) {
    return ThemeData().copyWith(
      scaffoldBackgroundColor: !themeState.isDefaultScaffoldColor
          ? themeState.customScaffoldColor != null
              ? Color(themeState.customScaffoldColor!)
              : Colors.white
          : Colors.white,
      visualDensity: themeState.visualDensity,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(themeState.primaryColor),
        primary: Color(themeState.primaryColor),
        secondary: Color(themeState.primaryColor),
        contrastLevel: themeState.contrastLevel,
      ),
      primaryColor: Color(themeState.primaryColor),
      tabBarTheme: const TabBarThemeData(
        unselectedLabelStyle: TextStyle(fontSize: 7),
        labelStyle: TextStyle(
            fontSize: 8,
            fontFamily: AppFonts.poppins,
            fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
          backgroundColor: !themeState.isDefaultAppBarColor
              ? Color(themeState.customAppBarColor!)
              : null),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          Color(themeState.primaryColor),
        ),
      ),
    );
  }

  //--- Default Dark Theme ---//
  _defaultDarkTheme({required ThemeState themeState}) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: themeState.isBlackMode
          ? Colors.black
          : !themeState.isDefaultScaffoldColor
              ? themeState.customScaffoldColor != null
                  ? Color(themeState.customScaffoldColor!)
                  : null
              : null,
      appBarTheme: AppBarTheme(
          backgroundColor: themeState.isBlackMode
              ? Colors.black
              : !themeState.isDefaultAppBarColor
                  ? themeState.customAppBarColor != null
                      ? Color(themeState.customAppBarColor!)
                      : null
                  : null),
      primaryColor: Color(themeState.primaryColor),
      visualDensity: themeState.visualDensity,
      colorScheme: ColorScheme.fromSeed(
          seedColor: Color(themeState.primaryColor),
          primary: Color(themeState.primaryColor),
          secondary: Color(themeState.primaryColor),
          brightness: Brightness.dark,
          contrastLevel: themeState.contrastLevel),
      tabBarTheme: const TabBarThemeData(
        unselectedLabelStyle: TextStyle(fontSize: 7),
        labelStyle: TextStyle(
            fontSize: 8,
            fontFamily: AppFonts.poppins,
            fontWeight: FontWeight.w500),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          Color(themeState.primaryColor),
        ),
      ),
    );
  }
}
