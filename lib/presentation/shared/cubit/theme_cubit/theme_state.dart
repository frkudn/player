import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../base/db/hive_service.dart';

class ThemeState extends Equatable {
  // ── Dark / light / black mode ──────────────────────────────────────────────
  final bool isDarkMode;
  final bool isBlackMode;

  // ── Theme customisation ───────────────────────────────────────────────────
  final bool defaultTheme;
  final bool useMaterial3;
  final double contrastLevel;
  final VisualDensity visualDensity;
  final int primaryColorListIndex;
  final int primaryColor;

  // ── Scaffold / AppBar colours ─────────────────────────────────────────────
  final bool isDefaultScaffoldColor;
  final bool isDefaultAppBarColor;
  final int? customScaffoldColor;
  final int? customAppBarColor;

  // ── Bottom nav bar — legacy position/size/rotation fields ────────────────
  // These are kept so existing Hive data isn't lost.
  // The new style system (navBarStyleIndex) replaces their visual effect.
  final bool isDefaultBottomNavBarBgColor;
  final bool isDefaultBottomNavBarPosition;
  final bool isDefaultBottomNavBarRotation;
  final bool isDefaultBottomNavBarIconRotation;
  final int? customBottomNavBarBgColor;
  final double bottomNavBarPositionFromLeft;
  final double bottomNavBarPositionFromBottom;
  final double bottomNavBarWidth;
  final double bottomNavBarHeight;
  final double bottomNavBarRotation;
  final double bottomNavBarIconRotation;
  final bool isHoldBottomNavBarCirclePositionButton;
  // /// 0 = Compact, 1 = Regular (default), 2 = Large
  final int navBarSizeIndex;
// /// Background opacity for glass-style nav bars (0.4 – 1.0, default 0.9)
  final double navBarOpacity;

  // ── NEW: Nav bar preset style ─────────────────────────────────────────────
  // Controls which of the 4 visual presets is shown:
  //   0 → Floating Pill (default)
  //   1 → Full-Width Bar
  //   2 → Side Rail
  //   3 → Minimal Dot
  final int navBarStyleIndex;

  const ThemeState({
    required this.isBlackMode,
    required this.isDarkMode,
    required this.useMaterial3,
    required this.primaryColorListIndex,
    required this.primaryColor,
    required this.defaultTheme,
    required this.contrastLevel,
    required this.visualDensity,
    required this.customScaffoldColor,
    required this.bottomNavBarRotation,
    required this.bottomNavBarIconRotation,
    required this.isDefaultBottomNavBarRotation,
    required this.isDefaultBottomNavBarIconRotation,
    required this.isDefaultScaffoldColor,
    required this.isDefaultAppBarColor,
    required this.isDefaultBottomNavBarBgColor,
    required this.isDefaultBottomNavBarPosition,
    required this.customAppBarColor,
    required this.customBottomNavBarBgColor,
    required this.bottomNavBarPositionFromBottom,
    required this.bottomNavBarPositionFromLeft,
    required this.bottomNavBarHeight,
    required this.bottomNavBarWidth,
    required this.isHoldBottomNavBarCirclePositionButton,
    required this.navBarStyleIndex,
    required this.navBarSizeIndex,
    required this.navBarOpacity,
  });

  static get themeBox => MyHiveBoxes.theme;

  factory ThemeState.initial() => ThemeState(
        defaultTheme: themeBox.get(MyHiveKeys.defaultTheme) ?? true,
        primaryColor: themeBox.get(MyHiveKeys.primaryColor) ?? 0xFFF43F5E,
        useMaterial3: themeBox.get(MyHiveKeys.useMaterial3) ?? true,
        isBlackMode: themeBox.get(MyHiveKeys.isBlackMode) ?? false,
        isDarkMode: themeBox.get(MyHiveKeys.isDarkMode) ?? false,
        primaryColorListIndex:
            themeBox.get(MyHiveKeys.primaryColorListIndex) ?? 0,
        contrastLevel: themeBox.get(MyHiveKeys.contrastLevel) ?? 0.5,
        visualDensity: VisualDensity.comfortable,
        isDefaultScaffoldColor:
            themeBox.get(MyHiveKeys.isDefaultScaffoldColor) ?? true,
        isDefaultAppBarColor:
            themeBox.get(MyHiveKeys.isDefaultAppBarColor) ?? true,
        isDefaultBottomNavBarBgColor:
            themeBox.get(MyHiveKeys.isDefaultBottomNavBarBgColor) ?? true,
        customScaffoldColor: themeBox.get(MyHiveKeys.customScaffoldColor),
        customAppBarColor: themeBox.get(MyHiveKeys.customAppBarColor),
        customBottomNavBarBgColor:
            themeBox.get(MyHiveKeys.customBottomNavBarBgColor),
        bottomNavBarPositionFromBottom:
            themeBox.get(MyHiveKeys.bottomNavBarPositionFromBottom) ?? 0.05,
        bottomNavBarPositionFromLeft:
            themeBox.get(MyHiveKeys.bottomNavBarPositionFromLeft) ?? 0.1,
        isDefaultBottomNavBarPosition:
            themeBox.get(MyHiveKeys.isDefaultBottomNavBarPosition) ?? true,
        bottomNavBarHeight: themeBox.get(MyHiveKeys.bottomNavBarHeight) ?? 0.05,
        bottomNavBarWidth: themeBox.get(MyHiveKeys.bottomNavBarWidth) ?? 0.8,
        isHoldBottomNavBarCirclePositionButton:
            themeBox.get(MyHiveKeys.isHoldBottomNavBarCirclePositionButton) ??
                false,
        bottomNavBarRotation:
            themeBox.get(MyHiveKeys.bottomNavBarRotation) ?? 0,
        bottomNavBarIconRotation:
            themeBox.get(MyHiveKeys.bottomNavBarIconRotation) ?? 0,
        isDefaultBottomNavBarRotation:
            themeBox.get(MyHiveKeys.isDefaultBottomNavBarRotation) ?? true,
        isDefaultBottomNavBarIconRotation:
            themeBox.get(MyHiveKeys.isDefaultBottomNavBarIconRotation) ?? true,
        // ── NEW: read saved style, default to 0 (Floating Pill)
        navBarStyleIndex: themeBox.get(MyHiveKeys.navBarStyleIndex) ?? 0,
        navBarSizeIndex: themeBox.get(MyHiveKeys.navBarSizeIndex) ?? 1,
        navBarOpacity: themeBox.get(MyHiveKeys.navBarOpacity) ?? 0.9,
      );

