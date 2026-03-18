import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_player/base/di/injection.dart';
import 'package:open_player/data/services/audio_playlist_service/audio_playlist_service.dart';
import 'package:open_player/data/services/user/user_services.dart';
import 'package:open_player/logic/audio_player_bloc/audio_player_bloc.dart';
import 'package:open_player/logic/audio_playlist_bloc/audio_playlist_bloc.dart';
import 'package:open_player/logic/bottom_nav_bar_cubit/bottom_nav_bar_cubit.dart';
import 'package:open_player/logic/brightness_cubit/brightness_cubit.dart';
import 'package:open_player/logic/greeting/greeting_cubit.dart';
import 'package:open_player/logic/language_cubit/language_cubit.dart';
import 'package:open_player/logic/theme_cubit/theme_cubit.dart';
import 'package:open_player/logic/user_data/user_data_cubit.dart';
import 'base/services/storage/storage_services.dart';
import 'logic/Control_visibility/controls_visibility_cubit.dart';
import 'logic/audio_bloc/audios_bloc.dart';
import 'logic/lyrics_cubit/lyrics_cubit.dart';
import 'logic/volume_cubit/volume_cubit.dart';
import 'data/repositories/audio/audio_repository.dart';

///?----------------   B L O C   P R O V I D E R S   -------------///
///////////////////////////////////////////////////////////////////
blocProviders() {
  return [
    BlocProvider(
      create: (context) => BottomNavBarCubit(),
    ),
    BlocProvider(
      create: (context) => ThemeCubit(),
    ),
    BlocProvider(
      create: (context) => LanguageCubit(),
    ),
    BlocProvider(
      create: (context) =>
          GreetingCubit(languageCubit: locator<LanguageCubit>()),
    ),
    BlocProvider(
      create: (context) =>
          AudiosBloc(audioRepository: locator<AudioRepository>()),
    ),
    BlocProvider(
      create: (context) => UserDataCubit(
          userRepository: locator<UserService>(),
          storageService: StorageService()),
    ),
    BlocProvider(
      create: (context) => AudioPlayerBloc(),
    ),
    BlocProvider(
      create: (context) => VolumeCubit(
        audioPlayer: locator<AudioPlayer>(),
      ),
    ),
    BlocProvider(
      create: (context) => BrightnessCubit(),
    ),
    BlocProvider(
      create: (context) => ControlsVisibilityCubit(),
    ),
    BlocProvider(
      create: (context) => AudioPlaylistBloc(AudioPlaylistService()),
    ),
    BlocProvider(
      create: (context) => LyricsCubit(),
    ),
  ];
}
