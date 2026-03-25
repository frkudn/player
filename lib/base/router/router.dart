import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_player/data/models/audio_playlist_model.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/albums/view/album_preview_page.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/artists/view/artist_preview_page.dart';
import 'package:open_player/presentation/features/audio_section/views/sub/playlists/view/audio_playlist_preview_page.dart';
import 'package:open_player/presentation/features/online_section/view/online_section_page.dart';
import 'package:open_player/presentation/features/local_audio_player/view/audio_player.dart';
import 'package:open_player/presentation/features/settings/about/view/about_page.dart';
import 'package:open_player/presentation/features/settings/change_accent_color/view/change_accent_color_page.dart';
import 'package:open_player/presentation/features/settings/equalizer/view/equalizer_page.dart';
import 'package:open_player/presentation/features/settings/language/view/language_page.dart';
import 'package:open_player/presentation/features/settings/privacy_policy/view/privacy_policy_page.dart';
import 'package:open_player/presentation/features/settings/user_profile/view/user_profile_page.dart';
import 'package:open_player/presentation/features/splash/view/splash_page.dart';
import '../../presentation/features/main/view/main_page.dart';
import '../../presentation/features/audio_section/views/sub/audio_search/view/search_audio_page.dart';
import '../../presentation/features/settings/setting/view/setting_page.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: AppRoutes.splashRoute,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.mainRoute,
      builder: (context, state) => MainPage(),
    ),
    GoRoute(
      path: AppRoutes.settingsRoute,
      builder: (context, state) => const SettingPage(),
    ),
    GoRoute(
      path: AppRoutes.userProfileRoute,
      name: AppRoutes.userProfileRoute,
      builder: (context, state) => UserProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.changeThemeRoute,
      builder: (context, state) => ChangeAccentColorPage(),
    ),
    GoRoute(
      name: AppRoutes.languageRoute,
      path: AppRoutes.languageRoute,
      builder: (context, state) => const LanguagePage(),
    ),
    GoRoute(
      name: AppRoutes.privacyPolicyRoute,
      path: AppRoutes.privacyPolicyRoute,
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
    GoRoute(
      name: AppRoutes.aboutRoute,
      path: AppRoutes.aboutRoute,
      builder: (context, state) => const AboutPage(),
    ),
    GoRoute(
        name: AppRoutes.audioPlayerRoute,
        path: AppRoutes.audioPlayerRoute,
        builder: (context, state) {
          return const AudioPlayerPage();
        }),
    GoRoute(
        name: AppRoutes.onlineMusicRoute,
        path: AppRoutes.onlineMusicRoute,
        builder: (context, state) {
          return OnlineSectionPage();
        }),
    GoRoute(
      name: AppRoutes.searchAudiosRoute,
      path: AppRoutes.searchAudiosRoute,
      builder: (context, state) => const SearchAudioPage(),
    ),
    GoRoute(
      name: AppRoutes.equalizerRoute,
      path: AppRoutes.equalizerRoute,
      builder: (context, state) => const EqualizerPage(),
    ),
    GoRoute(
        name: AppRoutes.playlistPreviewRoute,
        path: AppRoutes.playlistPreviewRoute,
        builder: (context, state) {
          AudioPlaylistModel extra = state.extra as AudioPlaylistModel;
          return AudioPlaylistPreviewPage(playlist: extra);
        }),
    GoRoute(
        name: AppRoutes.artistPreviewRoute,
        path: AppRoutes.artistPreviewRoute,
        builder: (context, state) {
          List extra = state.extra as List;
          return ArtistPreviewPage(
            artist: extra[0],
            state: extra[1],
          );
        }),
    GoRoute(
        name: AppRoutes.albumPreviewRoute,
        path: AppRoutes.albumPreviewRoute,
        builder: (context, state) {
          List extra = state.extra as List;
          return AlbumPreviewPage(
            album: extra[0],
            state: extra[1],
          );
        }),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      body: Center(
        child: Text(' ${state.error}'),
      ),
    );
  },
);

class AppRoutes {
  static const splashRoute = "/";
  static const mainRoute = '/main';
  static const homeRoute = "/home";
  static const settingsRoute = "/settings";
  static const aboutRoute = "/about";
  static const userProfileRoute = "/profile";
  static const privacyPolicyRoute = "/privacy_policy";
  static const changeThemeRoute = "/change_theme";
  static const languageRoute = "/language";
  static const audioPlayerRoute = "/audio_player";
  static const onlineMusicRoute = "/online_music";
  static const searchAudiosRoute = "/search_audio";
  static const viewDirectoryRoute = "/view_directory";
  static const artistPreviewRoute = "/artist_preview";
  static const albumPreviewRoute = "/album_preview";
  static const equalizerRoute = "/equalizer";
  static const playlistPreviewRoute = "/playlist_preview";
}