  ThemeState copyWith({
    bool? isDarkMode,
    bool? isBlackMode,
    int? primaryColorListIndex,
    bool? defaultTheme,
    bool? useMaterial3,
    double? contrastLevel,
    VisualDensity? visualDensity,
    int? customScaffoldColor,
    int? customAppBarColor,
    int? customBottomNavBarBgColor,
    bool? isDefaultScaffoldColor,
    bool? isDefaultAppBarColor,
    bool? isDefaultBottomNavBarBgColor,
    bool? isDefaultBottomNavBarPosition,
    bool? isDefaultBottomNavBarRotation,
    bool? isDefaultBottomNavBarIconRotation,
    double? bottomNavBarPositionFromLeft,
    double? bottomNavBarPositionFromBottom,
    double? bottomNavBarHeight,
    double? bottomNavBarWidth,
    bool? isHoldBottomNavBarCirclePositionButton,
    int? primaryColor,
    double? bottomNavBarRotation,
    double? bottomNavBarIconRotation,
    int? navBarStyleIndex, // ← NEW
    int? navBarSizeIndex,
    double? navBarOpacity,
  }) {
    return ThemeState(
      primaryColor: primaryColor ?? this.primaryColor,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      defaultTheme: defaultTheme ?? this.defaultTheme,
      isBlackMode: isBlackMode ?? this.isBlackMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      primaryColorListIndex:
          primaryColorListIndex ?? this.primaryColorListIndex,
      contrastLevel: contrastLevel ?? this.contrastLevel,
      visualDensity: visualDensity ?? this.visualDensity,
      customScaffoldColor: customScaffoldColor ?? this.customScaffoldColor,
      isDefaultScaffoldColor:
          isDefaultScaffoldColor ?? this.isDefaultScaffoldColor,
      isDefaultBottomNavBarRotation:
          isDefaultBottomNavBarRotation ?? this.isDefaultBottomNavBarRotation,
      isDefaultBottomNavBarIconRotation: isDefaultBottomNavBarIconRotation ??
          this.isDefaultBottomNavBarIconRotation,
      customAppBarColor: customAppBarColor ?? this.customAppBarColor,
      isDefaultAppBarColor: isDefaultAppBarColor ?? this.isDefaultAppBarColor,
      isDefaultBottomNavBarBgColor:
          isDefaultBottomNavBarBgColor ?? this.isDefaultBottomNavBarBgColor,
      customBottomNavBarBgColor:
          customBottomNavBarBgColor ?? this.customBottomNavBarBgColor,
      bottomNavBarPositionFromBottom:
          bottomNavBarPositionFromBottom ?? this.bottomNavBarPositionFromBottom,
      bottomNavBarPositionFromLeft:
          bottomNavBarPositionFromLeft ?? this.bottomNavBarPositionFromLeft,
      isDefaultBottomNavBarPosition:
          isDefaultBottomNavBarPosition ?? this.isDefaultBottomNavBarPosition,
      bottomNavBarRotation: bottomNavBarRotation ?? this.bottomNavBarRotation,
      bottomNavBarIconRotation:
          bottomNavBarIconRotation ?? this.bottomNavBarIconRotation,
      bottomNavBarHeight: bottomNavBarHeight ?? this.bottomNavBarHeight,
      bottomNavBarWidth: bottomNavBarWidth ?? this.bottomNavBarWidth,
      isHoldBottomNavBarCirclePositionButton:
          isHoldBottomNavBarCirclePositionButton ??
              this.isHoldBottomNavBarCirclePositionButton,
      navBarStyleIndex: navBarStyleIndex ?? this.navBarStyleIndex, // ← NEW
      navBarSizeIndex: navBarSizeIndex ?? this.navBarSizeIndex,
      navBarOpacity: navBarOpacity ?? this.navBarOpacity,
    );
  }

  @override
  List<Object?> get props => [
        primaryColor,
        isBlackMode,
        isDarkMode,
        useMaterial3,
        primaryColorListIndex,
        defaultTheme,
        contrastLevel,
        visualDensity,
        customScaffoldColor,
        isDefaultScaffoldColor,
        customAppBarColor,
        isDefaultAppBarColor,
        customBottomNavBarBgColor,
        isDefaultBottomNavBarBgColor,
        bottomNavBarPositionFromBottom,
        bottomNavBarPositionFromLeft,
        isDefaultBottomNavBarPosition,
        isDefaultBottomNavBarRotation,
        isDefaultBottomNavBarIconRotation,
        bottomNavBarHeight,
        bottomNavBarWidth,
        isHoldBottomNavBarCirclePositionButton,
        bottomNavBarRotation,
        bottomNavBarIconRotation,
        navBarStyleIndex,
        navBarSizeIndex,
        navBarOpacity,
      ];
}
