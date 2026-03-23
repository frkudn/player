import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_player/base/db/hive_service.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME CUBIT
//
// Every method follows the same pattern:
//   1. Compute the new value
//   2. emit() the updated ThemeState (Equatable ensures no spurious rebuilds)
//   3. Persist to Hive immediately — no async dance needed, Hive put() is sync
//
// Hive keys used here are defined in MyHiveKeys (hive_service.dart).
// Make sure these keys are added to MyHiveKeys before running:
//   static const String hideStatusBar        = 'hide_status_bar';
//   static const String miniPlayerStyleIndex = 'mini_player_style_idx';
// ─────────────────────────────────────────────────────────────────────────────

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState.initial());

  // ── Theme mode ─────────────────────────────────────────────────────────────

  void toggleThemeMode() {
    final bool next = !state.isDarkMode;
    emit(state.copyWith(isDarkMode: next, isBlackMode: false));
    MyHiveBoxes.theme.put(MyHiveKeys.isDarkMode, next);
    MyHiveBoxes.theme.put(MyHiveKeys.isBlackMode, false);
  }

  // ── Primary color ──────────────────────────────────────────────────────────

  changeprimaryColor(int color) {
    emit(state.copyWith(primaryColor: color));
    MyHiveBoxes.theme.put(MyHiveKeys.primaryColor, color);
  }

  changeprimaryColorListIndex(int index) {
    emit(state.copyWith(primaryColorListIndex: index));
    MyHiveBoxes.theme.put(MyHiveKeys.primaryColorListIndex, index);
  }

  // ── Default / custom theme ─────────────────────────────────────────────────

  toggleDefaultTheme() {
    final bool next = !state.defaultTheme;
    emit(state.copyWith(defaultTheme: next));
    MyHiveBoxes.theme.put(MyHiveKeys.defaultTheme, next);
  }

  disableDefaultTheme() {
    emit(state.copyWith(defaultTheme: false));
    MyHiveBoxes.theme.put(MyHiveKeys.defaultTheme, false);
  }

  // ── Black mode ─────────────────────────────────────────────────────────────

  toggleBlackMode() {
    final bool next = !state.isBlackMode;
    emit(state.copyWith(isBlackMode: next));
    MyHiveBoxes.theme.put(MyHiveKeys.isBlackMode, next);
  }

  disableBlackMode() {
    emit(state.copyWith(isBlackMode: false));
    MyHiveBoxes.theme.put(MyHiveKeys.isBlackMode, false);
  }

  // ── Material 3 ─────────────────────────────────────────────────────────────

  toggleMaterial3() {
    final bool next = !state.useMaterial3;
    emit(state.copyWith(useMaterial3: next));
    MyHiveBoxes.theme.put(MyHiveKeys.useMaterial3, next);
  }

  // ── Contrast & density ─────────────────────────────────────────────────────

  changeContrastLevel(double contrast) {
    emit(state.copyWith(contrastLevel: contrast));
    MyHiveBoxes.theme.put(MyHiveKeys.contrastLevel, contrast);
  }

  changeVisualDensity(VisualDensity visualDensity) {
    // Visual density is a runtime-only preference — not persisted to Hive
    emit(state.copyWith(visualDensity: visualDensity));
  }

  // ── Scaffold / AppBar colors ───────────────────────────────────────────────

  changeScaffoldBgColor(int colorCode) async {
    emit(state.copyWith(
        customScaffoldColor: colorCode, isDefaultScaffoldColor: false));
    await MyHiveBoxes.theme.put(MyHiveKeys.customScaffoldColor, colorCode);
    await MyHiveBoxes.theme.put(MyHiveKeys.isDefaultScaffoldColor, false);
  }

  changeAppBarColor(int colorCode) {
    emit(state.copyWith(
        customAppBarColor: colorCode, isDefaultAppBarColor: false));
    MyHiveBoxes.theme.put(MyHiveKeys.customAppBarColor, colorCode);
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultAppBarColor, false);
  }

  resetToDefaultScaffoldColor() {
    emit(state.copyWith(isDefaultScaffoldColor: true));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultScaffoldColor, true);
  }

  resetToDefaultAppBarColor() {
    emit(state.copyWith(isDefaultAppBarColor: true));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultAppBarColor, true);
  }

  resetToDefaultBottomNavBarBgColor() {
    emit(state.copyWith(isDefaultBottomNavBarBgColor: true));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarBgColor, true);
  }

  // ── Legacy nav bar position / size / rotation ──────────────────────────────
  // These methods remain for backward compatibility.
  // New UI uses navBarStyleIndex + the free-position sliders
  // which write to bottomNavBarPositionFromLeft / FromBottom.

  resetToDefaultBottomNavBarPosition() {
    emit(state.copyWith(
      isDefaultBottomNavBarPosition: true,
      bottomNavBarPositionFromBottom: 0.05,
      bottomNavBarPositionFromLeft: 0.1,
    ));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarPosition, true);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromBottom, 0.05);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromLeft, 0.1);
  }

  resetToDefaultBottomNavBarHeightAndWidth() {
    // bottomNavBarWidth is now 0.3–1.0 (fraction of screen width).
    // 0.8 (80 %) gives a comfortable centered pill on phones.
    // The old value 0.08 was from a deprecated icon-size system —
    // never write it again or the position sliders will produce a
    // tiny 8 % wide bar that looks broken.
    emit(state.copyWith(bottomNavBarHeight: 0.045, bottomNavBarWidth: 0.8));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarHeight, 0.045);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarWidth, 0.8);
  }

  resetToDefaultBottomNavBarRotation() {
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

  changeBottomNavBarPositionTop() {
    final double next = state.bottomNavBarPositionFromBottom <= 0.95
        ? state.bottomNavBarPositionFromBottom + 0.01
        : 0;
    emit(state.copyWith(
        isDefaultBottomNavBarPosition: false,
        bottomNavBarPositionFromBottom: next));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarPosition, false);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromBottom, next);
  }

  changeBottomNavBarPositionLeft() {
    final double next = state.bottomNavBarPositionFromLeft - 0.01;
    emit(state.copyWith(
        isDefaultBottomNavBarPosition: false,
        bottomNavBarPositionFromLeft: next));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarPosition, false);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromLeft, next);
  }

  changeBottomNavBarPositionRight() {
    final double next = state.bottomNavBarPositionFromLeft + 0.01;
    emit(state.copyWith(
        isDefaultBottomNavBarPosition: false,
        bottomNavBarPositionFromLeft: next));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarPosition, false);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromLeft, next);
  }

  changeBottomNavBarPositionBottom() {
    final double next = state.bottomNavBarPositionFromBottom >= 0.01
        ? state.bottomNavBarPositionFromBottom - 0.01
        : 0;
    emit(state.copyWith(
        isDefaultBottomNavBarPosition: false,
        bottomNavBarPositionFromBottom: next));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarPosition, false);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromBottom, next);
  }

  /// Directly set horizontal position (0.0–0.9) from a slider in Settings.
  void setNavBarPositionX(double value) {
    final double v = value.clamp(0.0, 0.9);
    emit(state.copyWith(
        isDefaultBottomNavBarPosition: false, bottomNavBarPositionFromLeft: v));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarPosition, false);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromLeft, v);
  }

  /// Directly set vertical position (0.0–0.9) from a slider in Settings.
  void setNavBarPositionY(double value) {
    final double v = value.clamp(0.0, 0.9);
    emit(state.copyWith(
        isDefaultBottomNavBarPosition: false,
        bottomNavBarPositionFromBottom: v));
    MyHiveBoxes.theme.put(MyHiveKeys.isDefaultBottomNavBarPosition, false);
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarPositionFromBottom, v);
  }

  increaseBottomNavBarWidth() {
    final double updated = state.bottomNavBarWidth < 2.0
        ? state.bottomNavBarWidth + 0.03
        : state.bottomNavBarWidth;
    emit(state.copyWith(bottomNavBarWidth: updated));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarWidth, updated);
  }

  decreaseBottomNavBarWidth() {
    final double updated = state.bottomNavBarWidth >= 0.1
        ? state.bottomNavBarWidth - 0.03
        : state.bottomNavBarWidth;
    emit(state.copyWith(bottomNavBarWidth: updated));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarWidth, updated);
  }

  /// Directly set nav bar width (0.3–1.0) from a slider in Settings.
  void setNavBarWidth(double value) {
    final double v = value.clamp(0.3, 1.0);
    emit(state.copyWith(bottomNavBarWidth: v));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarWidth, v);
  }

  increaseBottomNavBarHeight() {
    final double updated = state.bottomNavBarHeight <= 0.2
        ? state.bottomNavBarHeight + 0.03
        : state.bottomNavBarHeight;
    emit(state.copyWith(bottomNavBarHeight: updated));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarHeight, updated);
  }

  decreaseBottomNavBarHeight() {
    final double updated = state.bottomNavBarHeight > 0.04
        ? state.bottomNavBarHeight - 0.03
        : state.bottomNavBarHeight;
    emit(state.copyWith(bottomNavBarHeight: updated));
    MyHiveBoxes.theme.put(MyHiveKeys.bottomNavBarHeight, updated);
  }

  updateBottomNavigationBarRotationToRight() {
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

  updateBottomNavigationBarRotationToLeft() {
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

  enableHoldBottomNavBarCirclePositionButton() {
    if (!state.isHoldBottomNavBarCirclePositionButton) {
      emit(state.copyWith(isHoldBottomNavBarCirclePositionButton: true));
    }
  }

  disableHoldBottomNavBarCirclePositionButton() {
    if (state.isHoldBottomNavBarCirclePositionButton) {
      emit(state.copyWith(isHoldBottomNavBarCirclePositionButton: false));
    }
  }

  // ── Nav bar style (0–5) ────────────────────────────────────────────────────

  void setNavBarStyle(int index) {
    if (index < 0 || index > 5) return;
    emit(state.copyWith(navBarStyleIndex: index));
    MyHiveBoxes.theme.put(MyHiveKeys.navBarStyleIndex, index);
  }

  // ── Nav bar size token (0=Compact  1=Regular  2=Large) ────────────────────

  void setNavBarSize(int index) {
    if (index < 0 || index > 2) return;
    emit(state.copyWith(navBarSizeIndex: index));
    MyHiveBoxes.theme.put(MyHiveKeys.navBarSizeIndex, index);
  }

  // ── Nav bar background opacity (0.4–1.0, glass styles only) ──────────────

  void setNavBarOpacity(double value) {
    final double v = value.clamp(0.4, 1.0);
    emit(state.copyWith(navBarOpacity: v));
    MyHiveBoxes.theme.put(MyHiveKeys.navBarOpacity, v);
  }

  // ── Audio player dynamic background ───────────────────────────────────────
  // When ON: blurred album art slowly drifts + breathes for a cinematic look.
  // Default: true — looks great out of the box, user can disable in Settings.

  void togglePlayerDynamicLight() {
    final bool next = !state.playerDynamicLightEnabled;
    emit(state.copyWith(playerDynamicLightEnabled: next));
    MyHiveBoxes.theme.put(MyHiveKeys.playerDynamicLightEnabled, next);
  }

  // ── Audio player screen layout (0=Classic  1=Minimal  2=Immersive) ─────────

  void setPlayerStyle(int index) {
    if (index < 0 || index > 2) return;
    emit(state.copyWith(playerStyleIndex: index));
    MyHiveBoxes.theme.put(MyHiveKeys.playerStyleIndex, index);
  }

  // ── Status bar visibility ──────────────────────────────────────────────────
  // Hides the Android status bar for a full-screen experience.
  // SystemUiMode.immersiveSticky shows the bar on swipe then hides it again.

  void toggleHideStatusBar() {
    final bool next = !state.hideStatusBar;
    emit(state.copyWith(hideStatusBar: next));
    MyHiveBoxes.theme.put(MyHiveKeys.hideStatusBar, next);
    if (next) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  // ── Mini player style (0=Classic  1=Compact  2=Artwork) ──────────────────
  // Controls which mini player layout renders above the main tab bar.

  void setMiniPlayerStyle(int index) {
    if (index < 0 || index > 2) return;
    emit(state.copyWith(miniPlayerStyleIndex: index));
    MyHiveBoxes.theme.put(MyHiveKeys.miniPlayerStyleIndex, index);
  }

  // ── Restore all settings to factory defaults ───────────────────────────────

  restoreDefaultSetting() {
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
      navBarStyleIndex: 0,
      navBarSizeIndex: 1,
      navBarOpacity: 0.9,
      playerDynamicLightEnabled: true,
      playerStyleIndex: 0,
      hideStatusBar: false,
      miniPlayerStyleIndex: 0,
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
    MyHiveBoxes.theme.put(MyHiveKeys.navBarSizeIndex, 1);
    MyHiveBoxes.theme.put(MyHiveKeys.navBarOpacity, 0.9);
    MyHiveBoxes.theme.put(MyHiveKeys.playerDynamicLightEnabled, true);
    MyHiveBoxes.theme.put(MyHiveKeys.playerStyleIndex, 0);
    MyHiveBoxes.theme.put(MyHiveKeys.hideStatusBar, false);
    MyHiveBoxes.theme.put(MyHiveKeys.miniPlayerStyleIndex, 0);
    // Restore status bar visibility
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
