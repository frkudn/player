import 'dart:io';
import 'package:color_log/color_log.dart';
import 'package:hive/hive.dart';
import 'package:open_player/data/models/picture_model.dart';
import 'package:open_player/data/models/video_model.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../../data/models/audio_model.dart';
import '../../data/models/audio_playlist_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HIVE SERVICE
//
// Hive is used as the app's local key-value persistence layer.
// It's faster than SharedPreferences for complex data and works offline.
//
// Architecture:
//   MyHiveDatabase  — initializes Hive, registers adapters, opens all boxes
//   MyHiveBoxes     — static references to every open box (set after init)
//   MyHiveKeys      — string constants for every Hive key used across the app
//
// Why string constants for keys?
//   Typos in key strings are silent bugs — you get null instead of a crash.
//   Centralizing them here makes refactoring safe and makes the data schema
//   readable in one place.
//
// Adding a new preference:
//   1. Add a constant to MyHiveKeys
//   2. Add the field to ThemeState (or whichever state class owns it)
//   3. Read the key in ThemeState.initial()
//   4. Write the key in the relevant ThemeCubit method
// ─────────────────────────────────────────────────────────────────────────────

class MyHiveDatabase {
  /// Initializes Hive and opens every box the app needs.
  ///
  /// Called once at app startup, before any cubit reads from Hive.
  /// All box references are stored in [MyHiveBoxes] after initialization
  /// so the rest of the app never needs to call Hive.openBox() again.
  static Future<void> initializeHive() async {
    try {
      clog.info('Initializing Hive');

      // Hive stores files in the app documents directory on Android/iOS.
      final Directory appDocumentDirectory =
          await path_provider.getApplicationDocumentsDirectory();
      Hive.init(appDocumentDirectory.path);

      // ── Register type adapters ───────────────────────────────────────────
      // Adapters let Hive serialize/deserialize custom model classes.
      // Each adapter has a unique typeId — never reuse an ID.

      Hive.registerAdapter(AudioModelAdapter());
      clog.checkSuccess(Hive.isAdapterRegistered(AudioModelAdapter().typeId),
          'AudioModelAdapter registered');

      Hive.registerAdapter(PictureModelAdapter());
      clog.checkSuccess(Hive.isAdapterRegistered(PictureModelAdapter().typeId),
          'PictureModelAdapter registered');

      Hive.registerAdapter(AudioPlaylistModelAdapter());
      clog.checkSuccess(
          Hive.isAdapterRegistered(AudioPlaylistModelAdapter().typeId),
          'AudioPlaylistModelAdapter registered');

      Hive.registerAdapter(VideoModelAdapter());
      clog.checkSuccess(Hive.isAdapterRegistered(VideoModelAdapter().typeId),
          'VideoModelAdapter registered');

      // ── Open all boxes in parallel ───────────────────────────────────────
      // Future.wait opens every box concurrently — much faster than awaiting
      // each one sequentially. The order in the list must match the index
      // assignments in the .then() callback below.
      await Future.wait([
        Hive.openBox('theme'), // index 0 — app theme preferences
        Hive.openBox('language'), // index 1 — selected language
        Hive.openBox('user'), // index 2 — user profile data
        Hive.openBox('videoPlaybacks'), // index 3 — video playback positions
        Hive.openBox('favorites_audios'), // index 4 — favorited audio tracks
        Hive.openBox('favorites_videos'), // index 5 — favorited videos
        Hive.openBox(
            'recently_played_videos'), // index 6 — recently played videos
        Hive.openBox<AudioPlaylistModel>(
            'audio_playlist'), // index 7 — user playlists
        Hive.openBox('lyrics_prefs'), // index 8 — lyrics display preferences
      ]).then((boxes) {
        // Assign each opened box to its static reference.
        // These references are used everywhere else in the app via MyHiveBoxes.
        MyHiveBoxes.theme = boxes[0];
        MyHiveBoxes.language = boxes[1];
        MyHiveBoxes.user = boxes[2];
        MyHiveBoxes.videoPlayback = boxes[3];
        MyHiveBoxes.favoriteAudios = boxes[4];
        MyHiveBoxes.favoriteVideos = boxes[5];
        MyHiveBoxes.recentlyPlayedVideos = boxes[6];
        MyHiveBoxes.audioPlaylist = boxes[7] as Box<AudioPlaylistModel>;
        MyHiveBoxes.lyricsPrefs = boxes[8];
      });

      clog.info('Hive initialized successfully');
    } catch (e) {
      clog.error('Hive initialization error: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HIVE BOXES
//
// Static references to each open Hive box.
// Set during MyHiveDatabase.initializeHive() and valid for the app's lifetime.
//
// Usage:  MyHiveBoxes.theme.put(MyHiveKeys.isDarkMode, true);
//         MyHiveBoxes.theme.get(MyHiveKeys.isDarkMode) ?? false;
// ─────────────────────────────────────────────────────────────────────────────

class MyHiveBoxes {
  /// Visual theme preferences — dark mode, colors, nav bar, player settings.
  static late Box theme;

  /// App language / locale code (e.g. 'en', 'ur').
  static late Box language;

  /// User profile — username, avatar, login status.
  static late Box user;

  /// Video player — per-file playback position so videos resume where left off.
  static late Box videoPlayback;

  /// Favorited audio tracks (stores file paths / IDs).
  static late Box favoriteAudios;

  /// Favorited video files.
  static late Box favoriteVideos;

  /// Recently played videos (used to populate the recents list).
  static late Box recentlyPlayedVideos;

  /// User-created audio playlists (typed box — stores AudioPlaylistModel).
  static late Box<AudioPlaylistModel> audioPlaylist;

  /// Lyrics display preferences — theme, font size, style, synced mode.
  static late Box lyricsPrefs;
}

// ─────────────────────────────────────────────────────────────────────────────
// HIVE KEYS
//
// Every string key used to read/write from Hive boxes.
// Grouped by feature area so contributors can find what they need quickly.
//
// Key naming rules:
//   • Short but descriptive — Hive stores the string itself in the file
//   • Never reuse a key string across different boxes
//   • Never change a key once it's shipped — existing users would lose their
//     saved preference (silent data loss)
//   • Add a comment explaining units or valid values for non-obvious keys
// ─────────────────────────────────────────────────────────────────────────────

class MyHiveKeys {
  // ── Language ──────────────────────────────────────────────────────────────

  /// BCP-47 language tag, e.g. 'en', 'ur', 'ar'. Stored in MyHiveBoxes.language.
  static const String defaultLanguage = 'app_locale';

  // ── User profile ──────────────────────────────────────────────────────────

  /// Base64-encoded profile picture bytes. Stored in MyHiveBoxes.user.
  static const String userProfilePicture = 'hive_user_profile_pic';

  /// Display name chosen by the user.
  static const String userUsername = 'hive_username';

  /// Whether the user has completed onboarding / login.
  static const String userIsLoggedIn = 'hive_user_login_status';

  // ── Theme — mode ──────────────────────────────────────────────────────────

  /// bool — true = dark mode, false = light mode.
  static const String isDarkMode = 'dm';

  /// bool — true = pure black AMOLED scaffold background (dark mode only).
  static const String isBlackMode = 'bm';

  /// bool — true = use the system default Material 3 color scheme.
  ///         false = apply custom accent + scaffold colors below.
  static const String defaultTheme = 'dt';

  /// bool — whether Material 3 design is enabled.
  static const String useMaterial3 = 'm3';

  // ── Theme — colors ────────────────────────────────────────────────────────

  /// int (ARGB hex) — the app accent/primary color, e.g. 0xFFF43F5E.
  static const String primaryColor = 'theme_ primary_Color';

  /// int — index into AppAccentColors.colorHexCodesList.
  static const String primaryColorListIndex = 'ftli';

  /// double — ColorScheme contrastLevel, range 0.0–1.0. Default 0.5.
  static const String contrastLevel = 'cl';

  // ── Theme — scaffold / AppBar colors ──────────────────────────────────────

  /// bool — when true the scaffold uses the theme default background color.
  static const String isDefaultScaffoldColor = 'dsc';

  /// int (ARGB hex) — custom scaffold background color.
  static const String customScaffoldColor = 'csc';

  /// bool — when true the AppBar uses the theme default background color.
  static const String isDefaultAppBarColor = 'dac';

  /// int (ARGB hex) — custom AppBar background color.
  static const String customAppBarColor = 'cabc';

  // ── Nav bar — background color ────────────────────────────────────────────

  /// bool — when true the nav bar uses its style's default background.
  static const String isDefaultBottomNavBarBgColor = 'dbnbc';

  /// int (ARGB hex) — custom nav bar background color.
  static const String customBottomNavBarBgColor = 'cbnbbc';

  // ── Nav bar — legacy position / size / rotation ───────────────────────────
  // These fields were used by the original drag-to-position system.
  // They are now also written by the free-position sliders in Settings.

  /// bool — when true the nav bar is at its default position.
  static const String isDefaultBottomNavBarPosition = 'dbnbp';

  /// double (fraction of screen width, 0.0–0.9) — horizontal offset from left.
  static const String bottomNavBarPositionFromLeft = 'bnbpfl';

  /// double (fraction of screen height, 0.0–0.9) — vertical offset from bottom.
  static const String bottomNavBarPositionFromBottom = 'bnbpfb';

  /// double (fraction of screen width, 0.3–1.0) — nav bar width.
  static const String bottomNavBarWidth = 'bnbw';

  /// double (fraction of screen height) — nav bar height.
  static const String bottomNavBarHeight = 'bnbh';

  /// bool — legacy hold-position-button toggle.
  static const String isHoldBottomNavBarCirclePositionButton = 'hbnbcpb';

  /// double (radians) — nav bar container rotation.
  static const String bottomNavBarRotation = 'bottomNavBarTransform';

  /// double (radians) — nav bar icon rotation (counter to the container).
  static const String bottomNavBarIconRotation = 'bottomNavBarIconTransform';

  /// bool — when true the nav bar is at default rotation (0 radians).
  static const String isDefaultBottomNavBarRotation = 'dbnbT';

  /// bool — when true the nav bar icon is at default rotation.
  static const String isDefaultBottomNavBarIconRotation = 'dbnbIT';

  // ── Nav bar — new preset style system ─────────────────────────────────────
  // Replaces the visual rendering of the nav bar while keeping the legacy
  // position/size fields for free-placement support.

  /// int (0–5) — which nav bar preset is active:
  ///   0 = Floating Pill    1 = Full Bar       2 = Side Rail
  ///   3 = Minimal Dot      4 = Labeled Island  5 = Segmented
  static const String navBarStyleIndex = 'nav_style_idx';

  /// int (0–2) — icon/height size token: 0 = Compact, 1 = Regular, 2 = Large.
  static const String navBarSizeIndex = 'nav_size_idx';

  /// double (0.4–1.0) — background opacity for glass-style nav bars.
  static const String navBarOpacity = 'nav_opacity';

  // ── Audio player ──────────────────────────────────────────────────────────

  /// bool — when true the blurred album art drifts + breathes (flowing animation).
  ///        Default: true. User can disable in Settings → Audio Player.
  static const String playerDynamicLightEnabled = 'player_dyn_light';

  /// int (0–2) — full-screen audio player layout:
  ///   0 = Classic (thumbnail top + glassmorphic controls)
  ///   1 = Minimal (full-screen art, overlaid controls)
  ///   2 = Immersive (edge-to-edge, dark scrim + floating controls)
  static const String playerStyleIndex = 'player_style_idx';

  // ── Display preferences ───────────────────────────────────────────────────

  /// bool — when true SystemUiMode.immersiveSticky hides the Android status bar.
  ///        Default: false. Restoring defaults re-shows the status bar.
  static const String hideStatusBar = 'hide_status_bar';

  /// int (0–2) — mini player layout shown above the main tab bar:
  ///   0 = Classic (original glassmorphic card with seek bar)
  ///   1 = Compact (slim pill bar — thumbnail + title + play)
  ///   2 = Artwork (large album art card with controls on the right)
  static const String miniPlayerStyleIndex = 'mini_player_style_idx';

  // ── Lyrics display preferences ────────────────────────────────────────────
  // Stored in MyHiveBoxes.lyricsPrefs (separate box from theme).

  /// int (0–5) — which lyrics color theme is active. Matches _themes index
  /// in audio_player_lyrics_box_widget.dart.
  static const String lyricsThemeIndex = 'lyr_theme';

  /// double — lyrics font size in logical pixels. Default 16.0.
  static const String lyricsFontSize = 'lyr_font';

  /// int (0–4) — lyrics display style:
  ///   0 = Classic   1 = Bold   2 = Minimal   3 = Karaoke   4 = Elegant
  static const String lyricsStyleIndex = 'lyr_style';

  /// bool — when true timestamps in LRC lyrics are used to sync scrolling.
  static const String lyricsIsSynced = 'lyr_synced';

  // ── Miscellaneous ─────────────────────────────────────────────────────────

  /// String — path of the last played video file (used to resume on reopen).
  static const String lastPlayedVideo = 'lpv';

  /// bool — whether the online music one-time info dialog has been shown.
  ///        Stored in MyHiveBoxes.user so it's tied to the user, not the theme.
  static const String onlineMusicDialogShown = 'online_music_dialog_shown';

  /// String (JSON array) — user-added custom online instances.
  /// Each entry is an OnlineInstance serialized to JSON.
  /// Stored in MyHiveBoxes.user so it survives theme resets.
  static const String onlineCustomInstances = 'online_custom_instances';
}
