import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_player/base/di/dependency_injection.dart';
import 'package:open_player/data/services/audio_playlist_service/audio_playlist_service.dart';
import 'package:open_player/data/services/user/user_services.dart';
import 'package:open_player/presentation/features/local_audio_player/bloc/audio_player_bloc.dart';
import 'package:open_player/presentation/features/audio_section/bloc/audio_playlist_bloc/audio_playlist_bloc.dart';
import 'package:open_player/presentation/features/main/cubit/bottom_nav_bar_cubit.dart';
import 'package:open_player/presentation/features/audio_section/bloc/greeting/greeting_cubit.dart';
import 'package:open_player/presentation/features/settings/language/cubit/language_cubit/language_cubit.dart';
import 'package:open_player/presentation/shared/cubit/theme_cubit/theme_cubit.dart';
import 'package:open_player/presentation/features/settings/user_profile/cubit/user_data/user_data_cubit.dart';
import 'base/services/storage/storage_services.dart';
import 'presentation/features/audio_section/bloc/audio_bloc/audios_bloc.dart';
import 'presentation/features/local_audio_player/cubit/lyrics/lyrics_cubit.dart';
import 'presentation/features/local_audio_player/cubit/sleep_timer/sleep_timer_cubit.dart';
import 'presentation/features/local_audio_player/cubit/volume/volume_cubit.dart';
import 'data/repositories/audio/audio_repository.dart';
import 'presentation/features/online_section/cubit/online_section_cubit.dart';

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
      create: (context) => GreetingCubit(languageCubit: getIt<LanguageCubit>()),
    ),
    BlocProvider(
      create: (context) =>
          AudiosBloc(audioRepository: getIt<AudioRepository>()),
    ),
    BlocProvider(
      create: (context) => UserDataCubit(
          userRepository: getIt<UserService>(),
          storageService: StorageService()),
    ),
    BlocProvider(
      create: (context) => AudioPlayerBloc(),
    ),
    BlocProvider(
      create: (context) => VolumeCubit(
        audioPlayer: getIt<AudioPlayer>(),
      ),
    ),
    BlocProvider(
      create: (context) => AudioPlaylistBloc(AudioPlaylistService()),
    ),
    BlocProvider(
      create: (context) => LyricsCubit(),
    ),
     BlocProvider(create: (_) => SleepTimerCubit()),
      BlocProvider(create: (_) => OnlineSectionCubit()),
  ];
}
