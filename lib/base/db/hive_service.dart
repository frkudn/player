import 'dart:io';
import 'package:color_log/color_log.dart';
import 'package:hive/hive.dart';
import 'package:open_player/data/models/picture_model.dart';
import 'package:open_player/data/models/video_model.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../../data/models/audio_model.dart';
import '../../data/models/audio_playlist_model.dart';

class MyHiveDatabase {
  static Future<void> initializeHive() async {
    try {
      clog.info('Initializing Hive');
      //! Ensure Hive is initialized before using it
      final Directory appDocumentDirectory =
          await path_provider.getApplicationDocumentsDirectory();
      Hive.init(appDocumentDirectory.path);

      Hive.registerAdapter(AudioModelAdapter());
      final isAudioModelRegistered =
          Hive.isAdapterRegistered(AudioModelAdapter().typeId);
      clog.checkSuccess(
          isAudioModelRegistered, "'AudioModelAdapter is registered ");
      Hive.registerAdapter(PictureModelAdapter());
      final isPictureModelRegistered =
          Hive.isAdapterRegistered(PictureModelAdapter().typeId);
      clog.checkSuccess(
          isPictureModelRegistered, "'PictureModelAdapter is registered ");
      Hive.registerAdapter(AudioPlaylistModelAdapter());
      final isAudioPlaylistModelRegistered =
          Hive.isAdapterRegistered(AudioPlaylistModelAdapter().typeId);
      clog.checkSuccess(isAudioPlaylistModelRegistered,
          "AudioPlaylistModelAdapter is registered ");
      Hive.registerAdapter(VideoModelAdapter());
      final isVideoModelRegistered =
          Hive.isAdapterRegistered(VideoModelAdapter().typeId);
      clog.checkSuccess(
          isVideoModelRegistered, "VideoModelAdapter is registered ");

      await Future.wait([
        //! Open the library box
        Hive.openBox('theme'),
        //! Open the language box
        Hive.openBox('language'),

        //! Open the language box
        Hive.openBox('user'),

        //! Video Player Playback
        Hive.openBox("videoPlaybacks"),

        //! Favorite Audio
        Hive.openBox("favorites_audios"),

        //! Favorite Video
        Hive.openBox("favorites_videos"),

        //! Recently Played Videos
        Hive.openBox("recently_played_videos"),

        //! Audio Playlist
        Hive.openBox<AudioPlaylistModel>("audio_playlist"),

        // Add to the Future.wait list:
        Hive.openBox('lyrics_prefs'),

// adjust index
      ]).then(
        (value) {
          MyHiveBoxes.theme = value[0];
          MyHiveBoxes.language = value[1];
          MyHiveBoxes.user = value[2];
          MyHiveBoxes.videoPlayback = value[3];
          MyHiveBoxes.favoriteAudios = value[4];
          MyHiveBoxes.favoriteVideos = value[5];
          MyHiveBoxes.recentlyPlayedVideos = value[6];
          MyHiveBoxes.audioPlaylist = value[7];
          MyHiveBoxes.lyricsPrefs = value[8];
        },
      );

      clog.info('Hive initialized');
    } catch (e) {
      clog.error(
        'Hive initialization error: $e',
      );
    }
  }
}

///!----------------    MyHive Boxes
class MyHiveBoxes {
  static late Box theme;
  static late Box language;
  static late Box user;
  static late Box videoPlayback;
  static late Box favoriteAudios;
  static late Box favoriteVideos;
  static late Box recentlyPlayedVideos;
  static late Box audioPlaylist;
  static late Box lyricsPrefs;
}

///!---------------      MyHive Keys
class MyHiveKeys {
  static const String defaultLanguage = "app_locale";
  static const String primaryColor = "theme_ primary_Color";
  static const String userProfilePicture = "hive_user_profile_pic";
  static const String userUsername = "hive_username";
  static const String userIsLoggedIn = "hive_user_login_status";
  static const String bottomNavBarRotation = "bottomNavBarTransform";
  static const String bottomNavBarIconRotation = "bottomNavBarIconTransform";
  static const String isDarkMode = "dm";
  static const String isBlackMode = "bm";
  static const String defaultTheme = "dt";
  static const String useMaterial3 = "m3";
  static const String isDefaultScaffoldColor = "dsc";
  static const String isDefaultAppBarColor = "dac";
  static const String isDefaultBottomNavBarBgColor = "dbnbc";
  static const String isDefaultBottomNavBarPosition = "dbnbp";
  static const String isDefaultBottomNavBarRotation = "dbnbT";
  static const String isDefaultBottomNavBarIconRotation = "dbnbIT";
  static const String contrastLevel = "cl";
  static const String customScaffoldColor = "csc";
  static const String customAppBarColor = "cabc";
  static const String customBottomNavBarBgColor = "cbnbbc";
  static const String primaryColorListIndex = "ftli";
  static const String bottomNavBarPositionFromLeft = "bnbpfl";
  static const String bottomNavBarPositionFromBottom = "bnbpfb";
  static const String bottomNavBarWidth = "bnbw";
  static const String bottomNavBarHeight = "bnbh";
  static const String isHoldBottomNavBarCirclePositionButton = "hbnbcpb";
  static const String lastPlayedVideo = "lpv";
  static const String navBarStyleIndex = 'nav_style_idx'; 
  static const String navBarSizeIndex  = 'nav_size_idx';    
static const String navBarOpacity    = 'nav_opacity';    
  // ── Audio Player Lyrics ──────────────────────────────────────
  static const String lyricsThemeIndex = 'lyr_theme';
  static const String lyricsFontSize = 'lyr_font';
  static const String lyricsStyleIndex = 'lyr_style';
  static const String lyricsIsSynced = 'lyr_synced';

  // ── Online Music ─────────────────────────────────────────────
  // Stored in MyHiveBoxes.user — persists once across the app lifetime
  static const String onlineMusicDialogShown = 'online_music_dialog_shown';
}
