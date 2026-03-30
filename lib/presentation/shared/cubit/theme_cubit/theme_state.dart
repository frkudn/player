import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../base/db/hive_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME STATE
//
// Single source of truth for every visual preference in the app.
// Every field is persisted to Hive immediately when changed so preferences
// survive cold restarts without any async init work.
//
// Field groups:
//   • Dark / black mode
//   • Theme customization (colors, Material 3, contrast)
//   • Scaffold / AppBar colors
//   • Bottom nav bar — legacy position / size / rotation (kept for Hive compat)
//   • Bottom nav bar — new preset style system (navBarStyleIndex)
//   • Audio player — dynamic light + layout style
//   • Display — status bar, mini player style
// ─────────────────────────────────────────────────────────────────────────────

class ThemeState extends Equatable {
  // ── Dark / light / black mode ──────────────────────────────────────────────
  final bool isDarkMode;
  final bool isBlackMode;

  // ── Theme customization ────────────────────────────────────────────────────
  final bool defaultTheme;
  final bool useMaterial3;
  final double contrastLevel;
  final VisualDensity visualDensity;
  final int primaryColorListIndex;
  final int primaryColor;

  // ── Scaffold / AppBar colors ───────────────────────────────────────────────
  final bool isDefaultScaffoldColor;
  final bool isDefaultAppBarColor;
  final int? customScaffoldColor;
  final int? customAppBarColor;

  // ── Bottom nav bar — legacy position / size / rotation ────────────────────
  // Kept so existing Hive data is never lost.
  // Visual rendering now controlled by navBarStyleIndex.
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

  // ── Bottom nav bar — new preset style system ───────────────────────────────
  // 0 = Floating Pill   1 = Full Bar      2 = Side Rail
  // 3 = Minimal Dot     4 = Labeled Island  5 = Segmented
  final int navBarStyleIndex;

  // 0 = Compact   1 = Regular (default)   2 = Large
  final int navBarSizeIndex;

  // Background opacity for glass-style nav bars (0.4–1.0)
  final double navBarOpacity;

  // ── Audio player ───────────────────────────────────────────────────────────
  // true  → animated flowing background (blurred album art drifts + breathes)
  // false → static blurred background (original behavior)
  final bool playerDynamicLightEnabled;

  // 0 = Classic     1 = Minimal     2 = Immersive
  final int playerStyleIndex;

  // ── Display preferences ────────────────────────────────────────────────────
  // Hides the Android status bar for a true full-screen experience.
  // Uses SystemUiMode.immersiveSticky when true.
  final bool hideStatusBar;

  // Controls which mini player layout is rendered above the tab bar.
  // 0 = Classic (current glassmorphic card)
  // 1 = Compact (slim bar — just thumbnail + title + play)
  // 2 = Artwork  (large artwork card with controls below)
  final int miniPlayerStyleIndex;

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
    required this.playerDynamicLightEnabled,
    required this.playerStyleIndex,
    required this.hideStatusBar,
    required this.miniPlayerStyleIndex,
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
        navBarStyleIndex: themeBox.get(MyHiveKeys.navBarStyleIndex) ?? 0,
        navBarSizeIndex: themeBox.get(MyHiveKeys.navBarSizeIndex) ?? 1,
        navBarOpacity: themeBox.get(MyHiveKeys.navBarOpacity) ?? 0.9,
        playerDynamicLightEnabled:
            themeBox.get(MyHiveKeys.playerDynamicLightEnabled) ?? true,
        playerStyleIndex: themeBox.get(MyHiveKeys.playerStyleIndex) ?? 0,
        hideStatusBar: themeBox.get(MyHiveKeys.hideStatusBar) ?? false,
        miniPlayerStyleIndex:
            themeBox.get(MyHiveKeys.miniPlayerStyleIndex) ?? 2,
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
    int? navBarStyleIndex,
    int? navBarSizeIndex,
    double? navBarOpacity,
    bool? playerDynamicLightEnabled,
    int? playerStyleIndex,
    bool? hideStatusBar,
    int? miniPlayerStyleIndex,
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
      navBarStyleIndex: navBarStyleIndex ?? this.navBarStyleIndex,
      navBarSizeIndex: navBarSizeIndex ?? this.navBarSizeIndex,
      navBarOpacity: navBarOpacity ?? this.navBarOpacity,
      playerDynamicLightEnabled:
          playerDynamicLightEnabled ?? this.playerDynamicLightEnabled,
      playerStyleIndex: playerStyleIndex ?? this.playerStyleIndex,
      hideStatusBar: hideStatusBar ?? this.hideStatusBar,
      miniPlayerStyleIndex: miniPlayerStyleIndex ?? this.miniPlayerStyleIndex,
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
        playerDynamicLightEnabled,
        playerStyleIndex,
        hideStatusBar,
        miniPlayerStyleIndex,
      ];
}
