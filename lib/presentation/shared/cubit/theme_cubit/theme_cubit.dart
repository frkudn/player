import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState.initial());

  // ── Theme mode ─────────────────────────────────────────────────────────────

  /// Toggles between dark and light mode. Also turns off black mode.
  void toggleThemeMode() {
    final bool themeMode = !state.isDarkMode;
    emit(state.copyWith(isDarkMode: themeMode, isBlackMode: false));
    MyHiveBoxes.theme.put(MyHiveKeys.isDarkMode, themeMode);
    MyHiveBoxes.theme.put(MyHiveKeys.isBlackMode, false);
  }

  // ── Primary colour ─────────────────────────────────────────────────────────

  void changeprimaryColor(int color) {
    emit(state.copyWith(primaryColor: color));
    MyHiveBoxes.theme.put(MyHiveKeys.primaryColor, color);
  }

  void changeprimaryColorListIndex(int index) {
    emit(state.copyWith(primaryColorListIndex: index));
    MyHiveBoxes.theme.put(MyHiveKeys.primaryColorListIndex, index);
  }

  // ── Default / custom theme ─────────────────────────────────────────────────

  void toggleDefaultTheme() {
    final bool isDefault = !state.defaultTheme;
    emit(state.copyWith(defaultTheme: isDefault));
    MyHiveBoxes.theme.put(MyHiveKeys.defaultTheme, isDefault);
  }

  void disableDefaultTheme() {
    emit(state.copyWith(defaultTheme: false));
    MyHiveBoxes.theme.put(MyHiveKeys.defaultTheme, false);
  }

  // ── Black mode ─────────────────────────────────────────────────────────────

  void toggleBlackMode() {
    final bool isBlackMode = !state.isBlackMode;
    emit(state.copyWith(isBlackMode: isBlackMode));
    MyHiveBoxes.theme.put(MyHiveKeys.isBlackMode, isBlackMode);
  }

  void disableBlackMode() {
    emit(state.copyWith(isBlackMode: false));
    MyHiveBoxes.theme.put(MyHiveKeys.isBlackMode, false);
  }

  // ── Material 3 ─────────────────────────────────────────────────────────────

  void toggleMaterial3() {
    final bool isMaterial3 = !state.useMaterial3;
    emit(state.copyWith(useMaterial3: isMaterial3));
    MyHiveBoxes.theme.put(MyHiveKeys.useMaterial3, isMaterial3);
  }

  // ── Contrast & density ─────────────────────────────────────────────────────

  void changeContrastLevel(double contrast) {
    emit(state.copyWith(contrastLevel: contrast));
    MyHiveBoxes.theme.put(MyHiveKeys.contrastLevel, contrast);
  }

  void changeVisualDensity(VisualDensity visualDensity) {
    emit(state.copyWith(visualDensity: visualDensity));
    // VisualDensity is not persisted to Hive (runtime-only preference)
  }

  // ── Scaffold / AppBar colours ──────────────────────────────────────────────

  Future<void> changeScaffoldBgColor(int colorCode) async {
    emit(state.copyWith(
        customScaffoldColor: colorCode, isDefaultScaffoldColor: false));
    await MyHiveBoxes.theme.put(MyHiveKeys.customScaffoldColor, colorCode);
    await MyHiveBoxes.theme.put(MyHiveKeys.isDefaultScaffoldColor, false);
  }

  void changeAppBarColor(int colorCode) {
    emit(state.copyWith(
        customAppBarColor: colorCode, isDefaultAppBarColor: false));
    MyHiveBoxes.theme.put(MyHiveKeys.customAppBarColor, colorCode);
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultAppBarColor, false);
  }

  void resetToDefaultScaffoldColor() {
    emit(state.copyWith(isDefaultScaffoldColor: true));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultScaffoldColor, true);
  }

  void resetToDefaultAppBarColor() {
    emit(state.copyWith(isDefaultAppBarColor: true));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultAppBarColor, true);
  }

  void resetToDefaultBottomNavBarBgColor() {
    emit(state.copyWith(isDefaultBottomNavBarBgColor: true));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarBgColor, true);
  }

  // ── Legacy nav bar position / size / rotation ──────────────────────────────
  // These methods still work for any code that calls them, but the new
  // navBarStyleIndex approach is the recommended path going forward.

  void resetToDefaultBottomNavBarPosition() {
    emit(state.copyWith(
      isDefaultBottomNavBarPosition: true,
      bottomNavBarPositionFromBottom: 0.05,
      bottomNavBarPositionFromLeft: 0.1,
    ));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarPosition, true);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromBottom, 0.05);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromLeft, 0.1);
  }

  void resetToDefaultBottomNavBarHeightAndWidth() {
    emit(state.copyWith(bottomNavBarHeight: 0.045, bottomNavBarWidth: 0.08));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarHeight, 0.045);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarWidth, 0.08);
  }

  void resetToDefaultBottomNavBarRotation() {
    emit(state.copyWith(
      bottomNavBarRotation: 0,
      bottomNavBarIconRotation: 0,
      isDefaultBottomNavBarIconRotation: true,
      isDefaultBottomNavBarRotation: true,
    ));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarRotation, null);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarIconRotation, null);
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarRotation, true);
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarIconRotation, true);
  }

  void changeBottomNavBarPositionTop() {
    final double next = state.bottomNavBarPositionFromBottom <= 0.95
        ? state.bottomNavBarPositionFromBottom + 0.01
        : 0;
    emit(state.copyWith(
        isDefaultBottomNavBarPosition: false,
        bottomNavBarPositionFromBottom: next));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarPosition, false);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromBottom, next);
  }

  void changeBottomNavBarPositionLeft() {
    final double next = state.bottomNavBarPositionFromLeft - 0.01;
    emit(state.copyWith(
        isDefaultBottomNavBarPosition: false,
        bottomNavBarPositionFromLeft: next));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarPosition, false);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromLeft, next);
  }

  void changeBottomNavBarPositionRight() {
    final double next = state.bottomNavBarPositionFromLeft + 0.01;
    emit(state.copyWith(
        isDefaultBottomNavBarPosition: false,
        bottomNavBarPositionFromLeft: next));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarPosition, false);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromLeft, next);
  }

  void changeBottomNavBarPositionBottom() {
    final double next = state.bottomNavBarPositionFromBottom >= 0.01
        ? state.bottomNavBarPositionFromBottom - 0.01
        : 0;
    emit(state.copyWith(
        isDefaultBottomNavBarPosition: false,
        bottomNavBarPositionFromBottom: next));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarPosition, false);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromBottom, next);
  }

  void increaseBottomNavBarWidth() {
    final double updated = state.bottomNavBarWidth < 2.0
        ? state.bottomNavBarWidth + 0.03
        : state.bottomNavBarWidth;
    emit(state.copyWith(bottomNavBarWidth: updated));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarWidth, updated);
  }

  void decreaseBottomNavBarWidth() {
    final double updated = state.bottomNavBarWidth >= 0.1
        ? state.bottomNavBarWidth - 0.03
        : state.bottomNavBarWidth;
    emit(state.copyWith(bottomNavBarWidth: updated));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarWidth, updated);
  }

  void increaseBottomNavBarHeight() {
    final double updated = state.bottomNavBarHeight <= 0.2
        ? state.bottomNavBarHeight + 0.03
        : state.bottomNavBarHeight;
    emit(state.copyWith(bottomNavBarHeight: updated));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarHeight, updated);
  }

  void decreaseBottomNavBarHeight() {
    final double updated = state.bottomNavBarHeight > 0.04
        ? state.bottomNavBarHeight - 0.03
        : state.bottomNavBarHeight;
    emit(state.copyWith(bottomNavBarHeight: updated));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarHeight, updated);
  }

  void updateBottomNavigationBarRotationToRight() {
    final double nav = state.bottomNavBarRotation + 0.01;
    final double icon = state.bottomNavBarIconRotation - 0.01;
    emit(state.copyWith(
        bottomNavBarRotation: nav,
        bottomNavBarIconRotation: icon,
        isDefaultBottomNavBarRotation: false,
        isDefaultBottomNavBarIconRotation: false));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarRotation, nav);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarIconRotation, icon);
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarRotation, false);
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarIconRotation, false);
  }

  void updateBottomNavigationBarRotationToLeft() {
    final double nav = state.bottomNavBarRotation - 0.01;
    final double icon = state.bottomNavBarIconRotation + 0.01;
    emit(state.copyWith(
        bottomNavBarRotation: nav,
        bottomNavBarIconRotation: icon,
        isDefaultBottomNavBarRotation: false,
        isDefaultBottomNavBarIconRotation: false));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarRotation, nav);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarIconRotation, icon);
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarRotation, false);
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarIconRotation, false);
  }

  void enableHoldBottomNavBarCirclePositionButton() {
    if (!state.isHoldBottomNavBarCirclePositionButton) {
      emit(state.copyWith(isHoldBottomNavBarCirclePositionButton: true));
    }
  }

  void disableHoldBottomNavBarCirclePositionButton() {
    if (state.isHoldBottomNavBarCirclePositionButton) {
      emit(state.copyWith(isHoldBottomNavBarCirclePositionButton: false));
    }
  }

  // ── NEW: Nav bar preset style ──────────────────────────────────────────────

  /// Switches the bottom nav bar to one of the 4 visual presets.
  ///
  ///   0 → Floating Pill  (default, glassmorphic centred pill)
  ///   1 → Full-Width Bar (standard bottom bar with labels)
  ///   2 → Side Rail      (vertical left rail, great for tablets)
  ///   3 → Minimal Dot    (bare icons + animated dot underline)
  ///   4 → Labeled Island  (active tab expands to show label)
  ///   5 → Segmented       (sliding fill indicator)
  ///
  /// The change is instant — [CustomBottomNavBarWidget] listens via
  /// BlocBuilder<ThemeCubit> and rebuilds automatically.
  void setNavBarStyle(int index) {
    // Guard: ignore out-of-range values
    if (index < 0 || index > 5) return; // 6 styles: 0–5
    emit(state.copyWith(navBarStyleIndex: index));
    MyHiveBoxes.theme.put(MyHiveKeys.navBarStyleIndex, index);
  }

  // ── Restore all settings to factory defaults ───────────────────────────────

  void restoreDefaultSetting() {
    emit(state.copyWith(
      isDefaultAppBarColor: true,
      isDefaultScaffoldColor: true,
      contrastLevel: 0.9,
      defaultTheme: true,
      useMaterial3: true,
      bottomNavBarPositionFromBottom: 0.05,
      bottomNavBarPositionFromLeft: 0.1,
      bottomNavBarHeight: 0.045,
      bottomNavBarWidth: 0.8,
      bottomNavBarIconRotation: 0,
      bottomNavBarRotation: 0,
      navBarStyleIndex: 0, // ← reset to Floating Pill
    ));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultAppBarColor, true);
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarBgColor, true);
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultScaffoldColor, true);
    MyHiveBoxes.theme.put(MyHiveKeys.contrastLevel, 0.9);
    MyHiveBoxes.theme.put(MyHiveKeys.defaultTheme, true);
    MyHiveBoxes.theme.put(MyHiveKeys.useMaterial3, true);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromBottom, 0.05);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromLeft, 0.1);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarHeight, 0.045);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarWidth, 0.8);
    MyHiveBoxes.theme.put(MyHiveKeys.navBarStyleIndex, 0);
  }
}
