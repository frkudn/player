import 'package:color_log/color_log.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SYSTEM SERVICE
//
// Wraps SystemChrome calls so the rest of the app never touches the Flutter
// SDK orientation / UI mode APIs directly.
//
// Orientation policy:
//   • Default: portrait-up only (set at startup)
//   • Online WebView landscape: unlock to portrait + both landscape variants
//     so Android can auto-rotate when the user physically tilts the device
//   • Back to portrait: call lockPortrait() when leaving the WebView
// ─────────────────────────────────────────────────────────────────────────────

class SystemService {
  // ── Startup calls (called once from main()) ───────────────────────────────

  /// Lock to portrait-up at app start.
  static Future<void> setOrientationPortraitOnly() async {
    clog.info('Setting preferred orientations → portrait only');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    clog.checkSuccess(true, 'Orientation: portrait only');
  }

  /// Enable edge-to-edge display (no system UI overlap).
  static Future<void> setUIModeEdgeToEdge() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    clog.checkSuccess(true, 'UI mode: edge-to-edge');
  }

  // ── Runtime orientation helpers ───────────────────────────────────────────

  /// Unlock all orientations — called when the user enables landscape mode
  /// inside the WebView browser so they can tilt the device for full-screen
  /// video playback.
  static Future<void> unlockOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    clog.info('Orientation: unlocked (portrait + landscape)');
  }

  /// Re-lock to portrait — called when the user disables landscape mode or
  /// leaves the WebView browser (disposed in OnlineSectionPage.dispose()).
  static Future<void> lockPortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    clog.info('Orientation: locked back to portrait');
  }
}
